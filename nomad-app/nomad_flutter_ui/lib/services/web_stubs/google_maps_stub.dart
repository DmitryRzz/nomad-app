import 'package:flutter/material.dart';

class GoogleMap extends StatelessWidget {
  final dynamic initialCameraPosition;
  final Set<dynamic> markers;
  final Function? onMapCreated;
  final Function? onTap;
  const GoogleMap({super.key, this.initialCameraPosition, this.markers = const {}, this.onMapCreated, this.onTap});
  @override
  Widget build(BuildContext context) => Container(color: Colors.grey[300], child: const Center(child: Text('Map not available on web')));
}

class CameraPosition {
  final dynamic target;
  final double zoom;
  const CameraPosition({this.target, this.zoom = 10});
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class Marker {
  final dynamic markerId;
  final LatLng? position;
  final String? infoWindow;
  const Marker({this.markerId, this.position, this.infoWindow});
}

class MarkerId {
  final String value;
  const MarkerId(this.value);
}

class BitmapDescriptor {
  static BitmapDescriptor defaultMarker = BitmapDescriptor();
}

class GoogleMapController {
  Future<void> animateCamera(dynamic update) async {}
}

class CameraUpdate {
  static CameraUpdate newCameraPosition(dynamic position) => CameraUpdate();
}
