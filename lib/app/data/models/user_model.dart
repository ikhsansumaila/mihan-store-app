import '../config/api_config.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final bool googleLinked;
  final bool isGoogleAuth;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.googleLinked = false,
    this.isGoogleAuth = false,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    bool isGoogle = false,
  }) {
    final bool linked = json['googleLinked'] == true ||
        isGoogle ||
        (json['email']?.toString().toLowerCase().endsWith('@gmail.com') ?? false);

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      avatarUrl: json['avatarUrl']?.toString(),
      googleLinked: linked,
      isGoogleAuth: isGoogle || linked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
      'role': role,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'googleLinked': googleLinked,
      'isGoogleAuth': isGoogleAuth,
    };
  }

  bool get isAdmin =>
      role.toLowerCase() == 'admin' ||
      (ApiConfig.isAdminEmail(email) && isGoogle);
  bool get canAccessAdmin => isAdmin;
  bool get isGoogle => googleLinked || isGoogleAuth;
}

