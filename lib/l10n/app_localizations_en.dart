// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stay in Rhythm';

  @override
  String get refreshTooltip => 'Refresh data';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get exitTooltip => 'Exit app';

  @override
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get retry => 'Retry';

  @override
  String get calendarNextPeriod => 'Next Period:';

  @override
  String calendarInDays(int days) {
    return 'In $days days';
  }

  @override
  String get calendarLegendTitle => 'Legend:';

  @override
  String get calendarLegendPlanned => 'Planned';

  @override
  String get calendarLegendActual => 'Actual';

  @override
  String get calendarLegendToday => 'Today';

  @override
  String get calendarLegendOvulation => 'Ovulation';

  @override
  String get calendarLegendFertile => 'Fertile days';

  @override
  String get calendarLegendOverdue => 'Delay';

  @override
  String get idealTimeForConception => 'Ideal time for conception';

  @override
  String get favorableTimeForConception => 'Favorable time for conception';

  @override
  String get dayDetailsTitle => 'Day Details';

  @override
  String get periodManagementTitle => 'Period Management';

  @override
  String get startNewPeriodButton => 'Start New Period';

  @override
  String get startNewPeriodHint => 'Mark this day as the start of your period';

  @override
  String activePeriodLabel(Object start) {
    return 'Active period: $start - Present';
  }

  @override
  String get endPeriodButton => 'End Period Here';

  @override
  String get endPeriodHint => 'Mark this day as the end of your period';

  @override
  String get cancelPeriodButton => 'Cancel Period';

  @override
  String get cancelPeriodHint => 'Remove this period record';

  @override
  String get dayWithinActive => 'This day is within an active period';

  @override
  String get dayWithinActiveHint => 'To end the period, mark the last day of bleeding';

  @override
  String lastPeriodLabel(Object start, Object end) {
    return 'Last period: $start - $end';
  }

  @override
  String get lastPeriodHint => 'You can start a new period after the end date';

  @override
  String get removeEndDateButton => 'Remove End Date';

  @override
  String get deletePeriodButton => 'Delete Period';

  @override
  String get deletePeriodHint => 'First remove the end date, then you can delete the entire record if needed';

  @override
  String get symptomsTitle => 'Symptoms';

  @override
  String get addSymptomHint => 'Add symptom';

  @override
  String get currentSymptomsTitle => 'Current symptoms:';

  @override
  String get symptomAlreadyAddedMessage => 'Symptom already added';

  @override
  String get noSymptoms => 'No symptoms added';

  @override
  String get debugInfoTitle => 'Debug Info:';

  @override
  String debugCanMarkStart(Object value) {
    return 'Can mark start: $value';
  }

  @override
  String debugCanMarkEnd(Object value) {
    return 'Can mark end: $value';
  }

  @override
  String debugIsInActivePeriod(Object value) {
    return 'Is in active period: $value';
  }

  @override
  String debugActivePeriod(Object value) {
    return 'Active period: $value';
  }

  @override
  String debugLastPeriod(Object value) {
    return 'Last period: $value';
  }

  @override
  String debugSymptomsCount(int count) {
    return 'Symptoms count: $count';
  }

  @override
  String get symptomsSaved => 'Symptoms saved successfully';

  @override
  String symptomsSaveError(Object message) {
    return 'Error saving symptoms: $message';
  }

  @override
  String get startPeriodSuccess => 'Period started successfully';

  @override
  String startPeriodError(Object message) {
    return 'Error starting period: $message';
  }

  @override
  String get endPeriodSuccess => 'Period ended successfully';

  @override
  String endPeriodError(Object message) {
    return 'Error ending period: $message';
  }

  @override
  String get cancelPeriodSuccess => 'Period cancelled successfully';

  @override
  String cancelPeriodError(Object message) {
    return 'Error cancelling period: $message';
  }

  @override
  String get removePeriodEndSuccess => 'Period end removed';

  @override
  String removePeriodEndError(Object message) {
    return 'Error removing period end: $message';
  }

  @override
  String get deletePeriodSuccess => 'Period deleted';

  @override
  String deletePeriodError(Object message) {
    return 'Error deleting period: $message';
  }

  @override
  String get endDateBeforeStart => 'End date cannot be earlier than start date';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get settingsSaveError => 'Error saving settings';

  @override
  String get settingsFormCycleLength => 'Cycle Length (days)';

  @override
  String get settingsFormPeriodLength => 'Period Length (days)';

  @override
  String get settingsFormPlanningMonths => 'Planning Period (months)';

  @override
  String get settingsFormSaveButton => 'Save Settings';

  @override
  String get settingsFormValueMissing => 'Please enter a value';

  @override
  String get settingsFormInvalidNumber => 'Please enter a valid number';

  @override
  String settingsFormRangeError(int min, int max) {
    return 'Value must be between $min and $max';
  }

  @override
  String get settingsFormLanguageLabel => 'Language';

  @override
  String get settingsFormLanguageEnglish => 'English';

  @override
  String get settingsFormLanguageRussian => 'Russian';

  @override
  String get settingsFormFirstDayLabel => 'Calendar first day';

  @override
  String get settingsFormFirstDayMonday => 'Monday';

  @override
  String get settingsFormFirstDaySunday => 'Sunday';

  @override
  String get settingsTabGeneral => 'General';

  @override
  String get settingsTabMedications => 'Medications';

  @override
  String get settingsTabSymptoms => 'Symptoms';

  @override
  String get symptomHeadache => 'Headache';

  @override
  String get symptomFatigue => 'Fatigue';

  @override
  String get symptomBloating => 'Bloating';

  @override
  String get symptomIrritability => 'Irritability';

  @override
  String get symptomAbdominalPain => 'Abdominal pain';

  @override
  String get symptomAcne => 'Acne';

  @override
  String get symptomSweetCravings => 'Sweet cravings';

  @override
  String get symptomBreastPain => 'Breast pain';

  @override
  String get symptomCramps => 'Cramps';

  @override
  String get symptomNausea => 'Nausea';

  @override
  String get symptomInsomnia => 'Insomnia';

  @override
  String get addSymptomTitle => 'Add Symptom';

  @override
  String get editSymptomTitle => 'Edit Symptom';

  @override
  String get symptomNameLabel => 'Symptom Name';

  @override
  String get symptomNameRequired => 'Enter symptom name';

  @override
  String get symptomAdded => 'Symptom added';

  @override
  String get symptomAddError => 'Error adding symptom';

  @override
  String get symptomUpdated => 'Symptom updated';

  @override
  String get symptomUpdateError => 'Error updating symptom';

  @override
  String get fillAllFields => 'Fill all fields';

  @override
  String get deleteSymptomTitle => 'Delete Symptom';

  @override
  String deleteSymptomMessage(Object name) {
    return 'Are you sure you want to delete symptom \"$name\"?';
  }

  @override
  String get symptomDeleted => 'Symptom deleted';

  @override
  String get symptomDeleteError => 'Error deleting symptom';

  @override
  String get editButton => 'Edit';

  @override
  String get addMedicationTitle => 'Add Medication';

  @override
  String get editMedicationTitle => 'Edit Medication';

  @override
  String get medicationNameLabel => 'Medication Name';

  @override
  String get medicationStartDateLabel => 'Start Date';

  @override
  String get medicationPickStartDate => 'Pick start date';

  @override
  String get medicationEndDateLabel => 'End Date';

  @override
  String get medicationPickEndDate => 'Pick end date (optional)';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get medicationNameMissingError => 'Enter medication name and start date';

  @override
  String medicationSaveError(Object message) {
    return 'Error saving medication: $message';
  }

  @override
  String get noMedications => 'No medications added';

  @override
  String get medicationEndDateNotSet => 'Not set';

  @override
  String get medicationTimes => 'Times';

  @override
  String get medicationDeleteConfirmTitle => 'Delete Medication';

  @override
  String medicationDeleteConfirmMessage(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String medicationDeleteSuccess(Object name) {
    return 'Medication \"$name\" deleted';
  }

  @override
  String medicationDeleteError(Object message) {
    return 'Error deleting medication: $message';
  }

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get dayReportTitle => 'Daily Report';

  @override
  String get medicationsReportTitle => 'Medications Report';

  @override
  String get medicationsReportDescription => 'Detailed analytics on medication intake, missed doses and adherence';

  @override
  String get notificationPermissionGranted => 'Notification permission granted';

  @override
  String get notificationPermissionDenied => 'Notification permission denied';

  @override
  String get notificationPermissionPermanentlyDenied => 'Notification permission permanently denied';

  @override
  String get notificationPermissionDescription => 'Required for sending medication and menstrual cycle reminders';

  @override
  String get exactAlarmPermissionGranted => 'Exact alarm permission granted';

  @override
  String get exactAlarmPermissionDenied => 'Exact alarm permission denied';

  @override
  String get exactAlarmPermissionPermanentlyDenied => 'Exact alarm permission permanently denied';

  @override
  String get exactAlarmPermissionDescription => 'Required for precise medication reminder scheduling';

  @override
  String get permissionsRequestTitle => 'Permissions Required';

  @override
  String get permissionsRequestMessage => 'The following permissions are required for the app to work properly:';

  @override
  String get notNow => 'Not now';

  @override
  String get enable => 'Enable';

  @override
  String get openSettings => 'Settings';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuSubtitle => 'Choose the section you need';

  @override
  String get menu0 => 'Информация за день';

  @override
  String get menu1 => 'Health';

  @override
  String get menu2 => 'Ежедневник';

  @override
  String get menu3 => 'Lists';

  @override
  String get menu4 => 'Habits';

  @override
  String get menu5 => 'Notes';

  @override
  String get menuItem1 => 'Health opened';

  @override
  String get menuItem2 => 'Daily Schedule opened';

  @override
  String get menuItem3 => 'To-Do List opened';

  @override
  String get menuItem4 => 'Habits opened';

  @override
  String get menuItem5 => 'Notes opened';

  @override
  String get calendar => 'Calendar';

  @override
  String get listsTitle => 'Lists';

  @override
  String get addListButton => 'Add List';

  @override
  String get addListTitle => 'Add List';

  @override
  String get listNameLabel => 'List Name';

  @override
  String get listNameRequired => 'Enter list name';

  @override
  String get deleteListConfirmTitle => 'Delete List';

  @override
  String deleteListConfirmMessage(Object name) {
    return 'Are you sure you want to delete the list \"$name\"?';
  }

  @override
  String get addListItemButton => 'Add Item';

  @override
  String listProgressFormat(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get emptyListsMessage => 'Create your first list';

  @override
  String get emptyListItemsMessage => 'No items yet';

  @override
  String get addListItemTitle => 'Add Item';

  @override
  String get listItemTextLabel => 'Item Text';

  @override
  String get listItemTextRequired => 'Enter item text';

  @override
  String get listSaved => 'List saved';

  @override
  String listSaveError(Object message) {
    return 'Error saving list: $message';
  }

  @override
  String get listDeleted => 'List deleted';

  @override
  String listDeleteError(Object message) {
    return 'Error deleting list: $message';
  }

  @override
  String get listItemAdded => 'Item added';

  @override
  String listItemAddError(Object message) {
    return 'Error adding item: $message';
  }

  @override
  String get listItemUpdated => 'Item updated';

  @override
  String listItemUpdateError(Object message) {
    return 'Error updating item: $message';
  }

  @override
  String get listItemDeleted => 'Item deleted';

  @override
  String listItemDeleteError(Object message) {
    return 'Error updating item: $message';
  }

  @override
  String get periodBlockTitle => 'Period';

  @override
  String get delayLabel => 'Delay';

  @override
  String get previousPeriodsTitle => 'Previous periods';

  @override
  String get nextPlannedPeriodsTitle => 'Next planned periods';

  @override
  String get activeLabel => '(active)';

  @override
  String get durationLabel => 'Duration:';

  @override
  String get durationDayOne => 'day';

  @override
  String get durationDayFew => 'days';

  @override
  String get cycleManagementTitle => 'Cycle Management';

  @override
  String get sexBlockTitle => 'Sex';

  @override
  String get hadSexLabel => 'Had sex';

  @override
  String get sexTypeLabel => 'Sex type:';

  @override
  String get safeSexLabel => 'Safe';

  @override
  String get unsafeSexLabel => 'Unsafe';

  @override
  String get orgasmLabel => 'Orgasm:';

  @override
  String get hadOrgasmLabel => 'Had orgasm';

  @override
  String get noOrgasmLabel => 'No orgasm';

  @override
  String get healthBlockTitle => 'Health';

  @override
  String get selectSymptomsLabel => 'Select symptoms:';

  @override
  String get noAvailableSymptoms => 'No available symptoms. Add them in settings.';

  @override
  String get addSymptomButton => 'Add symptom';

  @override
  String get noMedicationRecords => 'No medication records for this day.';

  @override
  String get medicationTimeLabel => 'Medication time:';

  @override
  String get medicationTakenLabel => 'Taken:';

  @override
  String get editListTitle => 'Edit List';

  @override
  String get editListNameLabel => 'List Name';

  @override
  String get listUpdated => 'List updated';

  @override
  String listUpdateError(Object message) {
    return 'Error updating list: $message';
  }

  @override
  String get notificationChannelName => 'Medication Reminders';

  @override
  String get notificationChannelDescription => 'Medication intake notifications';

  @override
  String get notificationTitle => 'Time to take medications!';

  @override
  String get notificationBody => 'Don\'t forget to take:';

  @override
  String get notesTitle => 'Notes';

  @override
  String get addNoteTitle => 'Add Note';

  @override
  String get editNoteTitle => 'Edit Note';

  @override
  String get noteTitleLabel => 'Note Title';

  @override
  String get noteContentLabel => 'Note Content';

  @override
  String get noteDateLabel => 'Note Date';

  @override
  String get noteRequired => 'Enter note title or content';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get noteUpdated => 'Note updated';

  @override
  String get noteDeleted => 'Note deleted';

  @override
  String noteSaveError(Object message) {
    return 'Error saving note: $message';
  }

  @override
  String noteUpdateError(Object message) {
    return 'Error updating note: $message';
  }

  @override
  String noteDeleteError(Object message) {
    return 'Error deleting note: $message';
  }

  @override
  String get deleteNoteConfirmTitle => 'Delete Note';

  @override
  String deleteNoteConfirmMessage(Object title) {
    return 'Are you sure you want to delete the note \"$title\"?';
  }

  @override
  String get emptyNotesMessage => 'Create your first note';

  @override
  String get settingsTabHabits => 'Habits';

  @override
  String get settingsTabCache => 'Cache & Optimization';

  @override
  String get habitsTitle => 'Habits';

  @override
  String get noHabits => 'No habits';

  @override
  String get executionHabitsTitle => 'Execution Habits';

  @override
  String get measurableHabitsTitle => 'Measurable Habits';

  @override
  String get selectHabitTypeTitle => 'Select Habit Type';

  @override
  String get habitTypeExecution => 'Execution';

  @override
  String get habitTypeMeasurable => 'Measurable Result';

  @override
  String get habitTypeExecutionDescription => 'Simple habit completion tracking';

  @override
  String get habitTypeMeasurableDescription => 'Habit with measurable result';

  @override
  String get addHabitExecutionTitle => 'Add Execution Habit';

  @override
  String get editHabitExecutionTitle => 'Edit Execution Habit';

  @override
  String get addHabitMeasurableTitle => 'Add Measurable Habit';

  @override
  String get editHabitMeasurableTitle => 'Edit Measurable Habit';

  @override
  String get habitNameLabel => 'Habit Name';

  @override
  String get habitFrequencyLabel => 'Frequency';

  @override
  String get habitStartDateLabel => 'Start Date';

  @override
  String get habitEndDateLabel => 'End Date';

  @override
  String get habitReminderTimeLabel => 'Reminder Time';

  @override
  String get habitGoalLabel => 'Goal';

  @override
  String get habitUnitLabel => 'Unit';

  @override
  String get pickStartDate => 'Pick start date';

  @override
  String get pickEndDate => 'Pick end date';

  @override
  String get fillAllRequiredFields => 'Fill all required fields';

  @override
  String get invalidTimeFormat => 'Invalid time format (use HH:MM)';

  @override
  String get invalidGoalValue => 'Enter a valid goal value';

  @override
  String get habitExecutionAdded => 'Execution habit added';

  @override
  String get habitExecutionUpdated => 'Execution habit updated';

  @override
  String get habitMeasurableAdded => 'Measurable habit added';

  @override
  String get habitMeasurableUpdated => 'Measurable habit updated';

  @override
  String habitSaveError(Object message) {
    return 'Error saving habit: $message';
  }

  @override
  String get deleteHabitTitle => 'Delete Habit';

  @override
  String deleteHabitConfirmMessage(Object name) {
    return 'Are you sure you want to delete habit \"$name\"?';
  }

  @override
  String get habitDeleted => 'Habit deleted';

  @override
  String habitDeleteError(Object message) {
    return 'Error deleting habit: $message';
  }

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get speechRecognitionError => 'Speech recognition error';

  @override
  String speechRecognitionErrorWithMessage(Object error) {
    return 'Speech recognition error: $error';
  }

  @override
  String get speechNoteCreated => 'Voice note created';

  @override
  String get noMicrophonePermission => 'No microphone permission';

  @override
  String get listeningIndicator => 'Listening...';

  @override
  String get errorDialogTitle => 'Error';

  @override
  String get plannerTitle => 'Daily Planner';

  @override
  String get dayStartTime => 'Day Start Time';

  @override
  String get dayEndTime => 'Day End Time';

  @override
  String get addTask => 'Add Task';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get taskDescription => 'Description (optional)';

  @override
  String get taskStartTime => 'Start Time';

  @override
  String get taskEndTime => 'End Time';

  @override
  String get selectDate => 'Select Date';

  @override
  String get save => 'Save';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get deleteTaskConfirm => 'Are you sure you want to delete this task?';

  @override
  String get dayTimeRangeError => 'The difference between day end and day start must be at least 1 hour';
}
