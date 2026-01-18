import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay in Rhythm'**
  String get appTitle;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh data'**
  String get refreshTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @exitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Exit app'**
  String get exitTooltip;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(Object message);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @calendarNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next Period:'**
  String get calendarNextPeriod;

  /// No description provided for @calendarInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String calendarInDays(int days);

  /// No description provided for @calendarLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Legend:'**
  String get calendarLegendTitle;

  /// No description provided for @calendarLegendPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get calendarLegendPlanned;

  /// No description provided for @calendarLegendActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get calendarLegendActual;

  /// No description provided for @calendarLegendToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarLegendToday;

  /// No description provided for @calendarLegendOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get calendarLegendOvulation;

  /// No description provided for @calendarLegendFertile.
  ///
  /// In en, this message translates to:
  /// **'Fertile days'**
  String get calendarLegendFertile;

  /// No description provided for @calendarLegendOverdue.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get calendarLegendOverdue;

  /// No description provided for @idealTimeForConception.
  ///
  /// In en, this message translates to:
  /// **'Ideal time for conception'**
  String get idealTimeForConception;

  /// No description provided for @favorableTimeForConception.
  ///
  /// In en, this message translates to:
  /// **'Favorable time for conception'**
  String get favorableTimeForConception;

  /// No description provided for @dayDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Day Details'**
  String get dayDetailsTitle;

  /// No description provided for @periodManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Period Management'**
  String get periodManagementTitle;

  /// No description provided for @startNewPeriodButton.
  ///
  /// In en, this message translates to:
  /// **'Start New Period'**
  String get startNewPeriodButton;

  /// No description provided for @startNewPeriodHint.
  ///
  /// In en, this message translates to:
  /// **'Mark this day as the start of your period'**
  String get startNewPeriodHint;

  /// No description provided for @activePeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Active period: {start} - Present'**
  String activePeriodLabel(Object start);

  /// No description provided for @endPeriodButton.
  ///
  /// In en, this message translates to:
  /// **'End Period Here'**
  String get endPeriodButton;

  /// No description provided for @endPeriodHint.
  ///
  /// In en, this message translates to:
  /// **'Mark this day as the end of your period'**
  String get endPeriodHint;

  /// No description provided for @cancelPeriodButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Period'**
  String get cancelPeriodButton;

  /// No description provided for @cancelPeriodHint.
  ///
  /// In en, this message translates to:
  /// **'Remove this period record'**
  String get cancelPeriodHint;

  /// No description provided for @dayWithinActive.
  ///
  /// In en, this message translates to:
  /// **'This day is within an active period'**
  String get dayWithinActive;

  /// No description provided for @dayWithinActiveHint.
  ///
  /// In en, this message translates to:
  /// **'To end the period, mark the last day of bleeding'**
  String get dayWithinActiveHint;

  /// No description provided for @lastPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Last period: {start} - {end}'**
  String lastPeriodLabel(Object start, Object end);

  /// No description provided for @lastPeriodHint.
  ///
  /// In en, this message translates to:
  /// **'You can start a new period after the end date'**
  String get lastPeriodHint;

  /// No description provided for @removeEndDateButton.
  ///
  /// In en, this message translates to:
  /// **'Remove End Date'**
  String get removeEndDateButton;

  /// No description provided for @deletePeriodButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Period'**
  String get deletePeriodButton;

  /// No description provided for @deletePeriodHint.
  ///
  /// In en, this message translates to:
  /// **'First remove the end date, then you can delete the entire record if needed'**
  String get deletePeriodHint;

  /// No description provided for @symptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptomsTitle;

  /// No description provided for @addSymptomHint.
  ///
  /// In en, this message translates to:
  /// **'Add symptom'**
  String get addSymptomHint;

  /// No description provided for @currentSymptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Current symptoms:'**
  String get currentSymptomsTitle;

  /// No description provided for @symptomAlreadyAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Symptom already added'**
  String get symptomAlreadyAddedMessage;

  /// No description provided for @noSymptoms.
  ///
  /// In en, this message translates to:
  /// **'No symptoms added'**
  String get noSymptoms;

  /// No description provided for @debugInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug Info:'**
  String get debugInfoTitle;

  /// No description provided for @debugCanMarkStart.
  ///
  /// In en, this message translates to:
  /// **'Can mark start: {value}'**
  String debugCanMarkStart(Object value);

  /// No description provided for @debugCanMarkEnd.
  ///
  /// In en, this message translates to:
  /// **'Can mark end: {value}'**
  String debugCanMarkEnd(Object value);

  /// No description provided for @debugIsInActivePeriod.
  ///
  /// In en, this message translates to:
  /// **'Is in active period: {value}'**
  String debugIsInActivePeriod(Object value);

  /// No description provided for @debugActivePeriod.
  ///
  /// In en, this message translates to:
  /// **'Active period: {value}'**
  String debugActivePeriod(Object value);

  /// No description provided for @debugLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'Last period: {value}'**
  String debugLastPeriod(Object value);

  /// No description provided for @debugSymptomsCount.
  ///
  /// In en, this message translates to:
  /// **'Symptoms count: {count}'**
  String debugSymptomsCount(int count);

  /// No description provided for @symptomsSaved.
  ///
  /// In en, this message translates to:
  /// **'Symptoms saved successfully'**
  String get symptomsSaved;

  /// No description provided for @symptomsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving symptoms: {message}'**
  String symptomsSaveError(Object message);

  /// No description provided for @startPeriodSuccess.
  ///
  /// In en, this message translates to:
  /// **'Period started successfully'**
  String get startPeriodSuccess;

  /// No description provided for @startPeriodError.
  ///
  /// In en, this message translates to:
  /// **'Error starting period: {message}'**
  String startPeriodError(Object message);

  /// No description provided for @endPeriodSuccess.
  ///
  /// In en, this message translates to:
  /// **'Period ended successfully'**
  String get endPeriodSuccess;

  /// No description provided for @endPeriodError.
  ///
  /// In en, this message translates to:
  /// **'Error ending period: {message}'**
  String endPeriodError(Object message);

  /// No description provided for @cancelPeriodSuccess.
  ///
  /// In en, this message translates to:
  /// **'Period cancelled successfully'**
  String get cancelPeriodSuccess;

  /// No description provided for @cancelPeriodError.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling period: {message}'**
  String cancelPeriodError(Object message);

  /// No description provided for @removePeriodEndSuccess.
  ///
  /// In en, this message translates to:
  /// **'Period end removed'**
  String get removePeriodEndSuccess;

  /// No description provided for @removePeriodEndError.
  ///
  /// In en, this message translates to:
  /// **'Error removing period end: {message}'**
  String removePeriodEndError(Object message);

  /// No description provided for @deletePeriodSuccess.
  ///
  /// In en, this message translates to:
  /// **'Period deleted'**
  String get deletePeriodSuccess;

  /// No description provided for @deletePeriodError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting period: {message}'**
  String deletePeriodError(Object message);

  /// No description provided for @endDateBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be earlier than start date'**
  String get endDateBeforeStart;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get settingsSaveError;

  /// No description provided for @settingsFormCycleLength.
  ///
  /// In en, this message translates to:
  /// **'Cycle Length (days)'**
  String get settingsFormCycleLength;

  /// No description provided for @settingsFormPeriodLength.
  ///
  /// In en, this message translates to:
  /// **'Period Length (days)'**
  String get settingsFormPeriodLength;

  /// No description provided for @settingsFormPlanningMonths.
  ///
  /// In en, this message translates to:
  /// **'Planning Period (months)'**
  String get settingsFormPlanningMonths;

  /// No description provided for @settingsFormSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get settingsFormSaveButton;

  /// No description provided for @settingsFormValueMissing.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get settingsFormValueMissing;

  /// No description provided for @settingsFormInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get settingsFormInvalidNumber;

  /// No description provided for @settingsFormRangeError.
  ///
  /// In en, this message translates to:
  /// **'Value must be between {min} and {max}'**
  String settingsFormRangeError(int min, int max);

  /// No description provided for @settingsFormLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsFormLanguageLabel;

  /// No description provided for @settingsFormLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsFormLanguageEnglish;

  /// No description provided for @settingsFormLanguageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get settingsFormLanguageRussian;

  /// No description provided for @settingsFormFirstDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar first day'**
  String get settingsFormFirstDayLabel;

  /// No description provided for @settingsFormFirstDayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get settingsFormFirstDayMonday;

  /// No description provided for @settingsFormFirstDaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get settingsFormFirstDaySunday;

  /// No description provided for @settingsTabGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsTabGeneral;

  /// No description provided for @settingsTabMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get settingsTabMedications;

  /// No description provided for @settingsTabSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get settingsTabSymptoms;

  /// No description provided for @symptomHeadache.
  ///
  /// In en, this message translates to:
  /// **'Headache'**
  String get symptomHeadache;

  /// No description provided for @symptomFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get symptomFatigue;

  /// No description provided for @symptomBloating.
  ///
  /// In en, this message translates to:
  /// **'Bloating'**
  String get symptomBloating;

  /// No description provided for @symptomIrritability.
  ///
  /// In en, this message translates to:
  /// **'Irritability'**
  String get symptomIrritability;

  /// No description provided for @symptomAbdominalPain.
  ///
  /// In en, this message translates to:
  /// **'Abdominal pain'**
  String get symptomAbdominalPain;

  /// No description provided for @symptomAcne.
  ///
  /// In en, this message translates to:
  /// **'Acne'**
  String get symptomAcne;

  /// No description provided for @symptomSweetCravings.
  ///
  /// In en, this message translates to:
  /// **'Sweet cravings'**
  String get symptomSweetCravings;

  /// No description provided for @symptomBreastPain.
  ///
  /// In en, this message translates to:
  /// **'Breast pain'**
  String get symptomBreastPain;

  /// No description provided for @symptomCramps.
  ///
  /// In en, this message translates to:
  /// **'Cramps'**
  String get symptomCramps;

  /// No description provided for @symptomNausea.
  ///
  /// In en, this message translates to:
  /// **'Nausea'**
  String get symptomNausea;

  /// No description provided for @symptomInsomnia.
  ///
  /// In en, this message translates to:
  /// **'Insomnia'**
  String get symptomInsomnia;

  /// No description provided for @addSymptomTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Symptom'**
  String get addSymptomTitle;

  /// No description provided for @editSymptomTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Symptom'**
  String get editSymptomTitle;

  /// No description provided for @symptomNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptom Name'**
  String get symptomNameLabel;

  /// No description provided for @symptomNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter symptom name'**
  String get symptomNameRequired;

  /// No description provided for @symptomAdded.
  ///
  /// In en, this message translates to:
  /// **'Symptom added'**
  String get symptomAdded;

  /// No description provided for @symptomAddError.
  ///
  /// In en, this message translates to:
  /// **'Error adding symptom'**
  String get symptomAddError;

  /// No description provided for @symptomUpdated.
  ///
  /// In en, this message translates to:
  /// **'Symptom updated'**
  String get symptomUpdated;

  /// No description provided for @symptomUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating symptom'**
  String get symptomUpdateError;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Fill all fields'**
  String get fillAllFields;

  /// No description provided for @deleteSymptomTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Symptom'**
  String get deleteSymptomTitle;

  /// No description provided for @deleteSymptomMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete symptom \"{name}\"?'**
  String deleteSymptomMessage(Object name);

  /// No description provided for @symptomDeleted.
  ///
  /// In en, this message translates to:
  /// **'Symptom deleted'**
  String get symptomDeleted;

  /// No description provided for @symptomDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting symptom'**
  String get symptomDeleteError;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @addMedicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedicationTitle;

  /// No description provided for @editMedicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedicationTitle;

  /// No description provided for @medicationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationNameLabel;

  /// No description provided for @medicationStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get medicationStartDateLabel;

  /// No description provided for @medicationPickStartDate.
  ///
  /// In en, this message translates to:
  /// **'Pick start date'**
  String get medicationPickStartDate;

  /// No description provided for @medicationEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get medicationEndDateLabel;

  /// No description provided for @medicationPickEndDate.
  ///
  /// In en, this message translates to:
  /// **'Pick end date (optional)'**
  String get medicationPickEndDate;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @medicationNameMissingError.
  ///
  /// In en, this message translates to:
  /// **'Enter medication name and start date'**
  String get medicationNameMissingError;

  /// No description provided for @medicationSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving medication: {message}'**
  String medicationSaveError(Object message);

  /// No description provided for @noMedications.
  ///
  /// In en, this message translates to:
  /// **'No medications added'**
  String get noMedications;

  /// No description provided for @medicationEndDateNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get medicationEndDateNotSet;

  /// No description provided for @medicationTimes.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get medicationTimes;

  /// No description provided for @medicationDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get medicationDeleteConfirmTitle;

  /// No description provided for @medicationDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String medicationDeleteConfirmMessage(Object name);

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @medicationDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication \"{name}\" deleted'**
  String medicationDeleteSuccess(Object name);

  /// No description provided for @medicationDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting medication: {message}'**
  String medicationDeleteError(Object message);

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @dayReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dayReportTitle;

  /// No description provided for @medicationsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications Report'**
  String get medicationsReportTitle;

  /// No description provided for @medicationsReportDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed analytics on medication intake, missed doses and adherence'**
  String get medicationsReportDescription;

  /// No description provided for @notificationPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Notification permission granted'**
  String get notificationPermissionGranted;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get notificationPermissionDenied;

  /// No description provided for @notificationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission permanently denied'**
  String get notificationPermissionPermanentlyDenied;

  /// No description provided for @notificationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Required for sending medication and menstrual cycle reminders'**
  String get notificationPermissionDescription;

  /// No description provided for @exactAlarmPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission granted'**
  String get exactAlarmPermissionGranted;

  /// No description provided for @exactAlarmPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission denied'**
  String get exactAlarmPermissionDenied;

  /// No description provided for @exactAlarmPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission permanently denied'**
  String get exactAlarmPermissionPermanentlyDenied;

  /// No description provided for @exactAlarmPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Required for precise medication reminder scheduling'**
  String get exactAlarmPermissionDescription;

  /// No description provided for @permissionsRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsRequestTitle;

  /// No description provided for @permissionsRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'The following permissions are required for the app to work properly:'**
  String get permissionsRequestMessage;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @menuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the section you need'**
  String get menuSubtitle;

  /// No description provided for @menu0.
  ///
  /// In en, this message translates to:
  /// **'Информация за день'**
  String get menu0;

  /// No description provided for @menu1.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get menu1;

  /// No description provided for @menu2.
  ///
  /// In en, this message translates to:
  /// **'Ежедневник'**
  String get menu2;

  /// No description provided for @menu3.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get menu3;

  /// No description provided for @menu4.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get menu4;

  /// No description provided for @menu5.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get menu5;

  /// No description provided for @menuItem1.
  ///
  /// In en, this message translates to:
  /// **'Health opened'**
  String get menuItem1;

  /// No description provided for @menuItem2.
  ///
  /// In en, this message translates to:
  /// **'Daily Schedule opened'**
  String get menuItem2;

  /// No description provided for @menuItem3.
  ///
  /// In en, this message translates to:
  /// **'To-Do List opened'**
  String get menuItem3;

  /// No description provided for @menuItem4.
  ///
  /// In en, this message translates to:
  /// **'Habits opened'**
  String get menuItem4;

  /// No description provided for @menuItem5.
  ///
  /// In en, this message translates to:
  /// **'Notes opened'**
  String get menuItem5;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @listsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get listsTitle;

  /// No description provided for @addListButton.
  ///
  /// In en, this message translates to:
  /// **'Add List'**
  String get addListButton;

  /// No description provided for @addListTitle.
  ///
  /// In en, this message translates to:
  /// **'Add List'**
  String get addListTitle;

  /// No description provided for @listNameLabel.
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get listNameLabel;

  /// No description provided for @listNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter list name'**
  String get listNameRequired;

  /// No description provided for @deleteListConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete List'**
  String get deleteListConfirmTitle;

  /// No description provided for @deleteListConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the list \"{name}\"?'**
  String deleteListConfirmMessage(Object name);

  /// No description provided for @addListItemButton.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addListItemButton;

  /// No description provided for @listProgressFormat.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total}'**
  String listProgressFormat(int completed, int total);

  /// No description provided for @emptyListsMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first list'**
  String get emptyListsMessage;

  /// No description provided for @emptyListItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get emptyListItemsMessage;

  /// No description provided for @addListItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addListItemTitle;

  /// No description provided for @listItemTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Text'**
  String get listItemTextLabel;

  /// No description provided for @listItemTextRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter item text'**
  String get listItemTextRequired;

  /// No description provided for @listSaved.
  ///
  /// In en, this message translates to:
  /// **'List saved'**
  String get listSaved;

  /// No description provided for @listSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving list: {message}'**
  String listSaveError(Object message);

  /// No description provided for @listDeleted.
  ///
  /// In en, this message translates to:
  /// **'List deleted'**
  String get listDeleted;

  /// No description provided for @listDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting list: {message}'**
  String listDeleteError(Object message);

  /// No description provided for @listItemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added'**
  String get listItemAdded;

  /// No description provided for @listItemAddError.
  ///
  /// In en, this message translates to:
  /// **'Error adding item: {message}'**
  String listItemAddError(Object message);

  /// No description provided for @listItemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated'**
  String get listItemUpdated;

  /// No description provided for @listItemUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating item: {message}'**
  String listItemUpdateError(Object message);

  /// No description provided for @listItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get listItemDeleted;

  /// No description provided for @listItemDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error updating item: {message}'**
  String listItemDeleteError(Object message);

  /// No description provided for @periodBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get periodBlockTitle;

  /// No description provided for @delayLabel.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get delayLabel;

  /// No description provided for @previousPeriodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Previous periods'**
  String get previousPeriodsTitle;

  /// No description provided for @nextPlannedPeriodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Next planned periods'**
  String get nextPlannedPeriodsTitle;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'(active)'**
  String get activeLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration:'**
  String get durationLabel;

  /// No description provided for @durationDayOne.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get durationDayOne;

  /// No description provided for @durationDayFew.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get durationDayFew;

  /// No description provided for @cycleManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle Management'**
  String get cycleManagementTitle;

  /// No description provided for @sexBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sexBlockTitle;

  /// No description provided for @hadSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Had sex'**
  String get hadSexLabel;

  /// No description provided for @sexTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Sex type:'**
  String get sexTypeLabel;

  /// No description provided for @safeSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get safeSexLabel;

  /// No description provided for @unsafeSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Unsafe'**
  String get unsafeSexLabel;

  /// No description provided for @orgasmLabel.
  ///
  /// In en, this message translates to:
  /// **'Orgasm:'**
  String get orgasmLabel;

  /// No description provided for @hadOrgasmLabel.
  ///
  /// In en, this message translates to:
  /// **'Had orgasm'**
  String get hadOrgasmLabel;

  /// No description provided for @noOrgasmLabel.
  ///
  /// In en, this message translates to:
  /// **'No orgasm'**
  String get noOrgasmLabel;

  /// No description provided for @healthBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthBlockTitle;

  /// No description provided for @selectSymptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Select symptoms:'**
  String get selectSymptomsLabel;

  /// No description provided for @noAvailableSymptoms.
  ///
  /// In en, this message translates to:
  /// **'No available symptoms. Add them in settings.'**
  String get noAvailableSymptoms;

  /// No description provided for @addSymptomButton.
  ///
  /// In en, this message translates to:
  /// **'Add symptom'**
  String get addSymptomButton;

  /// No description provided for @noMedicationRecords.
  ///
  /// In en, this message translates to:
  /// **'No medication records for this day.'**
  String get noMedicationRecords;

  /// No description provided for @medicationTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication time:'**
  String get medicationTimeLabel;

  /// No description provided for @medicationTakenLabel.
  ///
  /// In en, this message translates to:
  /// **'Taken:'**
  String get medicationTakenLabel;

  /// No description provided for @editListTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit List'**
  String get editListTitle;

  /// No description provided for @editListNameLabel.
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get editListNameLabel;

  /// No description provided for @listUpdated.
  ///
  /// In en, this message translates to:
  /// **'List updated'**
  String get listUpdated;

  /// No description provided for @listUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating list: {message}'**
  String listUpdateError(Object message);

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Medication intake notifications'**
  String get notificationChannelDescription;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to take medications!'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to take:'**
  String get notificationBody;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @addNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNoteTitle;

  /// No description provided for @editNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNoteTitle;

  /// No description provided for @noteTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Note Title'**
  String get noteTitleLabel;

  /// No description provided for @noteContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Note Content'**
  String get noteContentLabel;

  /// No description provided for @noteDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Note Date'**
  String get noteDateLabel;

  /// No description provided for @noteRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter note title or content'**
  String get noteRequired;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @noteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Note updated'**
  String get noteUpdated;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// No description provided for @noteSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving note: {message}'**
  String noteSaveError(Object message);

  /// No description provided for @noteUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating note: {message}'**
  String noteUpdateError(Object message);

  /// No description provided for @noteDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting note: {message}'**
  String noteDeleteError(Object message);

  /// No description provided for @deleteNoteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNoteConfirmTitle;

  /// No description provided for @deleteNoteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the note \"{title}\"?'**
  String deleteNoteConfirmMessage(Object title);

  /// No description provided for @emptyNotesMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first note'**
  String get emptyNotesMessage;

  /// No description provided for @settingsTabHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get settingsTabHabits;

  /// No description provided for @settingsTabCache.
  ///
  /// In en, this message translates to:
  /// **'Cache & Optimization'**
  String get settingsTabCache;

  /// No description provided for @habitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsTitle;

  /// No description provided for @noHabits.
  ///
  /// In en, this message translates to:
  /// **'No habits'**
  String get noHabits;

  /// No description provided for @executionHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Execution Habits'**
  String get executionHabitsTitle;

  /// No description provided for @measurableHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Measurable Habits'**
  String get measurableHabitsTitle;

  /// No description provided for @selectHabitTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Habit Type'**
  String get selectHabitTypeTitle;

  /// No description provided for @habitTypeExecution.
  ///
  /// In en, this message translates to:
  /// **'Execution'**
  String get habitTypeExecution;

  /// No description provided for @habitTypeMeasurable.
  ///
  /// In en, this message translates to:
  /// **'Measurable Result'**
  String get habitTypeMeasurable;

  /// No description provided for @habitTypeExecutionDescription.
  ///
  /// In en, this message translates to:
  /// **'Simple habit completion tracking'**
  String get habitTypeExecutionDescription;

  /// No description provided for @habitTypeMeasurableDescription.
  ///
  /// In en, this message translates to:
  /// **'Habit with measurable result'**
  String get habitTypeMeasurableDescription;

  /// No description provided for @addHabitExecutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Execution Habit'**
  String get addHabitExecutionTitle;

  /// No description provided for @editHabitExecutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Execution Habit'**
  String get editHabitExecutionTitle;

  /// No description provided for @addHabitMeasurableTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Measurable Habit'**
  String get addHabitMeasurableTitle;

  /// No description provided for @editHabitMeasurableTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Measurable Habit'**
  String get editHabitMeasurableTitle;

  /// No description provided for @habitNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Habit Name'**
  String get habitNameLabel;

  /// No description provided for @habitFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get habitFrequencyLabel;

  /// No description provided for @habitStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get habitStartDateLabel;

  /// No description provided for @habitEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get habitEndDateLabel;

  /// No description provided for @habitReminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get habitReminderTimeLabel;

  /// No description provided for @habitGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get habitGoalLabel;

  /// No description provided for @habitUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get habitUnitLabel;

  /// No description provided for @pickStartDate.
  ///
  /// In en, this message translates to:
  /// **'Pick start date'**
  String get pickStartDate;

  /// No description provided for @pickEndDate.
  ///
  /// In en, this message translates to:
  /// **'Pick end date'**
  String get pickEndDate;

  /// No description provided for @fillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Fill all required fields'**
  String get fillAllRequiredFields;

  /// No description provided for @invalidTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid time format (use HH:MM)'**
  String get invalidTimeFormat;

  /// No description provided for @invalidGoalValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid goal value'**
  String get invalidGoalValue;

  /// No description provided for @habitExecutionAdded.
  ///
  /// In en, this message translates to:
  /// **'Execution habit added'**
  String get habitExecutionAdded;

  /// No description provided for @habitExecutionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Execution habit updated'**
  String get habitExecutionUpdated;

  /// No description provided for @habitMeasurableAdded.
  ///
  /// In en, this message translates to:
  /// **'Measurable habit added'**
  String get habitMeasurableAdded;

  /// No description provided for @habitMeasurableUpdated.
  ///
  /// In en, this message translates to:
  /// **'Measurable habit updated'**
  String get habitMeasurableUpdated;

  /// No description provided for @habitSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving habit: {message}'**
  String habitSaveError(Object message);

  /// No description provided for @deleteHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Habit'**
  String get deleteHabitTitle;

  /// No description provided for @deleteHabitConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete habit \"{name}\"?'**
  String deleteHabitConfirmMessage(Object name);

  /// No description provided for @habitDeleted.
  ///
  /// In en, this message translates to:
  /// **'Habit deleted'**
  String get habitDeleted;

  /// No description provided for @habitDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting habit: {message}'**
  String habitDeleteError(Object message);

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @speechRecognitionError.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition error'**
  String get speechRecognitionError;

  /// No description provided for @speechRecognitionErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition error: {error}'**
  String speechRecognitionErrorWithMessage(Object error);

  /// No description provided for @speechNoteCreated.
  ///
  /// In en, this message translates to:
  /// **'Voice note created'**
  String get speechNoteCreated;

  /// No description provided for @noMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'No microphone permission'**
  String get noMicrophonePermission;

  /// No description provided for @listeningIndicator.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listeningIndicator;

  /// No description provided for @errorDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorDialogTitle;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Planner'**
  String get plannerTitle;

  /// No description provided for @dayStartTime.
  ///
  /// In en, this message translates to:
  /// **'Day Start Time'**
  String get dayStartTime;

  /// No description provided for @dayEndTime.
  ///
  /// In en, this message translates to:
  /// **'Day End Time'**
  String get dayEndTime;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// No description provided for @taskDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get taskDescription;

  /// No description provided for @taskStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get taskStartTime;

  /// No description provided for @taskEndTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get taskEndTime;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get deleteTaskConfirm;

  /// No description provided for @dayTimeRangeError.
  ///
  /// In en, this message translates to:
  /// **'The difference between day end and day start must be at least 1 hour'**
  String get dayTimeRangeError;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
