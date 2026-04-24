// Web-compatible geolocator stub
class Position {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double heading;
  final double speed;
  final double speedAccuracy;
  final DateTime? timestamp;
  
  Position({this.latitude = 0, this.longitude = 0, this.accuracy = 0, this.altitude = 0, this.heading = 0, this.speed = 0, this.speedAccuracy = 0, this.timestamp});
  
  factory Position.demo() => Position(
    latitude: 48.8566,
    longitude: 2.3522,
    accuracy: 10,
    timestamp: DateTime.now(),
  );
}

class LocationAccuracy {
  final String _value;
  const LocationAccuracy._(this._value);
  static const high = LocationAccuracy._('high');
}

class LocationPermission {
  final String _value;
  const LocationPermission._(this._value);
  static const denied = LocationPermission._('denied');
  static const deniedForever = LocationPermission._('deniedForever');
  static const whileInUse = LocationPermission._('whileInUse');
  static const always = LocationPermission._('always');
  static const unableToDetermine = LocationPermission._('unableToDetermine');
  
  @override
  bool operator ==(Object other) => other is LocationPermission && other._value == _value;
  @override
  int get hashCode => _value.hashCode;
}

class Geolocator {
  static Future<Position> getCurrentPosition() async => Position.demo();
  static Future<bool> isLocationServiceEnabled() async => true;
  static Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;
  static Future<LocationPermission> requestPermission() async => LocationPermission.whileInUse;
  static Stream<Position> getPositionStream() => Stream.periodic(const Duration(seconds: 5), (_) => Position.demo());
}

class LocationSettings {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  LocationSettings({this.accuracy = LocationAccuracy.high, this.distanceFilter = 0});
}
