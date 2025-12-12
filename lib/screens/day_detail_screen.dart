import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';

import '../database/database_helper.dart';
import '../models/day_note.dart';
import '../models/period_record.dart';
import '../models/settings.dart';
import '../models/symptom.dart';
import '../utils/period_calculator.dart';
import '../models/medication.dart';
import '../models/medication_taken_record.dart'; // Импортируем MedicationTakenRecord
//import '../screens/home_screen.dart';

import 'package:yandex_mobileads/mobile_ads.dart';
import '../services/permissions_service.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
//import 'package:yandex_mobileads/ad_widget.dart';

// Added MedicationTime class
class MedicationTime {
  final int hour;
  final int minute;

  MedicationTime({required this.hour, required this.minute});

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class MedicationEvent {
  final String name;
  final DateTime scheduledTime;
  final int medicationId; // Для идентификации оригинального лекарства, если потребуется
  bool isTaken; // Добавляем статус приема
  DateTime? actualTakenTime; // Добавляем фактическое время приема

  MedicationEvent({
    required this.name,
    required this.scheduledTime,
    required this.medicationId,
    this.isTaken = false,
    this.actualTakenTime,
  });

  // Для сортировки
  int compareTo(MedicationEvent other) {
    return scheduledTime.compareTo(other.scheduledTime);
  }
}

class DayDetailScreen extends StatefulWidget {
  final DateTime selectedDate;
  final List<PeriodRecord> periodRecords;
  final Settings settings;
  final bool shouldReturnResult; // Нужно ли возвращать результат

  const DayDetailScreen({
    super.key, 
    required this.selectedDate,
    required this.periodRecords,
    required this.settings,
    this.shouldReturnResult = false,
  });

  @override
  _DayDetailScreenState createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  final _databaseHelper = DatabaseHelper();
  late DayNote _dayNote;
  final _symptomController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  
  
  //Реклама
  late BannerAd banner;
  var isBannerAlreadyCreated = false;


  PeriodRecord? _lastPeriod;
  PeriodRecord? _activePeriod;
  List<String> _allSymptoms = []; // Список всех доступных симптомов
  List<Medication> _allMedications = []; // Список всех лекарств

  // Состояние блоков (по умолчанию все раскрыты)
  bool _isPeriodBlockExpanded = true;
  bool _isSexBlockExpanded = true;
  bool _isHealthBlockExpanded = true;
  bool _isMedicineBlockExpanded = true;
  List<MedicationTakenRecord> _takenRecords = []; // Добавляем список записей о приеме

  bool get _canMarkStart => PeriodCalculator.canMarkPeriodStart(widget.selectedDate, _lastPeriod);
  bool get _canMarkEnd => PeriodCalculator.canMarkPeriodEnd(widget.selectedDate, _activePeriod);
  bool get _isInActivePeriod => PeriodCalculator.isDateInActivePeriod(widget.selectedDate, _activePeriod);
  bool get _isDelayDay => PeriodCalculator.isDelayDay(widget.selectedDate, widget.settings, widget.periodRecords);
  bool get _isOvulationDay => PeriodCalculator.isOvulationDay(widget.selectedDate, widget.settings, widget.periodRecords);
  bool get _isFertileDay => PeriodCalculator.isFertileDay(widget.selectedDate, widget.settings, widget.periodRecords);



//Реклама
  _createBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    return BannerAd(
      adUnitId: 'R-M-17946414-1',
      adSize: adSize,
      adRequest: const AdRequest(),
      onAdLoaded: () {},
      onAdFailedToLoad: (error) {},
      onAdClicked: () {},
      onLeftApplication: () {},
      onReturnedToApplication: () {},
      onImpression: (impressionData) {}
    );
  }




