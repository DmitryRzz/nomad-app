import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/poi.dart';
import '../services/api_service.dart';

class SmartCompassScreen extends StatefulWidget {
  const SmartCompassScreen({super.key});

  @override
  State<SmartCompassScreen> createState() => _SmartCompassScreenState();
}

class _SmartCompassScreenState extends State<SmartCompassScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  
  final ApiService _apiService = ApiService();
  List<POI> _nearbyPOIs = [];
  bool _isLoading = true;
  
  Position? _userPosition;
  double _heading = 0; // Device heading in degrees
  double _pitch = 0; // Device pitch
  double _roll = 0;  // Device roll
  
  final double _visibleDistance = 500; // meters
  final double _fieldOfView = 60; // degrees

  @override
  void initState() {
    super.initState();
    _initCamera();
    _getLocation();
    _startSensors();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras.first,
          ),
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Camera error: $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        _userPosition = await Geolocator.getCurrentPosition();
        await _fetchNearbyPOIs();
      }
    } catch (e) {
      print('Location error: $e');
    }
  }

  Future<void> _fetchNearbyPOIs() async {
    if (_userPosition == null) return;
    
    try {
      final pois = await _apiService.getNearbyPOI(
        _userPosition!.latitude,
        _userPosition!.longitude,
        radius: 500,
      );
      
      if (mounted) {
        setState(() {
          _nearbyPOIs = pois;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('POI fetch error: $e');
    }
  }

  void _startSensors() {
    magnetometerEvents.listen((event) {
      // Calculate heading from magnetometer
      double newHeading = _calculateHeading(event.x, event.y);
      setState(() {
        _heading = newHeading;
      });
    });

    accelerometerEvents.listen((event) {
      setState(() {
        _pitch = _calculatePitch(event.x, event.y, event.z);
        _roll = _calculateRoll(event.x, event.y, event.z);
      });
    });
  }

  double _calculateHeading(double x, double y) {
    double heading = math.atan2(y, x) * (180 / math.pi);
    if (heading < 0) heading += 360;
    return heading;
  }

  double _calculatePitch(double x, double y, double z) {
    return math.atan2(x, math.sqrt(y * y + z * z)) * (180 / math.pi);
  }

  double _calculateRoll(double x, double y, double z) {
    return math.atan2(y, z) * (180 / math.pi);
  }

  double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    double dLng = (lng2 - lng1) * (math.pi / 180);
    lat1 = lat1 * (math.pi / 180);
    lat2 = lat2 * (math.pi / 180);
    
    double y = math.sin(dLng) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) - 
               math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    
    double bearing = math.atan2(y, x) * (180 / math.pi);
    if (bearing < 0) bearing += 360;
    return bearing;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double R = 6371000; // Earth radius in meters
    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLng = (lng2 - lng1) * (math.pi / 180);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
               math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
               math.sin(dLng / 2) * math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return R * c;
  }

  bool _isPOIInView(POI poi) {
    if (_userPosition == null) return false;
    
    double bearing = _calculateBearing(
      _userPosition!.latitude,
      _userPosition!.longitude,
      poi.latitude,
      poi.longitude,
    );
    
    double distance = _calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      poi.latitude,
      poi.longitude,
    );
    
    // Check if POI is within field of view
    double angleDiff = (bearing - _heading).abs();
    if (angleDiff > 180) angleDiff = 360 - angleDiff;
    
    return angleDiff < (_fieldOfView / 2) && distance < _visibleDistance;
  }

  Offset? _calculateScreenPosition(POI poi, Size screenSize) {
    if (_userPosition == null) return null;
    
    double bearing = _calculateBearing(
      _userPosition!.latitude,
      _userPosition!.longitude,
      poi.latitude,
      poi.longitude,
    );
    
    double angleDiff = bearing - _heading;
    if (angleDiff > 180) angleDiff -= 360;
    if (angleDiff < -180) angleDiff += 360;
    
    // Map angle to screen x position
    double x = (screenSize.width / 2) + (angleDiff / (_fieldOfView / 2)) * (screenSize.width / 2);
    
    // Map distance to y position (closer = lower on screen)
    double distance = _calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      poi.latitude,
      poi.longitude,
    );
    
    double y = (screenSize.height * 0.3) + (distance / _visibleDistance) * (screenSize.height * 0.5);
    
    if (x < 0 || x > screenSize.width || y < 0 || y > screenSize.height) return null;
    
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_cameraController != null && _cameraController!.value.isInitialized)
            CameraPreview(_cameraController!)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          
          // POI overlays
          if (_userPosition != null && !_isLoading)
            _buildPOIOverlays(),
          
          // Top info bar
          _buildInfoBar(),
          
          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildPOIOverlays() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          children: _nearbyPOIs.where(_isPOIInView).map((poi) {
            final position = _calculateScreenPosition(poi, screenSize);
            if (position == null) return const SizedBox.shrink();
            
            return Positioned(
              left: position.dx - 80,
              top: position.dy - 60,
              child: _buildPOIMarker(poi),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPOIMarker(POI poi) {
    return GestureDetector(
      onTap: () => _showPOIDetails(poi),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getCategoryColor(poi.category),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(poi.category),
                  color: _getCategoryColor(poi.category),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    poi.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${poi.distanceMeters?.toStringAsFixed(0) ?? '?'}m • ${poi.category.toUpperCase()}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
              ),
            ),
            if (poi.rating != null)
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 12),
                  Text(
                    ' ${poi.rating!.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showPOIDetails(POI poi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(poi.category),
                  color: _getCategoryColor(poi.category),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    poi.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (poi.description != null)
              Text(
                poi.description!,
                style: TextStyle(color: Colors.grey[300], fontSize: 14),
              ),
            const SizedBox(height: 12),
            _buildInfoRow('Distance', '${poi.distanceMeters?.toStringAsFixed(0) ?? '?'}m'),
            _buildInfoRow('Category', poi.category.toUpperCase()),
            if (poi.address != null)
              _buildInfoRow('Address', poi.address!),
            if (poi.priceLevel != null)
              _buildInfoRow('Price', '💰' * poi.priceLevel!),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add to route
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(poi.category),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add to Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Compass heading
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_heading.toStringAsFixed(0)}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // POI count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_nearbyPOIs.where(_isPOIInView).length} visible',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterButton('All', null),
              _buildFilterButton('Food', 'restaurant'),
              _buildFilterButton('Sight', 'landmark'),
              _buildFilterButton('Shop', 'shop'),
            ],
          ),
        ),
      ),
    );
  }

  String? _selectedCategory;

  Widget _buildFilterButton(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          _selectedCategory = isSelected ? null : category;
          _isLoading = true;
        });
        await _fetchNearbyPOIs();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Colors.white.withOpacity(0.2),
        foregroundColor: isSelected ? Colors.white : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
        return Colors.orange;
      case 'cafe':
        return Colors.brown;
      case 'museum':
        return Colors.purple;
      case 'landmark':
        return Colors.blue;
      case 'park':
        return Colors.green;
      case 'shop':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'cafe':
        return Icons.restaurant;
      case 'museum':
        return Icons.museum;
      case 'landmark':
        return Icons.place;
      case 'park':
        return Icons.park;
      case 'shop':
        return Icons.shopping_bag;
      default:
        return Icons.place;
    }
  }
}