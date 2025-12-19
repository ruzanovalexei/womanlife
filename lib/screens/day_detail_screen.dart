import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
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
import 'medications_screen.dart';
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
  final bool shouldReturnResult;

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
  bool _isLoading = true;
  String? _errorMessage;
  
  // Реклама
  late BannerAd banner;
  var isBannerAlreadyCreated = false;
  static const _backgroundImage = AssetImage('assets/images/fon1.png');

  PeriodRecord? _lastPeriod;
  PeriodRecord? _activePeriod;
  List<PeriodRecord> _allPeriodRecords = []; // Все записи о периодах для расчета плановых периодов
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
  // bool get _isDelayDay => PeriodCalculator.isDelayDay(widget.selectedDate, widget.settings, _allPeriodRecords);
  bool get _isOvulationDay => PeriodCalculator.isOvulationDay(widget.selectedDate, widget.settings, _allPeriodRecords);
  bool get _isFertileDay => PeriodCalculator.isFertileDay(widget.selectedDate, widget.settings, _allPeriodRecords);







  // Получить следующие плановые периоды (первые после последних фактических с интервалом более 14 дней)
  List<PeriodRange> get _nextPlannedPeriods {
    if (_allPeriodRecords.isEmpty) return [];
    
    // Рассчитываем все плановые периоды на основе настроек и фактических записей
    final plannedPeriods = PeriodCalculator.calculatePlannedPeriods(
      widget.settings, 
      _allPeriodRecords
    );
    
    // Находим последний фактический период
    final sortedActualPeriods = List<PeriodRecord>.from(_allPeriodRecords)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    
    if (sortedActualPeriods.isEmpty) return [];
    
    final lastActualPeriod = sortedActualPeriods.first;
    
    // Фильтруем плановые периоды, оставляя только те, которые начинаются 
    // более чем через 14 дней после последнего фактического
    final nextPlannedPeriods = plannedPeriods.where((plannedPeriod) {
      final daysDifference = plannedPeriod.startDate.difference(lastActualPeriod.startDate).inDays;
      return daysDifference > 14;
    }).toList();
    
    // Берем только первый плановый период для отображения
    return nextPlannedPeriods.take(1).toList();
  }

  String _formatDate(BuildContext context, DateTime date) {
    final localeTag = Localizations.localeOf(context).toString();
    return DateFormat('dd.MM.yyyy', localeTag).format(date);
  }

  // Обновить экран с переходом к текущей дате
  void _refreshToCurrentDate() {
    final currentDate = PeriodCalculator.getToday();
    
    // Переходим к главному экрану с текущей датой
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailScreen(
          selectedDate: currentDate,
          periodRecords: widget.periodRecords, // Передаем текущие записи периодов
          settings: widget.settings,
          shouldReturnResult: false,
        ),
      ),
      (route) => false,
    );
  }

  // Переключить на предыдущий день
  void _goToPreviousDay() {
    final previousDate = widget.selectedDate.subtract(const Duration(days: 1));
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailScreen(
          selectedDate: previousDate,
          periodRecords: widget.periodRecords,
          settings: widget.settings,
          shouldReturnResult: widget.shouldReturnResult,
        ),
      ),
    );
  }

  // Переключить на следующий день
  void _goToNextDay() {
    final nextDate = widget.selectedDate.add(const Duration(days: 1));
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailScreen(
          selectedDate: nextDate,
          periodRecords: widget.periodRecords,
          settings: widget.settings,
          shouldReturnResult: widget.shouldReturnResult,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // Оптимизированная инициализация экрана
  void _initializeScreen() {
    _createAdBanner();
    _loadData();
  }

  // Создание баннера
  BannerAd _createBanner() {
    final screenWidth = MediaQuery.of(context).size.width.round();
    final adSize = BannerAdSize.sticky(width: screenWidth);
    
    return BannerAd(
      adUnitId: 'R-M-17946414-3',
      adSize: adSize,
      adRequest: const AdRequest(),
      onAdLoaded: () {
        if (mounted) {
          setState(() {}); // Обновляем только для показа баннера
        }
      },
      onAdFailedToLoad: (error) {
        debugPrint('Ad failed to load: $error');
      },
      onAdClicked: () {},
      onLeftApplication: () {},
      onReturnedToApplication: () {},
      onImpression: (impressionData) {}
    );
  }

  // Оптимизированное создание баннера
  void _createAdBanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !isBannerAlreadyCreated) {
        try {
          banner = _createBanner();
          setState(() {
            isBannerAlreadyCreated = true;
          });
        } catch (e) {
          debugPrint('Banner creation failed: $e');
        }
      }
    });
  }

  // Оптимизированная загрузка данных - один setState
  Future<void> _loadData() async {
    try {
      // Загружаем заметку дня
      DayNote? note = await _databaseHelper.getDayNote(widget.selectedDate);
      _dayNote = note ?? DayNote(
        date: widget.selectedDate,
        symptoms: [],
      );

      // Загружаем все периоды из базы данных
      _allPeriodRecords = await _databaseHelper.getAllPeriodRecords();
      
      // Загружаем последний период и активный период
      _lastPeriod = await _databaseHelper.getLastPeriodRecord();
      _activePeriod = await _databaseHelper.getActivePeriodRecord();

      await _loadAllSymptoms();
      _allMedications = await _databaseHelper.getAllMedications();
      _takenRecords = await _databaseHelper.getMedicationTakenRecordsForDay(widget.selectedDate);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        
        // Проверяем разрешения после загрузки данных
        await PermissionsService.checkAndRequestPermissions(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        debugPrint('Error loading day detail data: $e');
      }
    }
  }

  Future<void> _startNewPeriod() async {
    try {
      // final l10n = AppLocalizations.of(context)!;
      final newPeriod = PeriodRecord(
        startDate: widget.selectedDate,
      );
      
      await _databaseHelper.insertPeriodRecord(newPeriod);
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(l10n.startPeriodSuccess),
      //     backgroundColor: Colors.green,
      //   ),
      // );
      
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
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(l10n.endPeriodSuccess),
      //     backgroundColor: Colors.green,
      //   ),
      // );
      
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
      // final l10n = AppLocalizations.of(context)!;
      await _databaseHelper.deletePeriodRecord(_activePeriod!.id!);
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(l10n.cancelPeriodSuccess),
      //     backgroundColor: Colors.green,
      //   ),
      // );
      
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
      // final l10n = AppLocalizations.of(context)!;
      final updatedPeriod = _lastPeriod!.copyWith(endDate: null, setEndDate: true);
      await _databaseHelper.updatePeriodRecord(updatedPeriod);
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(l10n.removePeriodEndSuccess),
      //     backgroundColor: Colors.green,
      //   ),
      // );
      
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
      // final l10n = AppLocalizations.of(context)!;
      await _databaseHelper.deletePeriodRecord(_lastPeriod!.id!);
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(l10n.deletePeriodSuccess),
      //     backgroundColor: Colors.green,
      //   ),
      // );
      
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
      // final l10n = AppLocalizations.of(context)!;
      await _databaseHelper.insertOrUpdateDayNote(_dayNote);
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(l10n.symptomsSaved),
      //     backgroundColor: Colors.green,
      //     duration: const Duration(seconds: 1),
      //   ),
      // );
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
      // Сортируем симптомы в алфавитном порядке
      _allSymptoms.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } catch (e) {
      // print('Error loading all symptoms: $e');
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

  Future<void> _showQuickAddSymptomDialog() async {
    // final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return const AddSymptomDialog();
      },
    );

    // Если пользователь добавил симптом, обрабатываем его
    if (result != null && result.isNotEmpty) {
      _addSymptom(result);
    }
  }

  // Future<void> _quickAddSymptom(String symptomText) async {
  //   final symptom = symptomText.trim();
  //   if (symptom.isEmpty) return;

  //   try {
  //     // Добавляем симптом в глобальный список
  //     if (!_allSymptoms.any((s) => s.toLowerCase() == symptom.toLowerCase())) {
  //       final newSymptom = Symptom(name: symptom, isDefault: false);
  //       await _databaseHelper.insertSymptom(newSymptom);
  //       await _loadAllSymptoms(); // Перезагружаем список всех симптомов
  //     }

  //     // Добавляем симптом в текущий день
  //     _addSymptom(symptom);

  //     // Показываем уведомление об успехе
  //     //final l10n = AppLocalizations.of(context)!;
  //     if (mounted) {
  //       // ScaffoldMessenger.of(context).showSnackBar(
  //       //   SnackBar(
  //       //     content: Text('Симптом "$symptom" добавлен'),
  //       //     backgroundColor: Colors.green,
  //       //     duration: const Duration(seconds: 2),
  //       //   ),
  //       // );
  //     }
  //   } catch (e) {
  //     // Показываем ошибку
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Ошибка при добавлении симптома: $e'),
  //           backgroundColor: Colors.red,
  //           duration: const Duration(seconds: 3),
  //         ),
  //       );
  //     }
  //   }
  // }

  Future<void> _toggleMedicationTakenStatus(MedicationEvent event, bool isTaken) async {
    try {

      MedicationTakenRecord? existingRecord = await _databaseHelper.getMedicationTakenRecord(
        event.medicationId,
        widget.selectedDate,
        TimeOfDay(hour: event.scheduledTime.hour, minute: event.scheduledTime.minute),
      );

      MedicationTakenRecord updatedRecord; // Объявляем переменную перед блоками условий

      if (isTaken) {
        // Отмечаем как принятое
        updatedRecord = existingRecord?.copyWith(
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
          await _databaseHelper.insertMedicationTakenRecord(updatedRecord);
        } else {
          await _databaseHelper.updateMedicationTakenRecord(updatedRecord);
        }
      } else {
        // Отмечаем как непринятое
        if (existingRecord != null) {
          updatedRecord = existingRecord.copyWith(
            isTaken: false,
            actualTakenTime: null, // Сбрасываем фактическое время
          );
          await _databaseHelper.updateMedicationTakenRecord(updatedRecord);
        } else {
          // Если записи не было, создаем новую с isTaken = false
          updatedRecord = MedicationTakenRecord(
            medicationId: event.medicationId,
            date: widget.selectedDate,
            scheduledTime: TimeOfDay(hour: event.scheduledTime.hour, minute: event.scheduledTime.minute),
            isTaken: false,
          );
          await _databaseHelper.insertMedicationTakenRecord(updatedRecord);
        }
      }
      // Обновляем только локальные данные без перезагрузки всего экрана
      setState(() {
        // Обновляем записи о приеме лекарств
        final existingIndex = _takenRecords.indexWhere((record) =>
            record.medicationId == event.medicationId &&
            record.scheduledTime.hour == event.scheduledTime.hour &&
            record.scheduledTime.minute == event.scheduledTime.minute);

        if (existingIndex >= 0) {
          _takenRecords[existingIndex] = updatedRecord;
        } else {
          _takenRecords.add(updatedRecord);
        }
      });
    } catch (e) {
      // print('Ошибка при обновлении статуса приема лекарства: $e');
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshToCurrentDate,
            tooltip: l10n.refreshTooltip,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: _backgroundImage,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Основной контент
            Expanded(
              child: _buildMainContent(l10n),
            ),
            
            // Блок рекламы
            _buildBannerWidget(),
          ],
        ),
      ),
    );
  }

  // Вынесенный основной контент
  Widget _buildMainContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget(l10n);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Элемент переключения дат
          _buildDateNavigation(),
          const SizedBox(height: 16),

          // Блок "Месячные"
          _buildPeriodBlock(l10n),
          const SizedBox(height: 8),

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
    );
  }

  // Виджет навигации по датам
  Widget _buildDateNavigation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Кнопка "предыдущая"
            IconButton(
              onPressed: _goToPreviousDay,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Предыдущий день',
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            ),
            
            // Центральная часть с датой
            Expanded(
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
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Center(
                    child: Text(
                      _formatDate(context, widget.selectedDate),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Кнопка "следующая"
            IconButton(
              onPressed: _goToNextDay,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Следующий день',
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет ошибки
  Widget _buildErrorWidget(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            l10n.errorWithMessage(_errorMessage!),
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  // Вынесенный виджет баннера
  Widget _buildBannerWidget() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 8),
      height: isBannerAlreadyCreated ? 60 : 0, // Фиксированная высота
      child: isBannerAlreadyCreated 
                ? IgnorePointer(
              child: AdWidget(bannerAd: banner),
            )
          : const SizedBox.shrink(),
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
        title: Text(
          l10n.periodBlockTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                

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

                // Информация о следующих плановых месячных
                if (_nextPlannedPeriods.isNotEmpty) ...[
                  Text(
                    l10n.nextPlannedPeriodsTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._nextPlannedPeriods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final period = entry.value;
                    final daysUntil = period.startDate.difference(PeriodCalculator.getToday()).inDays;
                    final isDelay = daysUntil < 0;
                    final mainColor = isDelay ? Colors.orange : Colors.green;
                    final lightColor = isDelay ? Colors.orange[50] : Colors.green[50];
                    final iconColor = isDelay ? Colors.orange : Colors.green;
                    final textColor = isDelay ? Colors.orange : Colors.green;
                    
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: index < _nextPlannedPeriods.length - 1 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: lightColor,
                        border: Border.all(color: mainColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month, color: iconColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_formatDate(context, period.startDate)} - ${_formatDate(context, period.endDate)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.durationLabel} ${widget.settings.periodLength} ${widget.settings.periodLength == 1 ? l10n.durationDayOne : l10n.durationDayFew}',
                            style: TextStyle(fontSize: 12, color: textColor),
                          ),
                          if (index == 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDelay ? Colors.orange[100] : Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                daysUntil > 0 
                                    ? 'Через $daysUntil ${daysUntil == 1 ? l10n.durationDayOne : l10n.durationDayFew}'
                                    : daysUntil == 0 
                                        ? 'Начинается сегодня'
                                        : 'Задержка: ${-daysUntil} ${-daysUntil == 1 ? l10n.durationDayOne : l10n.durationDayFew}',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],

                // Управление периодом
                Text(
                  l10n.cycleManagementTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

                // Кнопка "Календарь месячных"
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            calledFromDetailScreen: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Календарь месячных'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
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
        title: Text(
          l10n.sexBlockTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                    Text(
                      l10n.hadSexLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Блок выбора типа секса (только если был секс)
                if (_dayNote.hadSex == true) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.sexTypeLabel,
                    style: const TextStyle(
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
                                l10n.safeSexLabel,
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
                                l10n.unsafeSexLabel,
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
                  Text(
                    l10n.orgasmLabel,
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
                                l10n.hadOrgasmLabel,
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
                                l10n.noOrgasmLabel,
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
                // if (_dayNote.hadSex == null || _dayNote.hadSex == false) ...[
                //   const SizedBox(height: 16),
                //   Text(
                //     'Если ничего не выбрано, в базу данных записывается null',
                //     style: TextStyle(
                //       fontSize: 12,
                //       color: Colors.grey[600],
                //       fontStyle: FontStyle.italic,
                //     ),
                //   ),
                // ],
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
        title: Text(
          l10n.healthBlockTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                
                // Список доступных симптомов с чекбоксами
                if (_allSymptoms.isNotEmpty) ...[
                  Text(
                    l10n.selectSymptomsLabel,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _allSymptoms.length,
                      itemBuilder: (context, index) {
                        final symptom = _allSymptoms[index];
                        final isSelected = _dayNote.symptoms.contains(symptom);
                        return CheckboxListTile(
                          title: Text(symptom),
                          value: isSelected,
                          onChanged: (bool? value) {
                            if (value == true) {
                              _addSymptom(symptom);
                            } else {
                              _removeSymptom(symptom);
                            }
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          dense: true,
                        );
                      },
                    ),
                  ),
                ] else
                  Text(
                    l10n.noAvailableSymptoms,
                    style: const TextStyle(color: Colors.grey),
                  ),
                
                const SizedBox(height: 16),
                
                // Кнопка быстрого добавления симптома
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showQuickAddSymptomDialog,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addSymptomButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Список выбранных симптомов
                if (_dayNote.symptoms.isNotEmpty) ...[
                  Text(
                    l10n.currentSymptomsTitle,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_dayNote.symptoms.toList()
                          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())))
                        .map((symptom) => Chip(
                          label: Text(symptom),
                          onDeleted: () => _removeSymptom(symptom),
                          deleteIcon: const Icon(Icons.clear, size: 18),
                          backgroundColor: Colors.pink.shade50,
                          side: BorderSide(color: Colors.pink.shade200),
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
        title: Text(
          l10n.settingsTabMedications,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (medicationEvents.isEmpty)
                  Text(
                    l10n.noMedicationRecords,
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
                            Checkbox(
                              value: event.isTaken,
                              onChanged: (bool? newValue) {
                                _toggleMedicationTakenStatus(event, newValue ?? false);
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '${l10n.medicationTimeLabel} ${DateFormat('HH:mm').format(event.scheduledTime)}',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  if (event.isTaken && event.actualTakenTime != null)
                                    Text(
                                      '${l10n.medicationTakenLabel} ${DateFormat('HH:mm').format(event.actualTakenTime!.toLocal())}',
                                      style: const TextStyle(fontSize: 12, color: Colors.green),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                
                // Кнопка для перехода к экрану лекарств
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MedicationsScreen(),
                        ),
                      );
                      
                      // Если были изменения в лекарствах, перезагружаем данные
                      if (result == true) {
                        await _loadData();
                      }
                    },
                    icon: const Icon(Icons.medication),
                    label: const Text('Управление лекарствами'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
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
    super.dispose();
  }

}

// Отдельный виджет для диалога добавления симптома
class AddSymptomDialog extends StatefulWidget {
  const AddSymptomDialog({super.key});

  @override
  State<AddSymptomDialog> createState() => _AddSymptomDialogState();
}

class _AddSymptomDialogState extends State<AddSymptomDialog> {
  late TextEditingController nameController;
  bool isAtStart = true; // Отслеживаем, находится ли курсор в начале

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    
    // Добавляем listener для отслеживания позиции курсора
    nameController.addListener(_updateKeyboardState);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // Функция для обновления состояния клавиатуры
  void _updateKeyboardState() {
    final currentPosition = nameController.selection.extentOffset;
    final newIsAtStart = currentPosition == 0;
    
    if (newIsAtStart != isAtStart) {
      setState(() {
        isAtStart = newIsAtStart;
      });
    }
  }

  Future<void> _addSymptom() async {
    final symptom = nameController.text.trim();
    if (symptom.isEmpty) return;

    try {
      // Получаем доступ к базе данных через контекст
      final databaseHelper = DatabaseHelper();
      
      // Проверяем, есть ли уже такой симптом в глобальном списке
      final allSymptoms = await databaseHelper.getAllSymptoms();
      if (!allSymptoms.any((s) => s.toLowerCase() == symptom.toLowerCase())) {
        final newSymptom = Symptom(name: symptom, isDefault: false);
        await databaseHelper.insertSymptom(newSymptom);
      }

      // Закрываем диалог и передаем результат
      if (mounted) {
        Navigator.pop(context, symptom);
      }
    } catch (e) {
      // Показываем ошибку
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при добавлении симптома: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: const Text('Добавить новый симптом'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Название симптома',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: isAtStart 
                ? TextCapitalization.sentences // Первая буква заглавная, остальные строчные
                : TextCapitalization.none,      // Все строчные буквы в середине
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addSymptom(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _addSymptom,
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}