  // Найти предыдущий период, предшествующий выбранному дню
  PeriodRecord? get _previousPeriod {
    if (widget.periodRecords.isEmpty) return null;
    
    // Фильтруем периоды, которые заканчиваются до выбранной даты
    final previousPeriods = widget.periodRecords.where((period) {
      final periodEndDate = period.endDate ?? PeriodCalculator.getToday();
      return periodEndDate.isBefore(widget.selectedDate) || 
             periodEndDate.isAtSameMomentAs(widget.selectedDate);
    }).toList();
    
    if (previousPeriods.isEmpty) return null;
    
    // Сортируем по дате окончания (от новых к старым) и берем первый
    previousPeriods.sort((a, b) {
      final aEndDate = a.endDate ?? PeriodCalculator.getToday();
      final bEndDate = b.endDate ?? PeriodCalculator.getToday();
      return bEndDate.compareTo(aEndDate);
    });
    
    return previousPeriods.first;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final localeTag = Localizations.localeOf(context).toString();
    return DateFormat('dd.MM.yyyy', localeTag).format(date);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool includeBanner = false}) async {
    try {

      if (includeBanner) {
        banner = _createBanner();
        
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          isBannerAlreadyCreated = true;
        });
      } else {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Загружаем заметку дня
      DayNote? note = await _databaseHelper.getDayNote(widget.selectedDate);
      _dayNote = note ?? DayNote(
        date: widget.selectedDate,
        symptoms: [],
      );

      // Загружаем последний период и активный период
      _lastPeriod = await _databaseHelper.getLastPeriodRecord();
      _activePeriod = await _databaseHelper.getActivePeriodRecord();

      await _loadAllSymptoms(); // Загружаем все симптомы через новую функцию
      // Загружаем все лекарства
      _allMedications = await _databaseHelper.getAllMedications();
      // Загружаем записи о приеме лекарств для выбранного дня
      _takenRecords = await _databaseHelper.getMedicationTakenRecordsForDay(widget.selectedDate);

      setState(() {
        _isLoading = false;
      });
      
      // Проверяем разрешения после загрузки данных
      if (mounted) {
        await PermissionsService.checkAndRequestPermissions(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startNewPeriod() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final newPeriod = PeriodRecord(
        startDate: widget.selectedDate,
      );
      
      await _databaseHelper.insertPeriodRecord(newPeriod);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startPeriodSuccess),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadData(); // Перезагружаем данные
      
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startPeriodError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error, // Изменено здесь
        ),
      );
    }
  }

  Future<void> _endActivePeriod() async {
    if (_activePeriod == null) return;
    
    try {
      final l10n = AppLocalizations.of(context)!;
      // Проверяем, что дата окончания не раньше даты начала
      if (widget.selectedDate.isBefore(_activePeriod!.startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.endDateBeforeStart),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updatedPeriod = PeriodRecord(
        id: _activePeriod!.id,
        startDate: _activePeriod!.startDate,
        endDate: widget.selectedDate,
      );
      
      await _databaseHelper.updatePeriodRecord(updatedPeriod);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.endPeriodSuccess),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadData(); // Перезагружаем данные
      
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startPeriodError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error, // Изменено здесь
        ),
      );
    }
  }

  Future<void> _cancelActivePeriod() async {
    if (_activePeriod == null) return;
    
    try {
      final l10n = AppLocalizations.of(context)!;
      await _databaseHelper.deletePeriodRecord(_activePeriod!.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cancelPeriodSuccess),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadData(); // Перезагружаем данные
      
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startPeriodError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error, // Изменено здесь
        ),
      );
    }
  }

  Future<void> _removeLastPeriodEnd() async {
    if (_lastPeriod == null || _lastPeriod!.endDate == null) return;
    
    try {
      final l10n = AppLocalizations.of(context)!;
      final updatedPeriod = _lastPeriod!.copyWith(endDate: null, setEndDate: true);
      await _databaseHelper.updatePeriodRecord(updatedPeriod);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.removePeriodEndSuccess),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadData();
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startPeriodError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error, // Изменено здесь
        ),
      );
    }
  }

  Future<void> _deleteLastPeriod() async {
    if (_lastPeriod == null || _lastPeriod!.id == null) return;
    
    try {
      final l10n = AppLocalizations.of(context)!;
      await _databaseHelper.deletePeriodRecord(_lastPeriod!.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deletePeriodSuccess),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadData();
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startPeriodError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error, // Изменено здесь
        ),
      );
    }
  }

  Future<void> _saveDayNote() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      await _databaseHelper.insertOrUpdateDayNote(_dayNote);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.symptomsSaved),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startPeriodError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error, // Изменено здесь
        ),
      );
    }
  }
