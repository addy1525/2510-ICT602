class User {
  final int? id;
  final String username;
  final String password;
  final String role;
  final String? fullName;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.fullName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'fullName': fullName,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      fullName: map['fullName'],
    );
  }
}
