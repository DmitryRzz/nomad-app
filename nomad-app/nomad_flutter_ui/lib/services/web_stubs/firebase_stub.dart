class FirebaseApp {
  static FirebaseApp? _instance;
  static Future<FirebaseApp> initializeApp() async {
    _instance ??= FirebaseApp();
    return _instance!;
  }
}
class FirebaseMessaging {
  static FirebaseMessaging get instance => FirebaseMessaging();
  Future<String?> getToken() async => null;
  Stream<RemoteMessage> get onMessage => Stream.empty();
  Stream<RemoteMessage> get onMessageOpenedApp => Stream.empty();
}
class RemoteMessage {
  final Map<String, dynamic> data = {};
  final RemoteNotification? notification;
  RemoteMessage({this.notification});
}
class RemoteNotification {
  final String? title;
  final String? body;
  RemoteNotification({this.title, this.body});
}
