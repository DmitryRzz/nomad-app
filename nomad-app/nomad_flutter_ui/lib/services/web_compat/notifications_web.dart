// Web-compatible local notifications stub
class FlutterLocalNotificationsPlugin {
  Future<void> initialize(dynamic settings, {Function? onDidReceiveNotificationResponse}) async {}
  Future<void> show(int id, String? title, String? body, dynamic notificationDetails, {String? payload}) async {
    print('[WEB NOTIFICATION] $title: $body');
  }
  Future<bool?> requestPermissions({bool? alert, bool? badge, bool? sound}) async => true;
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async => [];
  Future<void> cancel(int id) async {}
  Future<void> cancelAll() async {}
}

class AndroidInitializationSettings {
  final String icon;
  AndroidInitializationSettings(this.icon);
}

class DarwinInitializationSettings {
  final bool requestAlertPermission;
  final bool requestBadgePermission;
  final bool requestSoundPermission;
  DarwinInitializationSettings({this.requestAlertPermission = true, this.requestBadgePermission = true, this.requestSoundPermission = true});
}

class InitializationSettings {
  final AndroidInitializationSettings? android;
  final DarwinInitializationSettings? iOS;
  InitializationSettings({this.android, this.iOS});
}

class AndroidNotificationDetails {
  final String channelId;
  final String channelName;
  final String? channelDescription;
  final Importance importance;
  final Priority priority;
  AndroidNotificationDetails(this.channelId, this.channelName, {this.channelDescription, this.importance = Importance.defaultImportance, this.priority = Priority.defaultPriority});
}

class DarwinNotificationDetails {
  DarwinNotificationDetails();
}

class NotificationDetails {
  final AndroidNotificationDetails? android;
  final DarwinNotificationDetails? iOS;
  NotificationDetails({this.android, this.iOS});
}

class Importance {
  static const Importance max = Importance._('max');
  static const Importance high = Importance._('high');
  static const Importance defaultImportance = Importance._('default');
  static const Importance low = Importance._('low');
  static const Importance min = Importance._('min');
  static const Importance none = Importance._('none');
  
  final String value;
  const Importance._(this.value);
}

class Priority {
  static const Priority max = Priority._('max');
  static const Priority high = Priority._('high');
  static const Priority defaultPriority = Priority._('default');
  static const Priority low = Priority._('low');
  static const Priority min = Priority._('min');
  
  final String value;
  const Priority._(this.value);
}

class PendingNotificationRequest {
  final int id;
  final String? title;
  final String? body;
  final String? payload;
  PendingNotificationRequest({required this.id, this.title, this.body, this.payload});
}

class NotificationResponse {
  final String? payload;
  final NotificationResponseType notificationResponseType;
  NotificationResponse({this.payload, required this.notificationResponseType});
}

enum NotificationResponseType { selectedNotification, selectedNotificationAction }
