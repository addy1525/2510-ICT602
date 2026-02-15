class User {
  final int? id;
  final String username;
  final String password;
  final String role;
  final String fullName;
  final String email;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.fullName,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'full_name': fullName,
      'email': email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      fullName: map['full_name'],
      email: map['email'],
    );
  }
}
