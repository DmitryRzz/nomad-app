class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String nativeLanguage;
  final bool emailVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.nativeLanguage = 'ru',
    this.emailVerified = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['created_at'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000);
    } else if (json['created_at'] is String) {
      createdAt = DateTime.parse(json['created_at']);
    } else {
      createdAt = DateTime.now();
    }
    
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      nativeLanguage: json['native_language'] ?? 'ru',
      emailVerified: json['email_verified'] ?? false,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'native_language': nativeLanguage,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? nativeLanguage,
    bool? emailVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: json['expiresAt'] != null 
        ? DateTime.parse(json['expiresAt']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.subtract(const Duration(minutes: 5)));
  }
}
