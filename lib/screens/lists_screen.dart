// lib/screens/lists_screen_optimized.dart
import 'package:flutter/material.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/list_model.dart';
import 'package:period_tracker/models/list_item_model.dart';
import 'menu_screen.dart';
import '../services/ad_banner_service.dart';

/// Оптимизированный экран списков
/// Реклама и основной экран не пересоздаются при обновлении списков
class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  _ListsScreenState createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final _adBannerService = AdBannerService();
  static const _backgroundImage = AssetImage('assets/images/fon1.png');

  @override
  void initState() {
    super.initState();
    // Инициализация сервиса рекламы при создании экрана
    _adBannerService.initialize();
  }

  // @override
  // void dispose() {
  //   // Очистка рекламы при закрытии экрана
  //   _adBannerService.clearBannerOnScreenChange();
  //   super.dispose();
  // }

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
            // Основной контент - только списки (обновляются независимо)
            const Expanded(
              child: ListsWidget(),
            ),
            
            // Блок рекламы (статичный, не пересоздается)
            _adBannerService.createBannerWidget(),
          ],
        ),
      ),
    );
  }
}

/// Отдельный виджет для работы со списками
/// Содержит всю логику управления списками и обновляется независимо от основного экрана
class ListsWidget extends StatefulWidget {
  const ListsWidget({super.key});

  @override
  _ListsWidgetState createState() => _ListsWidgetState();
}

class _ListsWidgetState extends State<ListsWidget> {
  final _databaseHelper = DatabaseHelper();
  late List<ListModel> _lists;
  bool _isLoading = true;
  String? _errorMessage;
  // ID открытого списка (только один список может быть открыт одновременно)
  int? _expandedListId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Оптимизированная загрузка данных - один setState
  Future<void> _loadData() async {
    try {
      final lists = await _databaseHelper.getAllLists();
      
      if (mounted) {
        setState(() {
          _lists = lists;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        debugPrint('Error loading lists: $e');
      }
    }
  }

  Future<void> _showAddListDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return const AddListDialog();
      },
    );

    // Если пользователь добавил список, обрабатываем его
    if (result != null && result.isNotEmpty) {
      await _saveList(result);
    }
  }

  Future<void> _showEditListDialog(ListModel list) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return EditListDialog(initialName: list.name);
      },
    );

    // Если пользователь обновил список, обрабатываем его
    if (result != null && result.isNotEmpty) {
      await _updateList(list, result);
    }
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listSaved),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listSaveError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        debugPrint('Error saving list: $e');
      }
    }
  }

  Future<void> _updateList(ListModel list, String name) async {
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
      final updatedList = ListModel(
        id: list.id,
        name: trimmedName,
        createdDate: list.createdDate,
        updatedDate: now,
      );

      await _databaseHelper.updateList(updatedList);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.listUpdated),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        await _loadData();
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listUpdateError(e.toString())),
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.listDeleted),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );

          await _loadData();
        }
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
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AddListItemDialog();
      },
    );

    // Если пользователь добавил запись, обрабатываем ее
    if (result != null && result.isNotEmpty) {
      await _saveListItem(listId, result);
    }
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
      
      // Обновляем только списки, не весь экран
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
      // Обновляем только списки, не весь экран
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
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и кнопка добавления
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.addListTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FloatingActionButton(
                onPressed: _showAddListDialog,
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Списки
          Expanded(
            child: _buildListsContent(l10n),
          ),
        ],
      ),
    );
  }

  // Вынесенный контент списков
  Widget _buildListsContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget(l10n);
    }
    
    if (_lists.isEmpty) {
      return _buildEmptyWidget(l10n);
    }
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _lists.length,
      itemBuilder: (context, index) {
        final list = _lists[index];
        return _buildListBlock(list, l10n);
      },
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

  // Виджет пустого состояния
  Widget _buildEmptyWidget(AppLocalizations l10n) {
    return Center(
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
    );
  }

  Widget _buildListBlock(ListModel list, AppLocalizations l10n) {
    final isExpanded = _expandedListId == list.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Заголовок блока
          ListTile(
            title: FutureBuilder<Map<String, int>>(
              future: _getListProgress(list.id!),
              builder: (context, snapshot) {
                final progress = snapshot.data ?? {'completed': 0, 'total': 0};
                final completed = progress['completed']!;
                final total = progress['total']!;
                final isCompleted = total > 0 && completed == total;
                
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        list.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          color: isCompleted ? Colors.grey[600] : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green[100] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.listProgressFormat(completed, total),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.green[700] : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditListDialog(list),
                  tooltip: l10n.editButton,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteList(list),
                  tooltip: l10n.deleteButton,
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  // Если список открыт, закрываем его
                  _expandedListId = null;
                } else {
                  // Если список закрыт, открываем только его
                  _expandedListId = list.id;
                }
              });
            },
          ),
          
          // Содержимое блока с анимацией
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: isExpanded ? _buildListContent(list, l10n) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(ListModel list, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Кнопка добавления записи
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddListItemDialog(list.id!),
              icon: const Icon(Icons.add),
              label: Text(l10n.addListItemButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
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

                // Сортируем элементы: сначала невыполненные, потом выполненные
                final sortedItems = items.toList()
                  ..sort((a, b) {
                    // Сначала сравниваем по статусу выполнения
                    if (a.isCompleted != b.isCompleted) {
                      return a.isCompleted ? 1 : -1; // невыполненные (-1) идут первыми
                    }
                    // Если статус одинаковый, сортируем по дате создания (новые первыми)
                    return b.createdDate.compareTo(a.createdDate);
                  });

                return Column(
                  children: sortedItems.map((item) {
                    return _buildListItem(item, l10n);
                  }).toList(),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.listItemDeleted),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );

          await _loadData();
        }
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

