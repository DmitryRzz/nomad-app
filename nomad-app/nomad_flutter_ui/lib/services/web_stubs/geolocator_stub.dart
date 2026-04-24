class Position {
  final double latitude;
  final double longitude;
  final double accuracy;
  const Position({this.latitude = 0, this.longitude = 0, this.accuracy = 0});
}

class LocationAccuracy {
  static const high = LocationAccuracy.high;
}

class LocationPermission {
  static const denied = LocationPermission.denied;
  static const whileInUse = LocationPermission.whileInUse;
  static const always = LocationPermission.always;
}

class Geolocator {
  static Future<Position> getCurrentPosition() async => Position();
  static Future<bool> isLocationServiceEnabled() async => false;
  static Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;
}

Future<Position> getCurrentPosition() async => Position();
Future<bool> isLocationServiceEnabled() async => false;
