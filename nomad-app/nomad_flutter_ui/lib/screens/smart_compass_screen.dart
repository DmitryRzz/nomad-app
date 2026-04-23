import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../theme/sunset_theme.dart';
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
  double _heading = 0;
  double _pitch = 0;
  double _roll = 0;

  final double _visibleDistance = 500;
  final double _fieldOfView = 60;

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
      debugPrint('Camera error: $e');
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
      debugPrint('Location error: $e');
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
      debugPrint('POI fetch error: $e');
    }
  }

  void _startSensors() {
    magnetometerEvents.listen((event) {
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
    const double R = 6371000;
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

    double x = (screenSize.width / 2) + (angleDiff / (_fieldOfView / 2)) * (screenSize.width / 2);

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
              decoration: const BoxDecoration(gradient: SunsetGradients.background),
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
    final categoryColor = _getCategoryColor(poi.category);
    return GestureDetector(
      onTap: () => _showPOIDetails(poi),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 170,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(poi.category),
                        color: categoryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        poi.name,
                        style: const TextStyle(
                          color: SunsetColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${poi.distanceMeters?.toStringAsFixed(0) ?? '?'}m • ${poi.category.toUpperCase()}',
                  style: const TextStyle(
                    color: SunsetColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (poi.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: SunsetColors.sunsetYellow, size: 12),
                      Text(
                        ' ${poi.rating!.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: SunsetColors.textDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPOIDetails(POI poi) {
    final categoryColor = _getCategoryColor(poi.category);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: SunsetGradients.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(poi.category),
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    poi.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (poi.description != null)
              Text(
                poi.description!,
                style: const TextStyle(color: SunsetColors.textLightMuted, fontSize: 14),
              ),
            const SizedBox(height: 16),
            _buildInfoRow('Distance', '${poi.distanceMeters?.toStringAsFixed(0) ?? '?'}m'),
            _buildInfoRow('Category', poi.category.toUpperCase()),
            if (poi.address != null)
              _buildInfoRow('Address', poi.address!),
            if (poi.priceLevel != null)
              _buildInfoRow('Price', '💰' * poi.priceLevel!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: categoryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Add to Route', style: TextStyle(fontWeight: FontWeight.w700)),
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
            style: const TextStyle(
              color: SunsetColors.textLightMuted,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.explore, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_heading.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_nearbyPOIs.where(_isPOIInView).length} visible',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.5),
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
            ? Colors.white
            : Colors.white.withOpacity(0.2),
        foregroundColor: isSelected ? SunsetColors.sunsetRed : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
        return SunsetColors.sunsetRed;
      case 'cafe':
        return SunsetColors.sunsetYellow;
      case 'museum':
        return SunsetColors.sunsetPink;
      case 'landmark':
        return SunsetColors.sunsetBlue;
      case 'park':
        return const Color(0xFF2D6A4F);
      case 'shop':
        return const Color(0xFFFF9FF3);
      default:
        return SunsetColors.textMuted;
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
