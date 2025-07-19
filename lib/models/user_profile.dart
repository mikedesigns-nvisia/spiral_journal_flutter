/// Simple user profile model for TestFlight version
/// Contains basic information: first name and birthday
class UserProfile {
  final String firstName;
  final DateTime birthday;
  final DateTime createdAt;

  const UserProfile({
    required this.firstName,
    required this.birthday,
    required this.createdAt,
  });

  /// Create a new user profile
  factory UserProfile.create({
    required String firstName,
    required DateTime birthday,
  }) {
    return UserProfile(
      firstName: firstName,
      birthday: birthday,
      createdAt: DateTime.now(),
    );
  }

  /// Create from JSON (for local storage)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['firstName'] as String,
      birthday: DateTime.parse(json['birthday'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON (for local storage)
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'birthday': birthday.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get user's age
  int get age {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || 
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  /// Get formatted birthday string
  String get formattedBirthday {
    return '${birthday.month}/${birthday.day}/${birthday.year}';
  }

  /// Get display name (just first name for now)
  String get displayName => firstName;

  /// Copy with new values
  UserProfile copyWith({
    String? firstName,
    DateTime? birthday,
    DateTime? createdAt,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      birthday: birthday ?? this.birthday,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.firstName == firstName &&
        other.birthday == birthday &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return firstName.hashCode ^ birthday.hashCode ^ createdAt.hashCode;
  }

  @override
  String toString() {
    return 'UserProfile(firstName: $firstName, birthday: $formattedBirthday, age: $age)';
  }
}
