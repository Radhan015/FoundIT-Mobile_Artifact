import '../config.dart';

class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? noTelp;
  final String? fotoUrl;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.noTelp,
    this.fotoUrl,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      noTelp: json['no_telp'] as String?,
      fotoUrl: json['foto_url'] as String? ?? (json['foto'] != null ? '${AppConfig.storageUrl}/${json['foto']}' : null),
      role: (json['role'] as String?) ?? 'user',
    );
  }
}
