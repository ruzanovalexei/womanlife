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
  String get menuAnalytics => 'Health';

  @override
  String get menuMedications => 'Daily Schedule';

  @override
  String get menuInsights => 'To-Do List';

  @override
  String get menuReminders => 'Habits';

  @override
  String get menuHelp => 'Notes';

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
}
