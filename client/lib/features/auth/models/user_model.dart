class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool mustChangePassword;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.mustChangePassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      mustChangePassword: json['mustChangePassword'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'mustChangePassword': mustChangePassword,
    };
  }
}
