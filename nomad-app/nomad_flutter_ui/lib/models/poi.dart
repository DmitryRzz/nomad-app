class POI {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double latitude;
  final double longitude;
  final String? address;
  final double? distanceMeters;
  final double? rating;
  final bool indoor;
  final int? priceLevel;
  final bool mustSee;
  final int relevanceScore;

  POI({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.distanceMeters,
    this.rating,
    required this.indoor,
    this.priceLevel,
    required this.mustSee,
    this.relevanceScore = 0,
  });

  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      category: json['category'] ?? 'other',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      distanceMeters: json['distance_meters']?.toDouble(),
      rating: json['rating']?.toDouble(),
      indoor: json['indoor'] ?? false,
      priceLevel: json['price_level'],
      mustSee: json['must_see'] ?? false,
      relevanceScore: json['relevance_score'] ?? 0,
    );
  }
}
