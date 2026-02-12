/// User Identity Model - Personal & authentication info
/// Stored in: users/{uid}.identity
class UserIdentityModel {
  /// User first name (min 2 chars)
  final String firstName;

  /// User last name (min 2 chars)
  final String lastName;

  /// Email address (unique via Firebase Auth)
  final String email;

  /// Phone number (Bangladesh: 01XXXXXXXXX)
  final String phone;

  /// How user signed up: "password" | "google" | "phone"
  final String authProvider;

  /// Profile photo URL (empty string if none)
  final String photoURL;

  /// Cover photo URL (empty string if none)
  final String coverURL;

  const UserIdentityModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.authProvider,
    required this.photoURL,
    required this.coverURL,
  });

  /// Full name getter for convenience
  String get fullName => '$firstName $lastName'.trim();

  /// Empty identity
  factory UserIdentityModel.empty() {
    return const UserIdentityModel(
      firstName: '',
      lastName: '',
      phone: '',
      email: '',
      authProvider: 'password',
      photoURL: '',
      coverURL: '',
    );
  }

  /// Create from map
  factory UserIdentityModel.fromMap(Map<String, dynamic> map) {
    return UserIdentityModel(
      firstName: map['firstName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      authProvider: map['authProvider']?.toString() ?? 'password',
      photoURL: map['photoURL']?.toString() ?? '',
      coverURL: map['coverURL']?.toString() ?? '',
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'authProvider': authProvider,
      'photoURL': photoURL,
      'coverURL': coverURL,
    };
  }

  /// Copy with
  UserIdentityModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? authProvider,
    String? photoURL,
    String? coverURL,
  }) {
    return UserIdentityModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      authProvider: authProvider ?? this.authProvider,
      photoURL: photoURL ?? this.photoURL,
      coverURL: coverURL ?? this.coverURL,
    );
  }

  /// Check if has profile photo
  bool get hasPhoto => photoURL.isNotEmpty;

  /// Check if has cover photo
  bool get hasCover => coverURL.isNotEmpty;

  /// Get initials for avatar placeholder
  String get initials {
    if (firstName.isEmpty) return '?';
    if (lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    return firstName.substring(0, 1).toUpperCase();
  }

  /// Convenience getter for avatar (alias to photoURL)
  String get avatarUrl => photoURL;
}
