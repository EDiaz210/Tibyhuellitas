class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? address;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isEmailVerified;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLogin,
    this.isEmailVerified = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'],
      address: json['address'],
      profileImageUrl: json['profile_image_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      isEmailVerified: json['is_email_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address': address,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_email_verified': isEmailVerified,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isEmailVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
