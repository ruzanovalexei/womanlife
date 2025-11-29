// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Трекер цикла';

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
  String get calendarLegendOverdue => 'Задержка';

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
  String get settingsFormOvulationDay => 'День овуляции (от начала)';

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
  String get medicationNameMissingError => 'Enter medication name and start date';

  @override
  String medicationSaveError(Object message) {
    return 'Error saving medication: $message';
  }

  @override
  String get noMedications => 'Лекарства не добавлены';

  @override
  String get noMedicationsScheduled => 'Нет запланированных лекарств';

  @override
  String get medicationEndDateNotSet => 'Not set';

  @override
  String get medicationTimes => 'Times';

  @override
  String get medicationDeleteConfirmTitle => 'Удалить лекарство';

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
}
