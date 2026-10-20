class User {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String role; // 'ADMIN' or 'CUSTOMER'
  final String avatarUrl;
  final String createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.role = 'CUSTOMER',
    this.avatarUrl = '',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isCustomer => role.toUpperCase() == 'CUSTOMER';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'avatar_url': avatarUrl,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      fullName: map['full_name'] as String,
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'CUSTOMER',
      avatarUrl: (map['avatar_url'] as String?) ?? '',
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? role,
    String? avatarUrl,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
