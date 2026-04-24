class FlutterLocalNotificationsPlugin {
  Future<void> initialize(dynamic settings) async {}
  Future<void> show(int id, String? title, String? body, dynamic notificationDetails) async {}
}
class AndroidNotificationDetails {
  final String channelId;
  final String channelName;
  final String channelDescription;
  const AndroidNotificationDetails(this.channelId, this.channelName, {this.channelDescription = ''});
}
class DarwinNotificationDetails {}
class NotificationDetails {
  final AndroidNotificationDetails? android;
  final DarwinNotificationDetails? iOS;
  const NotificationDetails({this.android, this.iOS});
}
class AndroidInitializationSettings {
  final String icon;
  const AndroidInitializationSettings(this.icon);
}
class DarwinInitializationSettings {
  const DarwinInitializationSettings();
}
class InitializationSettings {
  final AndroidInitializationSettings? android;
  final DarwinInitializationSettings? iOS;
  const InitializationSettings({this.android, this.iOS});
}
