import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:period_tracker/l10n/app_localizations.dart';

class PermissionsService {
  static const Permission _notificationPermission = Permission.notification;
  static const Permission _exactAlarmPermission = Permission.scheduleExactAlarm;

  /// Проверяет статус разрешения на уведомления
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await _notificationPermission.status;
    return status.isGranted;
  }

  /// Проверяет статус разрешения на точные будильники
  static Future<bool> isExactAlarmPermissionGranted() async {
    final status = await _exactAlarmPermission.status;
    return status.isGranted;
  }

  /// Проверяет все необходимые разрешения
  static Future<Map<Permission, bool>> checkAllPermissions() async {
    final notificationStatus = await _notificationPermission.status;
    final exactAlarmStatus = await _exactAlarmPermission.status;
    
    return {
      _notificationPermission: notificationStatus.isGranted,
      _exactAlarmPermission: exactAlarmStatus.isGranted,
    };
  }

  /// Запрашивает разрешение на уведомления
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final status = await _notificationPermission.request();

    if (status.isGranted) {
      _showSuccessDialog(context, l10n.notificationPermissionGranted);
      return true;
    } else if (status.isDenied) {
      _showDeniedDialog(context, l10n.notificationPermissionDenied, l10n.notificationPermissionDescription);
      return false;
    } else if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context, l10n.notificationPermissionPermanentlyDenied, l10n.notificationPermissionDescription);
      return false;
    }
    
    return false;
  }

  /// Запрашивает разрешение на точные будильники
  static Future<bool> requestExactAlarmPermission(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final status = await _exactAlarmPermission.request();

    if (status.isGranted) {
      _showSuccessDialog(context, l10n.exactAlarmPermissionGranted);
      return true;
    } else if (status.isDenied) {
      _showDeniedDialog(context, l10n.exactAlarmPermissionDenied, l10n.exactAlarmPermissionDescription);
      return false;
    } else if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context, l10n.exactAlarmPermissionPermanentlyDenied, l10n.exactAlarmPermissionDescription);
      return false;
    }
    
    return false;
  }

  /// Запрашивает все необходимые разрешения
  static Future<void> requestAllPermissions(BuildContext context) async {
    // Запрашиваем разрешения последовательно
    final notificationGranted = await requestNotificationPermission(context);
    if (notificationGranted) {
      // Если разрешение на уведомления получено, запрашиваем разрешение на точные будильники
      await requestExactAlarmPermission(context);
    }
  }

  /// Показывает диалог успешного получения разрешения
  static void _showSuccessDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Показывает диалог отклонения разрешения
  static void _showDeniedDialog(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  /// Показывает диалог постоянного отклонения разрешения
  static void _showPermanentlyDeniedDialog(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // Открываем настройки приложения
              },
              child: Text(l10n.openSettings),
            ),
          ],
        );
      },
    );
  }

  /// Проверяет и предлагает включить разрешения при необходимости
  static Future<void> checkAndRequestPermissions(BuildContext context) async {
    final permissions = await checkAllPermissions();
    final missingPermissions = <Permission>[];

    // Проверяем, какие разрешения отсутствуют
    if (!permissions[_notificationPermission]!) {
      missingPermissions.add(_notificationPermission);
    }
    
    if (!permissions[_exactAlarmPermission]!) {
      missingPermissions.add(_exactAlarmPermission);
    }

    // Если есть отсутствующие разрешения, предлагаем их включить
    if (missingPermissions.isNotEmpty) {
      _showPermissionsRequestDialog(context, missingPermissions);
    }
  }

  /// Показывает диалог с предложением включить разрешения
  static void _showPermissionsRequestDialog(BuildContext context, List<Permission> permissions) {
    final l10n = AppLocalizations.of(context)!;
    
    String message = l10n.permissionsRequestMessage;
    if (permissions.contains(_notificationPermission)) {
      message += '\n\n• ${l10n.notificationPermissionDescription}';
    }
    if (permissions.contains(_exactAlarmPermission)) {
      message += '\n• ${l10n.exactAlarmPermissionDescription}';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.permissionsRequestTitle),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.notNow),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                requestAllPermissions(context);
              },
              child: Text(l10n.enable),
            ),
          ],
        );
      },
    );
  }
}