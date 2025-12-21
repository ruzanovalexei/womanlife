import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/l10n/app_localizations.dart';
import 'package:period_tracker/database/database_helper.dart';
import 'package:period_tracker/models/note_model.dart';
import 'menu_screen.dart';
import '../services/ad_banner_service.dart';
import 'package:period_tracker/services/speech_service.dart';
// import 'package:yandex_mobileads/mobile_ads.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _databaseHelper = DatabaseHelper();
  final _speechService = SpeechService();
  final _adBannerService = AdBannerService();
  late List<NoteModel> _notes;
  bool _isLoading = true;
  String? _errorMessage;
  static const _backgroundImage = AssetImage('assets/images/fon1.png');
  
  // Состояние распознавания речи
  bool _isSpeechListening = false;
  String _speechWords = '';
  String _selectedLanguage = 'ru_RU';
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // Оптимизированная инициализация экрана
  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _initializeSpeechService();
    });
  }

  // Переинициализация сервиса распознавания речи
  // Future<void> _reinitializeSpeechService() async {
  //   // final l10n = AppLocalizations.of(context)!;

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Переинициализация speech recognition...'),
  //       backgroundColor: Colors.blue,
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );

  //   await _initializeSpeechService();
    
  //   if (_speechService.isAvailable) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Speech recognition успешно инициализирован'),
  //         backgroundColor: Colors.green,
  //         duration: const Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // }

  // Инициализация сервиса распознавания речи
  Future<void> _initializeSpeechService() async {
    // final l10n = AppLocalizations.of(context)!;

    debugPrint('Initializing speech service...');
    final initialized = await _speechService.initialize();
    
    if (initialized) {
      debugPrint('Speech service initialized successfully');
      setState(() {
        _selectedLanguage = _speechService.selectedLanguage;
      });
      
      // Проверяем разрешения после инициализации
      final hasPermissions = await _speechService.hasPermissions();
      if (!hasPermissions) {
        debugPrint('No microphone permissions, requesting...');
        final granted = await _speechService.requestPermissions();
        if (!granted) {
          debugPrint('Microphone permissions not granted');
          // Показываем предупреждение, но не блокируем интерфейс
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Для использования голосовых заметок необходимо разрешение на микрофон'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      debugPrint('Failed to initialize speech service');
      
      // Показываем ошибку пользователю
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Распознавание речи недоступно. Проверьте разрешения микрофона в настройках приложения.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Настройки',
            textColor: Colors.white,
            onPressed: () {
              _speechService.openAppSettings();
            },
          ),
        ),
      );
    }
  }

  // Запуск распознавания речи
  Future<void> _startSpeechRecognition() async {
    final l10n = AppLocalizations.of(context)!;

    // Защита от двойного нажатия
    if (_isSpeechListening) {
      debugPrint('Speech recognition already active, ignoring start request');
      return;
    }

    // Показываем индикатор загрузки
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Запуск распознавания речи...'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );

    // Проверяем разрешения
    final hasPermissions = await _speechService.hasPermissions();
    if (!hasPermissions) {
      final granted = await _speechService.requestPermissions();
      if (!granted) {
        _showErrorDialog(l10n.noMicrophonePermission);
        return;
      }
    }

    // Проверяем доступность сервиса
    if (!_speechService.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Распознавание речи недоступно'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('Starting speech recognition with language: $_selectedLanguage');

    // Запускаем распознавание
    final success = await _speechService.startListening(
      onResult: (words) {
        setState(() {
          _speechWords = words;
        });
      },
      onListeningStarted: () {
        debugPrint('=== Speech recognition started callback ===');
        setState(() {
          _isSpeechListening = true;
          _speechWords = '';
        });
      },
      onListeningStopped: () {
        debugPrint('=== Speech recognition stopped callback ===');
        setState(() {
          _isSpeechListening = false;
        });
        // Если есть распознанный текст, создаем заметку
        if (_speechWords.isNotEmpty) {
          _createNoteFromSpeech();
        }
      },
      onError: (error) {
        debugPrint('Speech recognition error details: $error');
        
        // ВАЖНО: Сбрасываем состояние при ошибке
        setState(() {
          _isSpeechListening = false;
        });
        
        String errorMessage;
        if (error.contains('error_no_match')) {
          errorMessage = 'Речь не распознана. Попробуйте говорить громче и четче.';
        } else if (error.contains('error_not_available')) {
          errorMessage = 'Распознавание речи недоступно на этом устройстве.';
        } else if (error.contains('error_permission')) {
          errorMessage = 'Нет разрешения на использование микрофона.';
        } else {
          errorMessage = 'Ошибка распознавания речи: $error';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );

    if (!success) {
      setState(() {
        _isSpeechListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.speechRecognitionError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Остановка распознавания речи
  Future<void> _stopSpeechRecognition() async {
    debugPrint('Stopping speech recognition...');
    
    // Проверяем, что мы действительно слушаем
    if (!_isSpeechListening) {
      debugPrint('Speech recognition is not active, nothing to stop');
      return;
    }

    // Показываем индикатор остановки
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Остановка записи...'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      debugPrint('About to call _speechService.stopListening...');
      
      // НЕ обновляем состояние здесь - это произойдет в колбэке
      await _speechService.stopListening(
        onListeningStopped: () {
          debugPrint('=== Speech recognition stopped callback received ===');
          // Состояние уже обновлено в onListeningStarted
          
          // Если есть распознанный текст, создаем заметку
          if (_speechWords.isNotEmpty) {
            debugPrint('Creating note from speech: "$_speechWords"');
            _createNoteFromSpeech();
          } else {
            debugPrint('No speech text to create note from');
            
            // Сбрасываем состояние при отсутствии текста
            setState(() {
              _isSpeechListening = false;
              _speechWords = '';
            });
            
            // Показываем сообщение если не удалось распознать речь
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Речь не распознана. Попробуйте говорить громче и четче.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
      
      debugPrint('_speechService.stopListening completed');
      
    } catch (e, stackTrace) {
      debugPrint('=== Error in _stopSpeechRecognition ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // При ошибке принудительно сбрасываем состояние
      setState(() {
        _isSpeechListening = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при остановке записи: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Создание заметки из распознанного текста
  Future<void> _createNoteFromSpeech() async {
    if (_speechWords.trim().isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    
    // Показываем предварительный просмотр распознанного текста
    final shouldCreateNote = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Создать заметку?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Распознанный текст:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_speechWords.trim()),
              ),
              const SizedBox(height: 8),
              Text('Заголовок заметки: "Аудиозаметка"'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Создать'),
            ),
          ],
        );
      },
    );

    if (shouldCreateNote != true) {
      // Пользователь отменил создание заметки
      setState(() {
        _speechWords = '';
        _isSpeechListening = false; // Сбрасываем состояние записи
      });
      return;
    }

    final note = NoteModel(
      title: 'Аудиозаметка', // Заголовок как требовалось
      content: _speechWords.trim(),
      createdDate: now,
      updatedDate: now,
    );

    try {
      await _databaseHelper.insertNote(note);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.speechNoteCreated),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Очищаем состояние
      setState(() {
        _speechWords = '';
        _isSpeechListening = false; // Сбрасываем состояние записи
      });

      // Перезагружаем заметки
      await _loadData();
    } catch (e) {
      // При ошибке тоже сбрасываем состояние записи
      setState(() {
        _isSpeechListening = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noteSaveError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Выбор языка распознавания
  // Future<void> _selectLanguage() async {
  //   final l10n = AppLocalizations.of(context)!;
    
  //   final selected = await showDialog<String>(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text(l10n.selectLanguage),
  //         content: SizedBox(
  //           width: double.maxFinite,
  //           child: ListView.builder(
  //             shrinkWrap: true,
  //             itemCount: _speechService.availableLanguages.length,
  //             itemBuilder: (context, index) {
  //               final languageName = _speechService.availableLanguages.keys.elementAt(index);
  //               final languageCode = _speechService.availableLanguages.values.elementAt(index);
                
  //               return RadioListTile<String>(
  //                 title: Text(languageName),
  //                 value: languageCode,
  //                 groupValue: _selectedLanguage,
  //                 onChanged: (value) {
  //                   Navigator.pop(context, value);
  //                 },
  //               );
  //             },
  //           ),
  //         ),
  //       );
  //     },
  //   );

  //   if (selected != null) {
  //     setState(() {
  //       _selectedLanguage = selected;
  //     });
  //     _speechService.setLanguage(selected);
  //   }
  // }

  // Показать диалог ошибки
  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.errorDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text(
                'Для исправления:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Перейдите в настройки приложения'),
              const Text('2. Разрешите доступ к микрофону'),
              const Text('3. Проверьте интернет-соединение'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _speechService.openAppSettings();
              },
              child: const Text('Настройки'),
            ),
          ],
        );
      },
    );
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.notesTitle),
          const SizedBox(width: 8),
          // Индикатор статуса speech recognition
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _speechService.isAvailable ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.mic),
      //     onPressed: _speechService.isAvailable ? _selectLanguage : _reinitializeSpeechService,
      //     tooltip: _speechService.isAvailable ? l10n.selectLanguage : 'Переинициализировать speech recognition',
      //   ),
      //   IconButton(
      //     icon: const Icon(Icons.refresh),
      //     onPressed: _loadData,
      //     tooltip: l10n.refreshTooltip,
      //   ),
      // ],
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
          
          // Кнопка распознавания речи
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSpeechListening 
                    ? _stopSpeechRecognition 
                    : _startSpeechRecognition,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isSpeechListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    key: ValueKey(_isSpeechListening),
                  ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _isSpeechListening 
                        ? 'Остановить запись' 
                        : 'Голосовая заметка',
                    key: ValueKey(_isSpeechListening),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSpeechListening ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ),
          
          // Блок рекламы
          _adBannerService.createBannerWidget(),
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
          children: [
            Expanded(
              child: Text(
                l10n.addNoteTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Индикатор состояния speech-to-text
            if (_isSpeechListening) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      l10n.listeningIndicator,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Кнопка добавления заметки
            SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: _showAddNoteDialog,
                heroTag: "add_note",
                tooltip: 'Добавить заметку',
                child: const Icon(Icons.add, size: 24),
              ),
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