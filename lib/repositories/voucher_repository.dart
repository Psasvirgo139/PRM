import '../core/database/database_helper.dart';
import '../models/voucher.dart';

class VoucherRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Lấy tất cả voucher có trên hệ thống
  Future<List<Voucher>> getAllVouchers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.query(
      'vouchers',
      orderBy: 'id ASC',
    );
    return res.map((m) => Voucher.fromMap(m)).toList();
  }

  /// Lấy voucher theo mã code (ví dụ: 'LUCKY20K')
  Future<Voucher?> getVoucherByCode(String code) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'vouchers',
      where: 'code = ?',
      whereArgs: [code.trim().toUpperCase()],
    );
    if (res.isNotEmpty) {
      return Voucher.fromMap(res.first);
    }
    return null;
  }

  /// Lấy danh sách Voucher trong kho của 1 User (kèm thông tin chi tiết Voucher)
  Future<List<UserVoucher>> getUserVouchers(int userId, {bool? onlyUnused}) async {
    final db = await _dbHelper.database;
    String whereClause = 'uv.user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (onlyUnused == true) {
      whereClause += ' AND uv.is_used = 0';
    }

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        uv.id AS user_voucher_id,
        uv.user_id,
        uv.voucher_id,
        uv.is_used,
        uv.used_at,
        uv.acquired_at,
        v.id AS v_id,
        v.code,
        v.title,
        v.description,
        v.discount_type,
        v.discount_value,
        v.min_order_value,
        v.max_discount,
        v.color_hex,
        v.created_at AS v_created_at
      FROM user_vouchers uv
      INNER JOIN vouchers v ON uv.voucher_id = v.id
      WHERE $whereClause
      ORDER BY uv.is_used ASC, uv.id DESC
    ''', whereArgs);

    return results.map((row) {
      final voucher = Voucher(
        id: row['v_id'] as int?,
        code: row['code'] as String,
        title: row['title'] as String,
        description: (row['description'] as String?) ?? '',
        discountType: (row['discount_type'] as String?) ?? 'FIXED',
        discountValue: (row['discount_value'] as num?)?.toDouble() ?? 0.0,
        minOrderValue: (row['min_order_value'] as num?)?.toDouble() ?? 0.0,
        maxDiscount: (row['max_discount'] as num?)?.toDouble() ?? 0.0,
        colorHex: (row['color_hex'] as String?) ?? '#FF9800',
        createdAt: (row['v_created_at'] as String?) ?? '',
      );

      return UserVoucher(
        id: row['user_voucher_id'] as int?,
        userId: row['user_id'] as int,
        voucherId: row['voucher_id'] as int,
        isUsed: (row['is_used'] as int?) == 1,
        usedAt: row['used_at'] as String?,
        acquiredAt: (row['acquired_at'] as String?) ?? '',
        voucher: voucher,
      );
    }).toList();
  }

  /// Thêm voucher trúng thưởng vào kho của user
  Future<int> addVoucherToUser({
    required int userId,
    required int voucherId,
  }) async {
    final db = await _dbHelper.database;
    return await db.insert('user_vouchers', {
      'user_id': userId,
      'voucher_id': voucherId,
      'is_used': 0,
      'acquired_at': DateTime.now().toIso8601String(),
    });
  }

  /// Đánh dấu voucher đã được sử dụng khi hoàn tất đặt hàng
  Future<void> markVoucherAsUsed({
    required int userVoucherId,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'user_vouchers',
      {
        'is_used': 1,
        'used_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userVoucherId],
    );
  }
}