// Отдельный виджет для диалога добавления списка
class AddListDialog extends StatefulWidget {
  const AddListDialog({super.key});

  @override
  State<AddListDialog> createState() => _AddListDialogState();
}

class _AddListDialogState extends State<AddListDialog> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            textCapitalization: isAtStart 
                ? TextCapitalization.sentences // Первая буква заглавная, остальные строчные
                : TextCapitalization.none,      // Все строчные буквы в середине
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _saveList,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  void _saveList() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listNameRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, name);
  }
}

// Отдельный виджет для диалога редактирования списка
class EditListDialog extends StatefulWidget {
  final String initialName;
  
  const EditListDialog({super.key, required this.initialName});

  @override
  State<EditListDialog> createState() => _EditListDialogState();
}

class _EditListDialogState extends State<EditListDialog> {
  late TextEditingController nameController;
  bool isAtStart = true; // Отслеживаем, находится ли курсор в начале

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.editListTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.editListNameLabel,
              border: const OutlineInputBorder(),
            ),
            textCapitalization: isAtStart 
                ? TextCapitalization.sentences // Первая буква заглавная, остальные строчные
                : TextCapitalization.none,      // Все строчные буквы в середине
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _saveList,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  void _saveList() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listNameRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, name);
  }
}

// Отдельный виджет для диалога добавления записи в список
class AddListItemDialog extends StatefulWidget {
  const AddListItemDialog({super.key});

  @override
  State<AddListItemDialog> createState() => _AddListItemDialogState();
}

class _AddListItemDialogState extends State<AddListItemDialog> {
  late TextEditingController textController;
  bool isAtStart = true; // Отслеживаем, находится ли курсор в начале

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    
    // Добавляем listener для отслеживания позиции курсора
    textController.addListener(_updateKeyboardState);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  // Функция для обновления состояния клавиатуры
  void _updateKeyboardState() {
    final currentPosition = textController.selection.extentOffset;
    final newIsAtStart = currentPosition == 0;
    
    if (newIsAtStart != isAtStart) {
      setState(() {
        isAtStart = newIsAtStart;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            textCapitalization: isAtStart 
                ? TextCapitalization.sentences // Первая буква заглавная, остальные строчные
                : TextCapitalization.none,      // Все строчные буквы в середине
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveItem(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _saveItem,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  void _saveItem() {
    final text = textController.text.trim();

    if (text.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listItemTextRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, text);
  }
}