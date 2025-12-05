import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import '../models/medication.dart';
import '../database/database_helper.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analyticsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard(
            context,
            title: l10n.medicationsReportTitle,
            description: l10n.medicationsReportDescription,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicationsReportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.medical_information,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Экран отчета по приему лекарств
class MedicationsReportScreen extends StatefulWidget {
  const MedicationsReportScreen({super.key});

  @override
  _MedicationsReportScreenState createState() => _MedicationsReportScreenState();
}

class _MedicationsReportScreenState extends State<MedicationsReportScreen> {
  final _databaseHelper = DatabaseHelper();
  
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  Medication? _selectedMedication;
  List<Medication> _availableMedications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedicationsForMonth();
  }

  Future<void> _loadMedicationsForMonth() async {
    setState(() {
      _isLoading = true;
      _selectedMedication = null;
    });

    try {
      final allMedications = await _databaseHelper.getAllMedications();
      final medicationsForMonth = allMedications.where((med) {
        return med.isActiveOn(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
      }).toList();

      setState(() {
        _availableMedications = medicationsForMonth;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Показать ошибку пользователю
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки лекарств: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationsReportTitle),
      ),
      body: Column(
        children: [
          // Фильтры
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Фильтры отчета',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Фильтр месяца
                  Text(
                    'Месяц',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DateTime>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _buildMonthItems(),
                    onChanged: (DateTime? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMonth = newValue;
                        });
                        _loadMedicationsForMonth();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Фильтр лекарства
                  Text(
                    'Лекарство',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<Medication>(
                          value: _selectedMedication,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _buildMedicationItems(),
                          onChanged: (Medication? newValue) {
                            setState(() {
                              _selectedMedication = newValue;
                            });
                          },
                        ),
                ],
              ),
            ),
          ),
          
          // Контент отчета
          Expanded(
            child: _buildReportContent(),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<DateTime>> _buildMonthItems() {
    List<DropdownMenuItem<DateTime>> items = [];
    
    // Добавляем текущий месяц и предыдущие 11 месяцев
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      items.add(
        DropdownMenuItem<DateTime>(
          value: month,
          child: Text(DateFormat('MMMM yyyy', 'ru').format(month)),
        ),
      );
    }
    
    return items;
  }

  List<DropdownMenuItem<Medication>> _buildMedicationItems() {
    if (_availableMedications.isEmpty) {
      return [
        const DropdownMenuItem<Medication>(
          value: null,
          child: Text('Нет лекарств в выбранном месяце'),
        ),
      ];
    }

    List<DropdownMenuItem<Medication>> items = [
      const DropdownMenuItem<Medication>(
        value: null,
        child: Text('Все лекарства'),
      ),
    ];

    for (Medication medication in _availableMedications) {
      items.add(
        DropdownMenuItem<Medication>(
          value: medication,
          child: Text(medication.name),
        ),
      );
    }

    return items;
  }

  Widget _buildReportContent() {
    if (_selectedMedication == null && _availableMedications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет данных для отображения',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Выберите месяц с запланированными лекарствами',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(
            'Отчет сформирован',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Здесь будет отображаться аналитика\nпо приему лекарств',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}