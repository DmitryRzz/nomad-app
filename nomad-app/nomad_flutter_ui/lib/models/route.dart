class Route {
  final String id;
  final String title;
  final String city;
  final String? country;
  final String status;
  final double? estimatedDurationHours;
  final List<RouteStop> stops;
  final List<String>? tags;
  final DateTime? createdAt;

  Route({
    required this.id,
    required this.title,
    required this.city,
    this.country,
    required this.status,
    this.estimatedDurationHours,
    required this.stops,
    this.tags,
    this.createdAt,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Route',
      city: json['city'] ?? '',
      country: json['country'],
      status: json['status'] ?? 'draft',
      estimatedDurationHours: json['estimated_duration_hours']?.toDouble(),
      stops: (json['stops'] as List<dynamic>?)
              ?.map((s) => RouteStop.fromJson(s))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      createdAt: json['created_at'] != null
          ? (json['created_at'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000)
              : DateTime.parse(json['created_at']))
          : null,
    );
  }
}

class RouteStop {
  final String id;
  final String poiName;
  final String category;
  final String? description;
  final int durationMinutes;
  final String? plannedTime;
  final double latitude;
  final double longitude;
  final String? address;
  final bool indoor;
  final bool visited;
  final bool skipped;

  RouteStop({
    required this.id,
    required this.poiName,
    required this.category,
    this.description,
    required this.durationMinutes,
    this.plannedTime,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.indoor,
    required this.visited,
    required this.skipped,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] ?? '',
      poiName: json['poi_name'] ?? 'Unknown',
      category: json['category'] ?? 'other',
      description: json['description'],
      durationMinutes: json['duration_minutes'] ?? 60,
      plannedTime: json['planned_time'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      indoor: json['indoor'] ?? false,
      visited: json['visited'] ?? false,
      skipped: json['skipped'] ?? false,
    );
  }
}

class RouteGenerationRequest {
  final String city;
  final String? country;
  final List<String> interests;
  final int budgetLevel;
  final String pace;

  RouteGenerationRequest({
    required this.city,
    this.country,
    this.interests = const [],
    this.budgetLevel = 3,
    this.pace = 'balanced',
  });

  Map<String, dynamic> toJson() => {
        'city': city,
        'country': country,
        'interests': interests,
        'budgetLevel': budgetLevel,
        'pace': pace,
      };
}
