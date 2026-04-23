import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/sunset_theme.dart';
import '../models/route.dart';
import '../providers/route_provider.dart';
import 'route_detail_screen.dart';
import 'create_route_screen.dart';

class RoutesListScreen extends ConsumerWidget {
  const RoutesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routesProvider);

    return Container(
      decoration: const BoxDecoration(gradient: SunsetGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GradientText(
            text: 'My Routes',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            gradient: LinearGradient(
              colors: [Colors.white, SunsetColors.sunsetYellow],
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRouteScreen()),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        body: routesAsync.when(
          data: (routes) {
            if (routes.isEmpty) {
              return const _EmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                return RouteCard(route: routes[index]);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, _) => Center(
            child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class RouteCard extends ConsumerWidget {
  final Route route;

  const RouteCard({super.key, required this.route});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: SunsetStyles.whiteCard,
      child: InkWell(
        onTap: () {
          ref.read(selectedRouteProvider.notifier).state = route;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RouteDetailScreen()),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SunsetColors.textDark,
                      ),
                    ),
                  ),
                  _StatusBadge(status: route.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: SunsetColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${route.city}${route.country != null ? ', ${route.country}' : ''}',
                    style: const TextStyle(color: SunsetColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: SunsetColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${route.estimatedDurationHours?.toStringAsFixed(1) ?? '?'} hours',
                    style: const TextStyle(color: SunsetColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.place, size: 16, color: SunsetColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${route.stops.length} stops',
                    style: const TextStyle(color: SunsetColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: route.tags?.map((tag) => _TagChip(tag: tag)).toList() ?? [],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SunsetColors.sunsetRed, SunsetColors.sunsetPink],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = SunsetColors.sunsetRed;
        break;
      case 'completed':
        color = SunsetColors.sunsetBlue;
        break;
      case 'draft':
        color = SunsetColors.sunsetYellow;
        break;
      default:
        color = SunsetColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.map_outlined, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'No routes yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first adventure',
            style: TextStyle(color: SunsetColors.textLightMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
