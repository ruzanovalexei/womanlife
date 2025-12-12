import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import '../database/database_helper.dart';
import '../models/symptom.dart';

class SymptomsTab extends StatefulWidget {
  const SymptomsTab({super.key});

  @override
  _SymptomsTabState createState() => _SymptomsTabState();
}

class _SymptomsTabState extends State<SymptomsTab> {
  final _databaseHelper = DatabaseHelper();
  List<Symptom> _symptoms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final symptoms = await _databaseHelper.getAllSymptomsAsObjects();
      setState(() {
        _symptoms = symptoms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddSymptomDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addSymptomTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.symptomNameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.symptomNameRequired),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final newSymptom = Symptom(
                    name: name,
                    isDefault: false,
                  );

                  await _databaseHelper.insertSymptom(newSymptom);
                  Navigator.pop(context);
                  await _loadSymptoms();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.symptomAdded),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.symptomAddError),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditSymptomDialog(Symptom symptom) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: symptom.name);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.editSymptomTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.symptomNameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.fillAllFields),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final updatedSymptom = symptom.copyWith(
                    name: name,
                  );

                  await _databaseHelper.updateSymptom(updatedSymptom);
                  Navigator.pop(context);
                  await _loadSymptoms();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.symptomUpdated),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.symptomUpdateError),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteSymptomDialog(Symptom symptom) async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteSymptomTitle),
          content: Text('Вы уверены, что хотите удалить симптом "${symptom.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _databaseHelper.deleteSymptom(symptom.id!);
                  Navigator.pop(context);
                  await _loadSymptoms();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.symptomDeleted),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.symptomDeleteError),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
    );
  }

  

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/fon1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и кнопка добавления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.symptomsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showAddSymptomDialog,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Список симптомов
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.errorWithMessage(_errorMessage!)),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: _loadSymptoms,
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        )
                      : _symptoms.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noSymptoms,
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _symptoms.length,
                              itemBuilder: (context, index) {
                                final symptom = _symptoms[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  elevation: 1, // Возвращаем небольшую тень
                                  child: Container(
                                    height: 56, // Увеличиваем высоту
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Убираем вертикальный отступ полностью
                                      minLeadingWidth: 14, // Уменьшаем ширину области иконки
                                      minVerticalPadding: 0, // Убираем минимальный вертикальный отступ
                                      //visualDensity: VisualDensity(horizontal: 0, vertical: -1), // Более плотное расположение вверх
                                      titleAlignment: ListTileTitleAlignment.center, // Центрируем title
                                      leading: Icon(
                                        symptom.isDefault ? Icons.star : Icons.circle,
                                        color: symptom.isDefault ? Colors.amber : Colors.grey,
                                        size: 20, // Оставляем размер иконки
                                      ),
                                      title: Text(
                                        symptom.name,
                                        style: const TextStyle(fontSize: 18), // Уменьшаем шрифт
                                      ),
                                      // subtitle: Text(
                                      //   symptom.isDefault ? 'По умолчанию' : 'Пользовательский',
                                      //   style: const TextStyle(fontSize: 9),
                                      // ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () => _showEditSymptomDialog(symptom),
                                            icon: const Icon(Icons.edit, size: 20), // Уменьшаем кнопку
                                            tooltip: l10n.editButton,
                                            padding: const EdgeInsets.all(2),
                                            visualDensity: VisualDensity.compact, // Компактная кнопка
                                          ),
                                          if (!symptom.isDefault)
                                            IconButton(
                                              onPressed: () => _showDeleteSymptomDialog(symptom),
                                              icon: const Icon(Icons.delete, size: 20), // Уменьшаем кнопку
                                              color: Colors.red,
                                              tooltip: l10n.deleteButton,
                                              padding: const EdgeInsets.all(2),
                                              visualDensity: VisualDensity.compact, // Компактная кнопка
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}