// Web-compatible sensors stub
import 'dart:async';

class MagnetometerEvent {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
  
  MagnetometerEvent(this.x, this.y, this.z, {DateTime? timestamp}) 
    : timestamp = timestamp ?? DateTime.now();
  
  factory MagnetometerEvent.demo() => MagnetometerEvent(12.0, 5.0, -8.0);
}

Stream<MagnetometerEvent> get magnetometerEvents => 
  Stream.periodic(const Duration(milliseconds: 100), (_) => MagnetometerEvent.demo());

class AccelerometerEvent {
  final double x;
  final double y;
  final double z;
  AccelerometerEvent(this.x, this.y, this.z);
}

Stream<AccelerometerEvent> get accelerometerEvents =>
  Stream.periodic(const Duration(milliseconds: 100), (_) => AccelerometerEvent(0, 0, 9.8));

class GyroscopeEvent {
  final double x;
  final double y;
  final double z;
  GyroscopeEvent(this.x, this.y, this.z);
}

Stream<GyroscopeEvent> get gyroscopeEvents =>
  Stream.periodic(const Duration(milliseconds: 100), (_) => GyroscopeEvent(0, 0, 0));

class UserAccelerometerEvent {
  final double x;
  final double y;
  final double z;
  UserAccelerometerEvent(this.x, this.y, this.z);
}

Stream<UserAccelerometerEvent> get userAccelerometerEvents =>
  Stream.periodic(const Duration(milliseconds: 100), (_) => UserAccelerometerEvent(0, 0, 0));
