import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route.dart' as nomad_route;
import '../providers/route_provider.dart';

class RouteDetailScreen extends ConsumerWidget {
  const RouteDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(selectedRouteProvider);

    if (route == null) {
      return const Scaffold(
        body: Center(child: Text('No route selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(route.title),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, route.id),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map section
          SizedBox(
            height: 250,
            child: _RouteMap(stops: route.stops),
          ),
          
          // Route info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.schedule,
                  label: '${route.estimatedDurationHours?.toStringAsFixed(1) ?? '?'}h',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.place,
                  label: '${route.stops.length} stops',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.location_on,
                  label: route.city,
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Stops list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: route.stops.length,
              itemBuilder: (context, index) {
                return StopItem(
                  stop: route.stops[index],
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String routeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Are you sure you want to delete this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(routesProvider.notifier).deleteRoute(routeId);
              if (success && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  final List<nomad_route.RouteStop> stops;

  const _RouteMap({required this.stops});

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Text('No map data')),
      );
    }

    final center = LatLng(
      stops.map((s) => s.latitude).reduce((a, b) => a + b) / stops.length,
      stops.map((s) => s.longitude).reduce((a, b) => a + b) / stops.length,
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 13,
      ),
      markers: stops.asMap().entries.map((entry) {
        return Marker(
          markerId: MarkerId('stop_${entry.key}'),
          position: LatLng(entry.value.latitude, entry.value.longitude),
          infoWindow: InfoWindow(
            title: entry.value.poiName,
            snippet: '${entry.value.durationMinutes} min',
          ),
        );
      }).toSet(),
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: stops.map((s) => LatLng(s.latitude, s.longitude)).toList(),
          color: Theme.of(context).colorScheme.primary,
          width: 4,
        ),
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

class StopItem extends ConsumerWidget {
  final nomad_route.RouteStop stop;
  final int index;

  const StopItem({super.key, required this.stop, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(stop.category),
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          stop.poiName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${stop.category.toUpperCase()} • ${stop.durationMinutes} min',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (stop.address != null)
              Text(
                stop.address!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stop.indoor)
              Icon(Icons.home, size: 16, color: Colors.blue[400]),
            const SizedBox(width: 8),
            _buildStatusIcon(),
          ],
        ),
        onTap: () {
          // TODO: Navigate to POI detail
        },
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (stop.visited) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (stop.skipped) {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    return const Icon(Icons.circle_outlined, color: Colors.grey);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'museum':
        return Colors.purple;
      case 'restaurant':
        return Colors.orange;
      case 'cafe':
        return Colors.brown;
      case 'park':
        return Colors.green;
      case 'landmark':
        return Colors.blue;
      case 'shop':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
