class MagnetometerEvent {
  final double x, y, z;
  MagnetometerEvent(this.x, this.y, this.z);
}
Stream<MagnetometerEvent> get magnetometerEvents => Stream.empty();
