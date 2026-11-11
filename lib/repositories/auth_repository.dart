import '../core/database/database_helper.dart';
import '../models/user.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<User?> login(String username, String password) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username.trim(), password],
    );

    if (res.isNotEmpty) {
      return User.fromMap(res.first);
    }
    return null;
  }

  Future<int> register(User user) async {
    final db = await _dbHelper.database;
    // Kiểm tra xem username đã tồn tại chưa
    final check = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [user.username.trim()],
    );
    if (check.isNotEmpty) {
      throw Exception('Tên đăng nhập "${user.username}" đã tồn tại!');
    }

    return await db.insert('users', user.toMap());
  }

  Future<int> updateUserProfile(User user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {
        'full_name': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'address': user.address,
        'avatar_url': user.avatarUrl,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> changePassword(int userId, String newPassword) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return User.fromMap(res.first);
    }
    return null;
  }
}
