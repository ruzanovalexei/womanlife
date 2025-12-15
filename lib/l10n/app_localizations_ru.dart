// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Будь в ритме';

  @override
  String get refreshTooltip => 'Обновить данные';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get exitTooltip => 'Закрыть приложение';

  @override
  String errorWithMessage(Object message) {
    return 'Ошибка: $message';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get calendarNextPeriod => 'Следующий цикл:';

  @override
  String calendarInDays(int days) {
    return 'Через $days дн.';
  }

  @override
  String get calendarLegendTitle => 'Обозначения:';

  @override
  String get calendarLegendPlanned => 'Плановый';

  @override
  String get calendarLegendActual => 'Фактический';

  @override
  String get calendarLegendToday => 'Сегодня';

  @override
  String get calendarLegendOvulation => 'День овуляции';

  @override
  String get calendarLegendFertile => 'Фертильные дни';

  @override
  String get calendarLegendOverdue => 'Задержка';

  @override
  String get idealTimeForConception => 'Идеальное время для зачатия';

  @override
  String get favorableTimeForConception => 'Благополучное время для зачатия';

  @override
  String get dayDetailsTitle => 'Детали дня';

  @override
  String get periodManagementTitle => 'Управление периодом';

  @override
  String get startNewPeriodButton => 'Начать новый цикл';

  @override
  String get startNewPeriodHint => 'Отметьте этот день как начало менструации';

  @override
  String activePeriodLabel(Object start) {
    return 'Активный цикл: $start - Текущая дата';
  }

  @override
  String get endPeriodButton => 'Завершить цикл';

  @override
  String get endPeriodHint => 'Отметьте этот день как конец цикла';

  @override
  String get cancelPeriodButton => 'Отменить цикл';

  @override
  String get cancelPeriodHint => 'Удалить запись о цикле';

  @override
  String get dayWithinActive => 'Этот день входит в активный цикл';

  @override
  String get dayWithinActiveHint => 'Чтобы завершить цикл, отметьте последний день';

  @override
  String lastPeriodLabel(Object start, Object end) {
    return 'Последний цикл: $start - $end';
  }

  @override
  String get lastPeriodHint => 'Новый цикл можно начать после даты окончания';

  @override
  String get removeEndDateButton => 'Удалить дату окончания';

  @override
  String get deletePeriodButton => 'Удалить цикл';

  @override
  String get deletePeriodHint => 'Сначала удалите дату окончания, затем запись';

  @override
  String get symptomsTitle => 'Симптомы';

  @override
  String get addSymptomHint => 'Добавить симптом';

  @override
  String get currentSymptomsTitle => 'Текущие симптомы:';

  @override
  String get symptomAlreadyAddedMessage => 'Симптом уже добавлен';

  @override
  String get noSymptoms => 'Симптомы не добавлены';

  @override
  String get debugInfoTitle => 'Отладочная информация:';

  @override
  String debugCanMarkStart(Object value) {
    return 'Можно отметить начало: $value';
  }

  @override
  String debugCanMarkEnd(Object value) {
    return 'Можно отметить конец: $value';
  }

  @override
  String debugIsInActivePeriod(Object value) {
    return 'День в активном цикле: $value';
  }

  @override
  String debugActivePeriod(Object value) {
    return 'Активный цикл: $value';
  }

  @override
  String debugLastPeriod(Object value) {
    return 'Последний цикл: $value';
  }

  @override
  String debugSymptomsCount(int count) {
    return 'Количество симптомов: $count';
  }

  @override
  String get symptomsSaved => 'Симптомы сохранены';

  @override
  String symptomsSaveError(Object message) {
    return 'Ошибка сохранения симптомов: $message';
  }

  @override
  String get startPeriodSuccess => 'Цикл начат';

  @override
  String startPeriodError(Object message) {
    return 'Ошибка начала цикла: $message';
  }

  @override
  String get endPeriodSuccess => 'Цикл завершен';

  @override
  String endPeriodError(Object message) {
    return 'Ошибка завершения цикла: $message';
  }

  @override
  String get cancelPeriodSuccess => 'Цикл отменен';

  @override
  String cancelPeriodError(Object message) {
    return 'Ошибка отмены цикла: $message';
  }

  @override
  String get removePeriodEndSuccess => 'Дата окончания удалена';

  @override
  String removePeriodEndError(Object message) {
    return 'Ошибка удаления даты окончания: $message';
  }

  @override
  String get deletePeriodSuccess => 'Цикл удален';

  @override
  String deletePeriodError(Object message) {
    return 'Ошибка удаления цикла: $message';
  }

  @override
  String get endDateBeforeStart => 'Дата окончания не может быть раньше даты начала';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String get settingsSaveError => 'Ошибка сохранения настроек';

  @override
  String get settingsFormCycleLength => 'Длина цикла (дни)';

  @override
  String get settingsFormPeriodLength => 'Длительность менструации (дни)';

  @override
  String get settingsFormPlanningMonths => 'Период планирования (мес.)';

  @override
  String get settingsFormSaveButton => 'Сохранить';

  @override
  String get settingsFormValueMissing => 'Введите значение';

  @override
  String get settingsFormInvalidNumber => 'Введите корректное число';

  @override
  String settingsFormRangeError(int min, int max) {
    return 'Значение должно быть от $min до $max';
  }

  @override
  String get settingsFormLanguageLabel => 'Язык';

  @override
  String get settingsFormLanguageEnglish => 'Английский';

  @override
  String get settingsFormLanguageRussian => 'Русский';

  @override
  String get settingsFormFirstDayLabel => 'Первый день календаря';

  @override
  String get settingsFormFirstDayMonday => 'Понедельник';

  @override
  String get settingsFormFirstDaySunday => 'Воскресенье';

  @override
  String get settingsTabGeneral => 'Основные';

  @override
  String get settingsTabMedications => 'Лекарства';

  @override
  String get settingsTabSymptoms => 'Симптомы';

  @override
  String get symptomHeadache => 'Головная боль';

  @override
  String get symptomFatigue => 'Усталость';

  @override
  String get symptomBloating => 'Вздутие живота';

  @override
  String get symptomIrritability => 'Раздражительность';

  @override
  String get symptomAbdominalPain => 'Боли внизу живота';

  @override
  String get symptomAcne => 'Акне';

  @override
  String get symptomSweetCravings => 'Тяга к сладкому';

  @override
  String get symptomBreastPain => 'Боль в груди';

  @override
  String get symptomCramps => 'Судороги';

  @override
  String get symptomNausea => 'Тошнота';

  @override
  String get symptomInsomnia => 'Бессонница';

  @override
  String get addSymptomTitle => 'Добавить симптом';

  @override
  String get editSymptomTitle => 'Редактировать симптом';

  @override
  String get symptomNameLabel => 'Название симптома';

  @override
  String get symptomNameRequired => 'Введите название симптома';

  @override
  String get symptomAdded => 'Симптом добавлен';

  @override
  String get symptomAddError => 'Ошибка добавления симптома';

  @override
  String get symptomUpdated => 'Симптом обновлен';

  @override
  String get symptomUpdateError => 'Ошибка обновления симптома';

  @override
  String get fillAllFields => 'Заполните все поля';

  @override
  String get deleteSymptomTitle => 'Удалить симптом';

  @override
  String deleteSymptomMessage(Object name) {
    return 'Вы уверены, что хотите удалить симптом \"$name\"?';
  }

  @override
  String get symptomDeleted => 'Симптом удален';

  @override
  String get symptomDeleteError => 'Ошибка удаления симптома';

  @override
  String get editButton => 'Редактировать';

  @override
  String get addMedicationTitle => 'Добавить лекарство';

  @override
  String get editMedicationTitle => 'Реадктировать лекарство';

  @override
  String get medicationNameLabel => 'Название лекарства';

  @override
  String get medicationStartDateLabel => 'Дата начала';

  @override
  String get medicationPickStartDate => 'Выберете дату начала приема';

  @override
  String get medicationEndDateLabel => 'Дата окончания';

  @override
  String get medicationPickEndDate => 'Выберете дату окончания приема';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get medicationNameMissingError => 'Введите название лекарства и даты приема';

  @override
  String medicationSaveError(Object message) {
    return 'Ошибка сохранения лекарства: $message';
  }

  @override
  String get noMedications => 'Нет лекарств';

  @override
  String get medicationEndDateNotSet => 'Не заданно';

  @override
  String get medicationTimes => 'Время';

  @override
  String get medicationDeleteConfirmTitle => 'Удалить лекарство';

  @override
  String medicationDeleteConfirmMessage(Object name) {
    return 'Вы уверены, что хотите удалить \"$name\"?';
  }

  @override
  String get deleteButton => 'Удалить';

  @override
  String medicationDeleteSuccess(Object name) {
    return 'Лекарство \"$name\" удалено';
  }

  @override
  String medicationDeleteError(Object message) {
    return 'Ошибка удаления лекарства: $message';
  }

  @override
  String get analyticsTitle => 'Аналитика';

  @override
  String get medicationsReportTitle => 'Отчет по приему лекарств';

  @override
  String get medicationsReportDescription => 'Подробная аналитика по приему лекарств, пропускам и соблюдению режима приема';

  @override
  String get notificationPermissionGranted => 'Разрешение на уведомления получено';

  @override
  String get notificationPermissionDenied => 'Разрешение на уведомления отклонено';

  @override
  String get notificationPermissionPermanentlyDenied => 'Разрешение на уведомления навсегда отклонено';

  @override
  String get notificationPermissionDescription => 'Необходимо для отправки напоминаний о лекарствах и менструальном цикле';

  @override
  String get exactAlarmPermissionGranted => 'Разрешение на точные будильники получено';

  @override
  String get exactAlarmPermissionDenied => 'Разрешение на точные будильники отклонено';

  @override
  String get exactAlarmPermissionPermanentlyDenied => 'Разрешение на точные будильники навсегда отклонено';

  @override
  String get exactAlarmPermissionDescription => 'Необходимо для точного планирования напоминаний о лекарствах';

  @override
  String get permissionsRequestTitle => 'Необходимы разрешения';

  @override
  String get permissionsRequestMessage => 'Для корректной работы приложения требуются следующие разрешения:';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get enable => 'Включить';

  @override
  String get openSettings => 'Настройки';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get menuTitle => 'Меню';

  @override
  String get menuSubtitle => 'Выберите нужный раздел';

  @override
  String get menu1 => 'Здоровье';

  @override
  String get menu2 => 'Распорядок дня(Ожидайте в новых релизах)';

  @override
  String get menu3 => 'Списки';

  @override
  String get menu4 => 'Привычки';

  @override
  String get menu5 => 'Заметки';

  @override
  String get menuItem1 => 'Здоровье открыто';

  @override
  String get menuItem2 => 'Распорядок дня открыт';

  @override
  String get menuItem3 => 'Список дел открыт';

  @override
  String get menuItem4 => 'Привычки открыты';

  @override
  String get menuItem5 => 'Заметки открыты';

  @override
  String get calendar => 'Календарь';

  @override
  String get listsTitle => 'Списки';

  @override
  String get addListButton => 'Добавить список';

  @override
  String get addListTitle => 'Добавить список';

  @override
  String get listNameLabel => 'Название списка';

  @override
  String get listNameRequired => 'Введите название списка';

  @override
  String get deleteListConfirmTitle => 'Удалить список';

  @override
  String deleteListConfirmMessage(Object name) {
    return 'Вы уверены, что хотите удалить список \"$name\"?';
  }

  @override
  String get addListItemButton => 'Добавить запись';

  @override
  String listProgressFormat(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get emptyListsMessage => 'Создайте первый список';

  @override
  String get emptyListItemsMessage => 'Записей пока нет';

  @override
  String get addListItemTitle => 'Добавить запись';

  @override
  String get listItemTextLabel => 'Текст записи';

  @override
  String get listItemTextRequired => 'Введите текст записи';

  @override
  String get listSaved => 'Список сохранен';

  @override
  String listSaveError(Object message) {
    return 'Ошибка сохранения списка: $message';
  }

  @override
  String get listDeleted => 'Список удален';

  @override
  String listDeleteError(Object message) {
    return 'Ошибка удаления списка: $message';
  }

  @override
  String get listItemAdded => 'Запись добавлена';

  @override
  String listItemAddError(Object message) {
    return 'Ошибка добавления записи: $message';
  }

  @override
  String get listItemUpdated => 'Запись обновлена';

  @override
  String listItemUpdateError(Object message) {
    return 'Ошибка обновления записи: $message';
  }

  @override
  String get listItemDeleted => 'Запись удалена';

  @override
  String listItemDeleteError(Object message) {
    return 'Ошибка удаления записи: $message';
  }

  @override
  String get periodBlockTitle => 'Месячные';

  @override
  String get delayLabel => 'Задержка';

  @override
  String get previousPeriodsTitle => 'Предыдущие месячные';

  @override
  String get nextPlannedPeriodsTitle => 'Следующие плановые месячные';

  @override
  String get activeLabel => '(активный)';

  @override
  String get durationLabel => 'Продолжительность:';

  @override
  String get durationDayOne => 'день';

  @override
  String get durationDayFew => 'дня';

  @override
  String get cycleManagementTitle => 'Управление циклом';

  @override
  String get sexBlockTitle => 'Секс';

  @override
  String get hadSexLabel => 'Был секс';

  @override
  String get sexTypeLabel => 'Тип секса:';

  @override
  String get safeSexLabel => 'Безопасный';

  @override
  String get unsafeSexLabel => 'Небезопасный';

  @override
  String get orgasmLabel => 'Оргазм:';

  @override
  String get hadOrgasmLabel => 'Был оргазм';

  @override
  String get noOrgasmLabel => 'Не было оргазма';

  @override
  String get healthBlockTitle => 'Самочувствие';

  @override
  String get selectSymptomsLabel => 'Выберите симптомы:';

  @override
  String get noAvailableSymptoms => 'Нет доступных симптомов. Добавьте их в настройках.';

  @override
  String get addSymptomButton => 'Добавить симптом';

  @override
  String get noMedicationRecords => 'Нет записей о лекарствах на этот день.';

  @override
  String get medicationTimeLabel => 'Время приема:';

  @override
  String get medicationTakenLabel => 'Принято:';

  @override
  String get editListTitle => 'Редактировать список';

  @override
  String get editListNameLabel => 'Название списка';

  @override
  String get listUpdated => 'Список обновлен';

  @override
  String listUpdateError(Object message) {
    return 'Ошибка обновления списка: $message';
  }

  @override
  String get notificationChannelName => 'Напоминания о лекарствах';

  @override
  String get notificationChannelDescription => 'Уведомления о приеме лекарств';

  @override
  String get notificationTitle => 'Скоро принимать лекарства!';

  @override
  String get notificationBody => 'Не забудьте принять:';

  @override
  String get notesTitle => 'Заметки';

  @override
  String get addNoteTitle => 'Добавить заметку';

  @override
  String get editNoteTitle => 'Редактировать заметку';

  @override
  String get noteTitleLabel => 'Заголовок заметки';

  @override
  String get noteContentLabel => 'Содержимое заметки';

  @override
  String get noteDateLabel => 'Дата заметки';

  @override
  String get noteRequired => 'Введите заголовок или содержимое заметки';

  @override
  String get noteSaved => 'Заметка сохранена';

  @override
  String get noteUpdated => 'Заметка обновлена';

  @override
  String get noteDeleted => 'Заметка удалена';

  @override
  String noteSaveError(Object message) {
    return 'Ошибка сохранения заметки: $message';
  }

  @override
  String noteUpdateError(Object message) {
    return 'Ошибка обновления заметки: $message';
  }

  @override
  String noteDeleteError(Object message) {
    return 'Ошибка удаления заметки: $message';
  }

  @override
  String get deleteNoteConfirmTitle => 'Удалить заметку';

  @override
  String deleteNoteConfirmMessage(Object title) {
    return 'Вы уверены, что хотите удалить заметку \"$title\"?';
  }

  @override
  String get emptyNotesMessage => 'Создайте первую заметку';

  @override
  String get settingsTabHabits => 'Привычки';

  @override
  String get habitsTitle => 'Привычки';

  @override
  String get noHabits => 'Нет привычек';

  @override
  String get executionHabitsTitle => 'Привычки выполнения';

  @override
  String get measurableHabitsTitle => 'Измеримые привычки';

  @override
  String get selectHabitTypeTitle => 'Выберите тип привычки';

  @override
  String get habitTypeExecution => 'Выполнение';

  @override
  String get habitTypeMeasurable => 'Измеримый результат';

  @override
  String get habitTypeExecutionDescription => 'Простая отметка выполнения привычки';

  @override
  String get habitTypeMeasurableDescription => 'Привычка с измеримым результатом';

  @override
  String get addHabitExecutionTitle => 'Добавить привычку выполнения';

  @override
  String get editHabitExecutionTitle => 'Редактировать привычку выполнения';

  @override
  String get addHabitMeasurableTitle => 'Добавить измеримую привычку';

  @override
  String get editHabitMeasurableTitle => 'Редактировать измеримую привычку';

  @override
  String get habitNameLabel => 'Название привычки';

  @override
  String get habitFrequencyLabel => 'Частота';

  @override
  String get habitStartDateLabel => 'Дата начала';

  @override
  String get habitEndDateLabel => 'Дата окончания';

  @override
  String get habitReminderTimeLabel => 'Время напоминания';

  @override
  String get habitGoalLabel => 'Цель';

  @override
  String get habitUnitLabel => 'Единица измерения';

  @override
  String get pickStartDate => 'Выберите дату начала';

  @override
  String get pickEndDate => 'Выберите дату окончания';

  @override
  String get fillAllRequiredFields => 'Заполните все обязательные поля';

  @override
  String get invalidTimeFormat => 'Неверный формат времени (используйте ЧЧ:ММ)';

  @override
  String get invalidGoalValue => 'Введите корректное значение цели';

  @override
  String get habitExecutionAdded => 'Привычка выполнения добавлена';

  @override
  String get habitExecutionUpdated => 'Привычка выполнения обновлена';

  @override
  String get habitMeasurableAdded => 'Измеримая привычка добавлена';

  @override
  String get habitMeasurableUpdated => 'Измеримая привычка обновлена';

  @override
  String habitSaveError(Object message) {
    return 'Ошибка сохранения привычки: $message';
  }

  @override
  String get deleteHabitTitle => 'Удалить привычку';

  @override
  String deleteHabitConfirmMessage(Object name) {
    return 'Вы уверены, что хотите удалить привычку \"$name\"?';
  }

  @override
  String get habitDeleted => 'Привычка удалена';

  @override
  String habitDeleteError(Object message) {
    return 'Ошибка удаления привычки: $message';
  }
}
