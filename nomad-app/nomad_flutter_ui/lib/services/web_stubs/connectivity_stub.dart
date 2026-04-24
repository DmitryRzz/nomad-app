class ConnectivityResult {
  static const wifi = ConnectivityResult._('wifi');
  static const mobile = ConnectivityResult._('mobile');
  static const none = ConnectivityResult._('none');
  final String _value;
  const ConnectivityResult._(this._value);
}
class Connectivity {
  static Connectivity get instance => Connectivity();
  Future<ConnectivityResult> checkConnectivity() async => ConnectivityResult.wifi;
  Stream<ConnectivityResult> get onConnectivityChanged => Stream.value(ConnectivityResult.wifi);
}
