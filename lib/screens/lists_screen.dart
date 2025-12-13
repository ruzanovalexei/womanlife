import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/list_model.dart';
import 'package:period_tracker/models/list_item_model.dart';
// import 'package:period_tracker/utils/date_utils.dart';
import 'menu_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  _ListsScreenState createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final _databaseHelper = DatabaseHelper();
  late List<ListModel> _lists;
  bool _isLoading = true;
  String? _errorMessage;

  // Состояние блоков (по умолчанию все раскрыты)
  final Map<int, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _lists = await _databaseHelper.getAllLists();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddListDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addListTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.listNameLabel,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (_) {
                  Navigator.pop(context);
                  _saveList(nameController.text);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveList(nameController.text);
              },
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveList(String name) async {
    final l10n = AppLocalizations.of(context)!;
    final trimmedName = name.trim();
    
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listNameRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final newList = ListModel(
        name: trimmedName,
        createdDate: now,
        updatedDate: now,
      );

      await _databaseHelper.insertList(newList);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listSaved),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      await _loadData();
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listSaveError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteList(ListModel list) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteListConfirmTitle),
          content: Text(l10n.deleteListConfirmMessage(list.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _databaseHelper.deleteList(list.id!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listDeleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        await _loadData();
      } catch (e) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listDeleteError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showAddListItemDialog(int listId) async {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addListItemTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: l10n.listItemTextLabel,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (_) {
                  Navigator.pop(context);
                  _saveListItem(listId, textController.text);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveListItem(listId, textController.text);
              },
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveListItem(int listId, String text) async {
    final l10n = AppLocalizations.of(context)!;
    final trimmedText = text.trim();
    
    if (trimmedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listItemTextRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final newItem = ListItemModel(
        listId: listId,
        text: trimmedText,
        createdDate: now,
        updatedDate: now,
      );

      await _databaseHelper.insertListItem(newItem);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listItemAdded),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      await _loadData();
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listItemAddError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _toggleListItemStatus(ListItemModel item) async {
    try {
      await _databaseHelper.toggleListItemStatus(item.id!, !item.isCompleted);
      await _loadData();
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listItemUpdateError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<Map<String, int>> _getListProgress(int listId) async {
    return await _databaseHelper.getListProgress(listId);
  }

  Future<List<ListItemModel>> _getListItems(int listId) async {
    return await _databaseHelper.getListItemsByListId(listId);
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
        title: Text(l10n.listsTitle),
        actions: [
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
                      ? Center(
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
                        )
                      : _lists.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.checklist,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.emptyListsMessage,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _lists.length,
                              itemBuilder: (context, index) {
                                final list = _lists[index];
                                return _buildListBlock(list, l10n);
                              },
                            ),
            ),

            // Кнопка добавления списка
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _showAddListDialog,
                icon: const Icon(Icons.add),
                label: Text(l10n.addListButton),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBlock(ListModel list, AppLocalizations l10n) {
    final isExpanded = _expandedStates[list.id] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedStates[list.id!] = expanded;
          });
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                list.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            FutureBuilder<Map<String, int>>(
              future: _getListProgress(list.id!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final progress = snapshot.data!;
                  final completed = progress['completed']!;
                  final total = progress['total']!;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.listProgressFormat(completed, total),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteList(list),
          tooltip: l10n.deleteButton,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Кнопка добавления записи
                ElevatedButton.icon(
                  onPressed: () => _showAddListItemDialog(list.id!),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.addListItemButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[100],
                    foregroundColor: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 16),

                // Список записей
                FutureBuilder<List<ListItemModel>>(
                  future: _getListItems(list.id!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final items = snapshot.data!;
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.emptyListItemsMessage,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: items.map((item) {
                          return _buildListItem(item, l10n);
                        }).toList(),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(ListItemModel item, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) => _toggleListItemStatus(item),
        ),
        title: Text(
          item.text,
          style: TextStyle(
            decoration: item.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: item.isCompleted ? Colors.grey[600] : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 16),
          onPressed: () => _deleteListItem(item),
          tooltip: l10n.deleteButton,
        ),
      ),
    );
  }

  Future<void> _deleteListItem(ListItemModel item) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteButton),
          content: const Text('Вы уверены, что хотите удалить эту запись?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _databaseHelper.deleteListItem(item.id!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listItemDeleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        await _loadData();
      } catch (e) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listItemDeleteError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}