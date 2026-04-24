// Web-compatible Google Maps stub
import 'package:flutter/material.dart';

class GoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final MapType mapType;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final ArgumentCallback<GoogleMapController>? onMapCreated;
  final VoidCallback? onTap;
  
  const GoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.mapType = MapType.normal,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.onMapCreated,
    this.onTap,
  });

  @override
  State<GoogleMap> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue[100]!, Colors.blue[50]!],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map, size: 64, color: Colors.blue[300]),
              const SizedBox(height: 8),
              Text(
                'Map Preview\n${widget.initialCameraPosition.target.latitude.toStringAsFixed(2)}, ${widget.initialCameraPosition.target.longitude.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue[700]),
              ),
              if (widget.markers.isNotEmpty)
                Text(
                  '${widget.markers.length} places',
                  style: TextStyle(color: Colors.blue[600], fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CameraPosition {
  final LatLng target;
  final double zoom;
  final double tilt;
  final double bearing;
  
  const CameraPosition({
    required this.target,
    this.zoom = 10,
    this.tilt = 0,
    this.bearing = 0,
  });
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class Marker {
  final MarkerId markerId;
  final LatLng position;
  final InfoWindow infoWindow;
  final BitmapDescriptor icon;
  
  Marker({
    required this.markerId,
    required this.position,
    this.infoWindow = const InfoWindow(),
    this.icon = BitmapDescriptor.defaultMarker,
  });
}

class MarkerId {
  final String value;
  const MarkerId(this.value);
}

class InfoWindow {
  final String? title;
  final String? snippet;
  const InfoWindow({this.title, this.snippet});
}

class BitmapDescriptor {
  static const BitmapDescriptor defaultMarker = BitmapDescriptor._('default');
  final String _type;
  const BitmapDescriptor._(this._type);
}

class GoogleMapController {
  Future<void> animateCamera(CameraUpdate update) async {}
  Future<void> moveCamera(CameraUpdate update) async {}
}

abstract class CameraUpdate {
  static CameraUpdate newCameraPosition(CameraPosition position) => _CameraUpdateNewPosition(position);
  static CameraUpdate newLatLng(LatLng latLng) => _CameraUpdateNewLatLng(latLng);
  static CameraUpdate zoomTo(double zoom) => _CameraUpdateZoom(zoom);
}

class _CameraUpdateNewPosition extends CameraUpdate {
  final CameraPosition position;
  _CameraUpdateNewPosition(this.position);
}

class _CameraUpdateNewLatLng extends CameraUpdate {
  final LatLng latLng;
  _CameraUpdateNewLatLng(this.latLng);
}

class _CameraUpdateZoom extends CameraUpdate {
  final double zoom;
  _CameraUpdateZoom(this.zoom);
}

enum MapType { none, normal, satellite, terrain, hybrid }

typedef ArgumentCallback<T> = void Function(T argument);