// Новые функции для работы с полями секса
  void _updateHadSex(bool? hadSex) {
    setState(() {
      _dayNote = _dayNote.copyWith(
        hadSex: hadSex,
        // Если снимаем галку "Был секс", сбрасываем связанные поля
        isSafeSex: hadSex == true ? _dayNote.isSafeSex : null,
        hadOrgasm: hadSex == true ? _dayNote.hadOrgasm : null,
      );
    });
    _saveDayNote();
  }

  void _updateIsSafeSex(bool? isSafeSex) {
    setState(() {
      _dayNote = _dayNote.copyWith(isSafeSex: isSafeSex);
    });
    _saveDayNote();
  }

  void _updateHadOrgasm(bool? hadOrgasm) {
    setState(() {
      _dayNote = _dayNote.copyWith(hadOrgasm: hadOrgasm);
    });
    _saveDayNote();
  }

  Future<void> _loadAllSymptoms() async {
    try {
      _allSymptoms = await _databaseHelper.getAllSymptoms();
    } catch (e) {
      print('Error loading all symptoms: $e');
      setState(() {
        _errorMessage = 'Error loading symptoms: ${e.toString()}';
      });
    }
  }

  void _addSymptom(String symptomText) async {
    final symptom = symptomText.trim();
    if (symptom.isNotEmpty) {
      if (!_dayNote.symptoms.contains(symptom)) {
        // Если симптома нет в текущих симптомах дня, добавляем его
        setState(() {
          _dayNote = _dayNote.copyWith(
            symptoms: [..._dayNote.symptoms, symptom],
          );
        });
        await _saveDayNote();

        // Если этого симптома нет в глобальном списке, добавляем в БД и обновляем глобальный список
        if (!_allSymptoms.any((s) => s.toLowerCase() == symptom.toLowerCase())) {
          final newSymptom = Symptom(name: symptom, isDefault: false);
          await _databaseHelper.insertSymptom(newSymptom); // Добавляем в БД
          await _loadAllSymptoms(); // Перезагружаем список всех симптомов
        }
      } else {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.symptomAlreadyAddedMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _removeSymptom(String symptom) {
    setState(() {
      _dayNote = _dayNote.copyWith(
        symptoms: _dayNote.symptoms.where((s) => s != symptom).toList(),
      );
    });
    _saveDayNote();
  }

  Future<void> _toggleMedicationTakenStatus(MedicationEvent event, bool isTaken) async {
    try {

      MedicationTakenRecord? existingRecord = await _databaseHelper.getMedicationTakenRecord(
        event.medicationId,
        widget.selectedDate,
        TimeOfDay(hour: event.scheduledTime.hour, minute: event.scheduledTime.minute),
      );

      if (isTaken) {
        // Отмечаем как принятое
        final newRecord = existingRecord?.copyWith(
              isTaken: true,
              actualTakenTime: DateTime.now(),
            ) ??
            MedicationTakenRecord(
              medicationId: event.medicationId,
              date: widget.selectedDate,
              scheduledTime: TimeOfDay(hour: event.scheduledTime.hour, minute: event.scheduledTime.minute),
              actualTakenTime: DateTime.now(),
              isTaken: true,
            );
        if (existingRecord == null) {
          await _databaseHelper.insertMedicationTakenRecord(newRecord);
        } else {
          await _databaseHelper.updateMedicationTakenRecord(newRecord);
        }
      } else {
        // Отмечаем как непринятое или удаляем запись, если она была
        if (existingRecord != null) {
          final updatedRecord = existingRecord.copyWith(
            isTaken: false,
            actualTakenTime: null, // Сбрасываем фактическое время
          );
          await _databaseHelper.updateMedicationTakenRecord(updatedRecord);
        }
      }
      await _loadData(); // Перезагружаем данные, чтобы обновить UI
    } catch (e) {
      print('Ошибка при обновлении статуса приема лекарства: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Создаем баннер только если его еще нет и мы не в процессе загрузки
    if (!isBannerAlreadyCreated && !_isLoading) {
      try {
        banner = _createBanner();
        setState(() {
          isBannerAlreadyCreated = true;
        });
      } catch (e) {
        // Игнорируем ошибки создания баннера
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MenuScreen()),
                (route) => false,
              );
          },
        ),
        title: Text(l10n.dayDetailsTitle),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.calendar_month),
          //   onPressed: _openCalendar,
          //   tooltip: 'Календарь',
          // ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: l10n.refreshTooltip,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fon1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
        children: [
          // Основной контент
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(l10n.errorWithMessage(_errorMessage!)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Заголовок с датой
                            Card(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomeScreen(
                                        calledFromDetailScreen: true,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      _formatDate(context, widget.selectedDate),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Блок "Месячные"
                            _buildPeriodBlock(l10n),
                            const SizedBox(height: 8),
//Убрал на будущее, пока не особо нужен
                            // Блок "Секс"
                            _buildSexBlock(l10n),
                            const SizedBox(height: 8),

                            // Блок "Самочувствие"
                            _buildHealthBlock(l10n),
                            const SizedBox(height: 8),

                            // Блок "Лекарства"
                            _buildMedicineBlock(l10n),
                          ],
                        ),
                      ),
          ),
          
          // Виджет рекламы
          Container(
            alignment: Alignment.bottomCenter,
            child: isBannerAlreadyCreated ? AdWidget(bannerAd: banner) : null,
          ),
        ],
      ),
      ),
    );
  }

  // Блок "Месячные"
  Widget _buildPeriodBlock(AppLocalizations l10n) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: _isPeriodBlockExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isPeriodBlockExpanded = expanded;
          });
        },
        title: const Text(
          'Месячные',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация о задержке
                if (_isDelayDay)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Задержка',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_isDelayDay) const SizedBox(height: 16),

                // Информация об овуляции
                if (_isOvulationDay)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.child_friendly, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.idealTimeForConception,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_isOvulationDay) const SizedBox(height: 16),

                // Информация о фертильных днях
                if (_isFertileDay && !_isOvulationDay)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen[50],
                      border: Border.all(color: Colors.lightGreen),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.lightGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.favorableTimeForConception,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.lightGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_isFertileDay && !_isOvulationDay) const SizedBox(height: 16),

                // Информация о предыдущих месячных
                if (_previousPeriod != null) ...[
                  const Text(
                    'Предыдущие месячные',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _previousPeriod!.endDate != null
                                    ? '${_formatDate(context, _previousPeriod!.startDate)} - ${_formatDate(context, _previousPeriod!.endDate!)}'
                                    : '${_formatDate(context, _previousPeriod!.startDate)} - (активный)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Продолжительность: ${_previousPeriod!.durationInDays} ${_previousPeriod!.durationInDays == 1 ? 'день' : 'дня'}',
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Управление периодом
                const Text(
                  'Управление циклом',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                if (_activePeriod == null && _canMarkStart) ...[
                  // Можно начать новый период
                  ElevatedButton(
                    onPressed: _startNewPeriod,
                    child: Text(l10n.startNewPeriodButton),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.startNewPeriodHint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ] else if (_activePeriod != null && _canMarkEnd) ...[
                  // Можно завершить активный период
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.activePeriodLabel(
                          _formatDate(context, _activePeriod!.startDate),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _endActivePeriod,
                        child: Text(l10n.endPeriodButton),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.endPeriodHint,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _cancelActivePeriod,
                        child: Text(
                          l10n.cancelPeriodButton,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      Text(
                        l10n.cancelPeriodHint,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ] else if (_isInActivePeriod) ...[
                  // День внутри активного периода
                  Text(
                    l10n.dayWithinActive,
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.dayWithinActiveHint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ] else if (_lastPeriod != null && _lastPeriod!.endDate != null) ...[
                  // Есть завершенный период
                  Text(
                    l10n.lastPeriodLabel(
                      _formatDate(context, _lastPeriod!.startDate),
                      _formatDate(context, _lastPeriod!.endDate!),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.lastPeriodHint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _removeLastPeriodEnd,
                    child: Text(l10n.removeEndDateButton),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _deleteLastPeriod,
                    child: Text(
                      l10n.deletePeriodButton,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  Text(
                    l10n.deletePeriodHint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
// Блок "Секс" с новой реализацией
  Widget _buildSexBlock(AppLocalizations l10n) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: _isSexBlockExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isSexBlockExpanded = expanded;
          });
        },
        title: const Text(
          'Секс',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Чекбокс "Был секс"
                Row(
                  children: [
                    Checkbox(
                      value: _dayNote.hadSex ?? false,
                      onChanged: _updateHadSex,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Был секс',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Блок выбора типа секса (только если был секс)
                if (_dayNote.hadSex == true) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Тип секса:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Кнопка "Безопасный"
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateIsSafeSex(true),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _dayNote.isSafeSex == true 
                                ? Colors.green[50] 
                                : Colors.transparent,
                            side: BorderSide(
                              color: _dayNote.isSafeSex == true 
                                  ? Colors.green 
                                  : Colors.grey,
                              width: _dayNote.isSafeSex == true ? 2 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield,
                                color: _dayNote.isSafeSex == true 
                                    ? Colors.green 
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Безопасный',
                                style: TextStyle(
                                  color: _dayNote.isSafeSex == true 
                                      ? Colors.green 
                                      : Colors.grey[700],
                                  fontWeight: _dayNote.isSafeSex == true 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Кнопка "Небезопасный"
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateIsSafeSex(false),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _dayNote.isSafeSex == false 
                                ? Colors.red[50] 
                                : Colors.transparent,
                            side: BorderSide(
                              color: _dayNote.isSafeSex == false 
                                  ? Colors.red 
                                  : Colors.grey,
                              width: _dayNote.isSafeSex == false ? 2 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning,
                                color: _dayNote.isSafeSex == false 
                                    ? Colors.red 
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Небезопасный',
                                style: TextStyle(
                                  color: _dayNote.isSafeSex == false 
                                      ? Colors.red 
                                      : Colors.grey[700],
                                  fontWeight: _dayNote.isSafeSex == false 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Блок выбора оргазма (только если был секс)
                  const SizedBox(height: 16),
                  const Text(
                    'Оргазм:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Кнопка "Был оргазм"
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateHadOrgasm(true),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _dayNote.hadOrgasm == true 
                                ? Colors.purple[50] 
                                : Colors.transparent,
                            side: BorderSide(
                              color: _dayNote.hadOrgasm == true 
                                  ? Colors.purple 
                                  : Colors.grey,
                              width: _dayNote.hadOrgasm == true ? 2 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: _dayNote.hadOrgasm == true 
                                    ? Colors.purple 
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Был оргазм',
                                style: TextStyle(
                                  color: _dayNote.hadOrgasm == true 
                                      ? Colors.purple 
                                      : Colors.grey[700],
                                  fontWeight: _dayNote.hadOrgasm == true 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Кнопка "Не было оргазма"
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateHadOrgasm(false),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _dayNote.hadOrgasm == false 
                                ? Colors.blue[50] 
                                : Colors.transparent,
                            side: BorderSide(
                              color: _dayNote.hadOrgasm == false 
                                  ? Colors.blue 
                                  : Colors.grey,
                              width: _dayNote.hadOrgasm == false ? 2 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cancel,
                                color: _dayNote.hadOrgasm == false 
                                    ? Colors.blue 
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Не было оргазма',
                                style: TextStyle(
                                  color: _dayNote.hadOrgasm == false 
                                      ? Colors.blue 
                                      : Colors.grey[700],
                                  fontWeight: _dayNote.hadOrgasm == false 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Подсказка если ничего не выбрано
                if (_dayNote.hadSex == null || _dayNote.hadSex == false) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Если ничего не выбрано, в базу данных записывается null',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Блок "Самочувствие"
  Widget _buildHealthBlock(AppLocalizations l10n) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: _isHealthBlockExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isHealthBlockExpanded = expanded;
          });
        },
        title: const Text(
          'Самочувствие',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.symptomsTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Поле ввода симптома
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return _allSymptoms.where((String option) {
                              return !_dayNote.symptoms.contains(option);
                            });
                          }
                          return _allSymptoms.where((String option) {
                            return !(_dayNote.symptoms.contains(option)) &&
                                option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) async {
                          _addSymptom(selection); // Добавляем симптом
                          _symptomController.clear(); // Очищаем наш контроллер
                        },
                        fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                          // Используем _symptomController в TextField
                          return TextField(
                            controller: _symptomController,
                            focusNode: focusNode,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.done,
                            maxLines: 1,
                            autocorrect: true,
                            enableSuggestions: true,
                            smartDashesType: SmartDashesType.enabled,
                            smartQuotesType: SmartQuotesType.enabled,
                            textCapitalization: TextCapitalization.none,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'.*')), // Разрешить любые символы
                            ],
                            decoration: InputDecoration(
                              hintText: l10n.addSymptomHint,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onSubmitted: (_) {
                              _addSymptom(_symptomController.text); // Передаем текст из нашего контроллера
                              _symptomController.clear(); // Очищаем наш контроллер
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 40),
                      color: Colors.pink,
                      onPressed: () {
                        _addSymptom(_symptomController.text);
                        _symptomController.clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Список симптомов
                if (_dayNote.symptoms.isNotEmpty) ...[
                  Text(
                    l10n.currentSymptomsTitle,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dayNote.symptoms.map((symptom) => Chip(
                      label: Text(symptom),
                      onDeleted: () => _removeSymptom(symptom),
                      deleteIcon: const Icon(Icons.clear, size: 18),
                    )).toList(),
                  ),
                ] else
                  Text(
                    l10n.noSymptoms,
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Блок "Лекарства"
  Widget _buildMedicineBlock(AppLocalizations l10n) {
    final activeMedications = _allMedications.where((med) => med.isActiveOn(widget.selectedDate)).toList();

    List<MedicationEvent> medicationEvents = [];
    for (var medication in activeMedications) {
      for (var medicationTime in medication.times) {
        // Формируем запланированное время для сравнения и отображения
        final scheduledDateTime = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          medicationTime.hour,
          medicationTime.minute,
        );

        // Ищем соответствующую запись о том, что лекарство было принято
        final takenRecord = _takenRecords.firstWhere(
          (record) =>
              record.medicationId == medication.id &&
              record.scheduledTime.hour == medicationTime.hour &&
              record.scheduledTime.minute == medicationTime.minute,
          orElse: () => MedicationTakenRecord(
            medicationId: medication.id!,
            date: widget.selectedDate,
            scheduledTime: TimeOfDay(hour: medicationTime.hour, minute: medicationTime.minute),
            isTaken: false, //по умолчанию false, если не найдено записи
          ), // Возвращаем заглушку, если запись не найдена
        );

        medicationEvents.add(MedicationEvent(
          name: medication.name,
          scheduledTime: scheduledDateTime,
          medicationId: medication.id!,
          isTaken: takenRecord.isTaken,
          actualTakenTime: takenRecord.actualTakenTime,
        ));
      }
    }

    medicationEvents.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return Card(
      margin: EdgeInsets.zero, // Убираем отступы вокруг Card
      child: ExpansionTile(
        initiallyExpanded: _isMedicineBlockExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isMedicineBlockExpanded = expanded;
          });
        },
        title: const Text(
          'Лекарства',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (medicationEvents.isEmpty)
                  const Text(
                    'Нет записей о лекарствах на этот день.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: medicationEvents.length,
                    itemBuilder: (context, index) {
                      final event = medicationEvents[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Время приема: ${DateFormat('HH:mm').format(event.scheduledTime)}',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  if (event.isTaken && event.actualTakenTime != null)
                                    Text(
                                      'Принято: ${DateFormat('HH:mm').format(event.actualTakenTime!.toLocal())}',
                                      style: const TextStyle(fontSize: 12, color: Colors.green),
                                    ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: event.isTaken,
                              onChanged: (bool? newValue) {
                                _toggleMedicationTakenStatus(event, newValue ?? false);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

}