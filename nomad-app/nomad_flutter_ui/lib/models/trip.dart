class Trip {
  final String id;
  final String title;
  final String? description;
  final String destination;
  final String? country;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'generating', 'draft', 'active', 'completed'
  final String budgetLevel; // 'budget', 'moderate', 'luxury'
  final String intensity; // 'relaxed', 'balanced', 'intense'
  final String transportMode; // 'air', 'land', 'sea', 'mixed'
  final double? totalBudget;
  final double? spentBudget;
  final List<String> interests;
  final List<String> cuisines;
  final String? wakeUpTime;
  final String? sleepTime;
  final List<TripDay> days;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? generationProgress; // 0-100 for streaming

  Trip({
    required this.id,
    required this.title,
    this.description,
    required this.destination,
    this.country,
    required this.startDate,
    required this.endDate,
    this.status = 'draft',
    this.budgetLevel = 'moderate',
    this.intensity = 'balanced',
    this.transportMode = 'mixed',
    this.totalBudget,
    this.spentBudget,
    this.interests = const [],
    this.cuisines = const [],
    this.wakeUpTime,
    this.sleepTime,
    this.days = const [],
    this.createdAt,
    this.updatedAt,
    this.generationProgress,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Trip',
      description: json['description'],
      destination: json['destination'] ?? '',
      country: json['country'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? 'draft',
      budgetLevel: json['budget_level'] ?? 'moderate',
      intensity: json['intensity'] ?? 'balanced',
      transportMode: json['transport_mode'] ?? 'mixed',
      totalBudget: json['total_budget']?.toDouble(),
      spentBudget: json['spent_budget']?.toDouble(),
      interests: List<String>.from(json['interests'] ?? []),
      cuisines: List<String>.from(json['cuisines'] ?? []),
      wakeUpTime: json['wake_up_time'],
      sleepTime: json['sleep_time'],
      days: (json['days'] as List<dynamic>?)
              ?.map((d) => TripDay.fromJson(d))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      generationProgress: json['generation_progress'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'destination': destination,
        'country': country,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': status,
        'budget_level': budgetLevel,
        'intensity': intensity,
        'transport_mode': transportMode,
        'total_budget': totalBudget,
        'spent_budget': spentBudget,
        'interests': interests,
        'cuisines': cuisines,
        'wake_up_time': wakeUpTime,
        'sleep_time': sleepTime,
        'days': days.map((d) => d.toJson()).toList(),
      };

  int get totalDays => days.length;
  int get completedActivities =>
      days.expand((d) => d.activities).where((a) => a.completed).length;
  int get totalActivities =>
      days.expand((d) => d.activities).length;
  double? get progressPercent =>
      totalActivities > 0 ? (completedActivities / totalActivities) * 100 : null;

  Trip copyWith({
    String? id,
    String? title,
    String? description,
    String? destination,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? budgetLevel,
    String? intensity,
    String? transportMode,
    double? totalBudget,
    double? spentBudget,
    List<String>? interests,
    List<String>? cuisines,
    String? wakeUpTime,
    String? sleepTime,
    List<TripDay>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? generationProgress,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      destination: destination ?? this.destination,
      country: country ?? this.country,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      intensity: intensity ?? this.intensity,
      transportMode: transportMode ?? this.transportMode,
      totalBudget: totalBudget ?? this.totalBudget,
      spentBudget: spentBudget ?? this.spentBudget,
      interests: interests ?? this.interests,
      cuisines: cuisines ?? this.cuisines,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      sleepTime: sleepTime ?? this.sleepTime,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      generationProgress: generationProgress ?? this.generationProgress,
    );
  }
}

class TripDay {
  final int dayNumber;
  final DateTime date;
  final String? theme;
  final List<TripActivity> activities;
  final double? dayBudget;

  TripDay({
    required this.dayNumber,
    required this.date,
    this.theme,
    this.activities = const [],
    this.dayBudget,
  });

  factory TripDay.fromJson(Map<String, dynamic> json) {
    return TripDay(
      dayNumber: json['day_number'] ?? 1,
      date: DateTime.parse(json['date']),
      theme: json['theme'],
      activities: (json['activities'] as List<dynamic>?)
              ?.map((a) => TripActivity.fromJson(a))
              .toList() ??
          [],
      dayBudget: json['day_budget']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'date': date.toIso8601String(),
        'theme': theme,
        'activities': activities.map((a) => a.toJson()).toList(),
        'day_budget': dayBudget,
      };
}

class TripActivity {
  final String id;
  final String title;
  final String? description;
  final String category; // 'sightseeing', 'food', 'transport', 'rest', 'shopping', 'entertainment'
  final String? poiId;
  final String? poiName;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final double? cost;
  final String? currency;
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool completed;
  final bool skipped;
  final String? notes;
  final String? bookingUrl;
  final String? imageUrl;

  TripActivity({
    required this.id,
    required this.title,
    this.description,
    this.category = 'sightseeing',
    this.poiId,
    this.poiName,
    this.startTime,
    this.endTime,
    this.durationMinutes = 60,
    this.cost,
    this.currency,
    this.latitude,
    this.longitude,
    this.address,
    this.completed = false,
    this.skipped = false,
    this.notes,
    this.bookingUrl,
    this.imageUrl,
  });

  factory TripActivity.fromJson(Map<String, dynamic> json) {
    return TripActivity(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown',
      description: json['description'],
      category: json['category'] ?? 'sightseeing',
      poiId: json['poi_id'],
      poiName: json['poi_name'],
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      durationMinutes: json['duration_minutes'] ?? 60,
      cost: json['cost']?.toDouble(),
      currency: json['currency'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'],
      completed: json['completed'] ?? false,
      skipped: json['skipped'] ?? false,
      notes: json['notes'],
      bookingUrl: json['booking_url'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'poi_id': poiId,
        'poi_name': poiName,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'cost': cost,
        'currency': currency,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'completed': completed,
        'skipped': skipped,
        'notes': notes,
        'booking_url': bookingUrl,
        'image_url': imageUrl,
      };

  TripActivity copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? poiId,
    String? poiName,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    double? cost,
    String? currency,
    double? latitude,
    double? longitude,
    String? address,
    bool? completed,
    bool? skipped,
    String? notes,
    String? bookingUrl,
    String? imageUrl,
  }) {
    return TripActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      poiId: poiId ?? this.poiId,
      poiName: poiName ?? this.poiName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      completed: completed ?? this.completed,
      skipped: skipped ?? this.skipped,
      notes: notes ?? this.notes,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class TripGenerationRequest {
  final String destination;
  final String? country;
  final DateTime startDate;
  final DateTime endDate;
  final String budgetLevel; // 'budget', 'moderate', 'luxury'
  final String intensity; // 'relaxed', 'balanced', 'intense'
  final String transportMode; // 'air', 'land', 'sea', 'mixed'
  final List<String> interests;
  final List<String> cuisines;
  final String? wakeUpTime;
  final String? sleepTime;
  final int? travelersCount;
  final String? specialRequirements;

  TripGenerationRequest({
    required this.destination,
    this.country,
    required this.startDate,
    required this.endDate,
    this.budgetLevel = 'moderate',
    this.intensity = 'balanced',
    this.transportMode = 'mixed',
    this.interests = const [],
    this.cuisines = const [],
    this.wakeUpTime,
    this.sleepTime,
    this.travelersCount,
    this.specialRequirements,
  });

  Map<String, dynamic> toJson() => {
        'destination': destination,
        'country': country,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'budget_level': budgetLevel,
        'intensity': intensity,
        'transport_mode': transportMode,
        'interests': interests,
        'cuisines': cuisines,
        'wake_up_time': wakeUpTime,
        'sleep_time': sleepTime,
        'travelers_count': travelersCount,
        'special_requirements': specialRequirements,
      };
}

class CostBreakdown {
  final double accommodation;
  final double food;
  final double transport;
  final double activities;
  final double shopping;
  final double other;
  final String currency;

  CostBreakdown({
    this.accommodation = 0,
    this.food = 0,
    this.transport = 0,
    this.activities = 0,
    this.shopping = 0,
    this.other = 0,
    this.currency = 'USD',
  });

  double get total => accommodation + food + transport + activities + shopping + other;

  factory CostBreakdown.fromJson(Map<String, dynamic> json) {
    return CostBreakdown(
      accommodation: (json['accommodation'] ?? 0).toDouble(),
      food: (json['food'] ?? 0).toDouble(),
      transport: (json['transport'] ?? 0).toDouble(),
      activities: (json['activities'] ?? 0).toDouble(),
      shopping: (json['shopping'] ?? 0).toDouble(),
      other: (json['other'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() => {
        'accommodation': accommodation,
        'food': food,
        'transport': transport,
        'activities': activities,
        'shopping': shopping,
        'other': other,
        'currency': currency,
        'total': total,
      };
}
