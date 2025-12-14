import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/note_model.dart';
import 'menu_screen.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _databaseHelper = DatabaseHelper();
  late List<NoteModel> _notes;
  bool _isLoading = true;
  String? _errorMessage;

  // Реклама
  late BannerAd banner;
  var isBannerAlreadyCreated = false;

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
      final notes = await _databaseHelper.getAllNotes();
      
      if (mounted) {
        setState(() {
          _notes = notes;
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
        debugPrint('Error loading notes: $e');
      }
    }
  }

  Future<void> _showAddNoteDialog() async {
    if (!mounted) return;
    
    final result = await showDialog<NoteModel>(
      context: context,
      builder: (context) {
        return const AddNoteDialog();
      },
    );

    // Если пользователь добавил заметку, обрабатываем её
    if (result != null && mounted) {
      await _saveNote(result);
    }
  }

  Future<void> _showEditNoteDialog(NoteModel note) async {
    if (!mounted) return;
    
    final result = await showDialog<NoteModel>(
      context: context,
      builder: (context) {
        return EditNoteDialog(note: note);
      },
    );

    // Если пользователь обновил заметку, обрабатываем её
    if (result != null && mounted) {
      await _updateNote(result);
    }
  }

  Future<void> _saveNote(NoteModel note) async {
    final l10n = AppLocalizations.of(context)!;
    
    if (note.title.trim().isEmpty && note.content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noteRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _databaseHelper.insertNote(note);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noteSaved),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      await _loadData();
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noteSaveError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _updateNote(NoteModel note) async {
    final l10n = AppLocalizations.of(context)!;
    
    if (note.title.trim().isEmpty && note.content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noteRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _databaseHelper.updateNote(note);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noteUpdated),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      await _loadData();
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noteUpdateError(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteNote(NoteModel note) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteNoteConfirmTitle),
          content: Text(l10n.deleteNoteConfirmMessage(note.title.isNotEmpty ? note.title : note.content.substring(0, note.content.length > 20 ? 20 : note.content.length))),
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
        await _databaseHelper.deleteNote(note.id!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noteDeleted),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        await _loadData();
      } catch (e) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noteDeleteError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
      title: Text(l10n.notesTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: l10n.refreshTooltip,
        ),
      ],
    ),
    body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/fon1.png'),
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
              l10n.addNoteTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            FloatingActionButton(
              onPressed: _showAddNoteDialog,
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Список заметок
        Expanded(
          child: _buildNotesList(l10n),
        ),
      ],
    ),
  );
}

// Вынесенный список заметок
Widget _buildNotesList(AppLocalizations l10n) {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  
  if (_errorMessage != null) {
    return _buildErrorWidget(l10n);
  }
  
  if (_notes.isEmpty) {
    return _buildEmptyWidget(l10n);
  }
  
  return ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: _notes.length,
    itemBuilder: (context, index) {
      final note = _notes[index];
      return _buildNoteCard(note, l10n);
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
          Icons.sticky_note_2,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.emptyNotesMessage,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}

// Виджет баннера
Widget _buildBannerWidget() {
  return Container(
    alignment: Alignment.bottomCenter,
    padding: const EdgeInsets.only(bottom: 8),
    height: isBannerAlreadyCreated ? 60 : 0,
    child: isBannerAlreadyCreated 
        ? AdWidget(bannerAd: banner)
        : const SizedBox.shrink(),
  );
}

  Widget _buildNoteCard(NoteModel note, AppLocalizations l10n) {
    final localeTag = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', localeTag);
    
    // Определяем заголовок карточки
    String displayTitle;
    if (note.title.isNotEmpty) {
      displayTitle = note.title;
    } else {
      displayTitle = note.content.length > 20 
          ? '${note.content.substring(0, 20)}...' 
          : note.content;
    }
    
    // Обрезаем содержимое до 2 строк
    String displayContent = note.content;
    if (displayContent.length > 100) {
      displayContent = '${displayContent.substring(0, 100)}...';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditNoteDialog(note),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Дата и время создания
              Text(
                dateFormat.format(note.createdDate.toLocal()),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              
              // Заголовок или начало содержимого
              Text(
                displayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Содержимое заметки (максимум 2 строки)
              Text(
                displayContent,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Кнопки редактирования и удаления
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () => _showEditNoteDialog(note),
                    tooltip: l10n.editButton,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _deleteNote(note),
                    tooltip: l10n.deleteButton,
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

// Диалог добавления заметки
class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({super.key});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  bool isAtStart = true; // Отслеживаем, находится ли курсор в начале

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    contentController = TextEditingController();
    
    // Добавляем listener для отслеживания позиции курсора
    titleController.addListener(_updateKeyboardState);
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  // Функция для обновления состояния клавиатуры
  void _updateKeyboardState() {
    final currentPosition = titleController.selection.extentOffset;
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
    final now = DateTime.now();

    return AlertDialog(
      title: Text(l10n.addNoteTitle),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      content: SizedBox(
        width: MediaQuery.of(context).size.width - 40, // Максимальная ширина минус отступы
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 40,
          ),
          child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Дата заметки
            Text(
              '${l10n.noteDateLabel}: ${DateFormat('dd.MM.yyyy HH:mm').format(now)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            
            // Поле заголовка
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: l10n.noteTitleLabel,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: isAtStart 
                  ? TextCapitalization.sentences // Первая буква заглавная, остальные строчные
                  : TextCapitalization.none,      // Все строчные буквы в середине
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            // Поле содержимого
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: l10n.noteContentLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6, // Фиксированная высота для многострочного поля
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
        ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _saveNote,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  void _saveNote() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    
    if (title.isEmpty && content.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noteRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final note = NoteModel(
      title: title,
      content: content,
      createdDate: now,
      updatedDate: now,
    );

    Navigator.pop(context, note);
  }
}

// Диалог редактирования заметки
class EditNoteDialog extends StatefulWidget {
  final NoteModel note;
  
  const EditNoteDialog({super.key, required this.note});

  @override
  State<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  bool isAtStart = true; // Отслеживаем, находится ли курсор в начале

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
    
    // Добавляем listener для отслеживания позиции курсора
    titleController.addListener(_updateKeyboardState);
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  // Функция для обновления состояния клавиатуры
  void _updateKeyboardState() {
    final currentPosition = titleController.selection.extentOffset;
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
      title: Text(l10n.editNoteTitle),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      content: SizedBox(
        width: MediaQuery.of(context).size.width - 40, // Максимальная ширина минус отступы
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 40,
          ),
          child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Дата создания заметки
            Text(
              '${l10n.noteDateLabel}: ${DateFormat('dd.MM.yyyy HH:mm').format(widget.note.createdDate.toLocal())}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            
            // Поле заголовка
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: l10n.noteTitleLabel,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: isAtStart 
                  ? TextCapitalization.sentences // Первая буква заглавная, остальные строчные
                  : TextCapitalization.none,      // Все строчные буквы в середине
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            // Поле содержимого
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: l10n.noteContentLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6, // Фиксированная высота для многострочного поля
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
        ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _saveNote,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  void _saveNote() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    
    if (title.isEmpty && content.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noteRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final updatedNote = NoteModel(
      id: widget.note.id,
      title: title,
      content: content,
      createdDate: widget.note.createdDate,
      updatedDate: now,
    );

    Navigator.pop(context, updatedNote);
  }
}