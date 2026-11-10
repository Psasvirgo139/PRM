import 'package:intl/intl.dart';
import '../core/database/database_helper.dart';
import '../models/user_quest.dart';

class QuestRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _getTodayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Lấy số lượt quay khả dụng hiện tại của User
  Future<int> getUserSpins(int userId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'user_spins',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (res.isNotEmpty) {
      return (res.first['spins_left'] as int?) ?? 0;
    }

    // Nếu chưa có record, khởi tạo 1 lượt mặc định
    await db.insert('user_spins', {
      'user_id': userId,
      'spins_left': 1,
      'total_spins_used': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
    return 1;
  }

  /// Tăng hoặc giảm lượt quay (delta có thể âm khi quay, hoặc dương khi nhận thưởng)
  Future<int> updateSpins({required int userId, required int delta}) async {
    final db = await _dbHelper.database;
    final current = await getUserSpins(userId);
    final newCount = (current + delta).clamp(0, 9999);

    int totalSpinsUsedIncrement = delta < 0 ? (-delta) : 0;

    await db.rawUpdate('''
      UPDATE user_spins 
      SET spins_left = ?, 
          total_spins_used = total_spins_used + ?,
          updated_at = ?
      WHERE user_id = ?
    ''', [newCount, totalSpinsUsedIncrement, DateTime.now().toIso8601String(), userId]);

    return newCount;
  }

  /// Lấy hoặc tạo tiến độ nhiệm vụ của User cho ngày hôm nay
  Future<UserDailyQuest> getTodayQuest(int userId) async {
    final db = await _dbHelper.database;
    final today = _getTodayString();

    final res = await db.query(
      'user_daily_quests',
      where: 'user_id = ? AND quest_date = ?',
      whereArgs: [userId, today],
    );

    if (res.isNotEmpty) {
      return UserDailyQuest.fromMap(res.first);
    }

    // Tạo record mới cho ngày hôm nay
    final newQuest = UserDailyQuest(
      userId: userId,
      questDate: today,
      loginClaimed: false,
      orderSpinsEarned: 0,
    );

    final id = await db.insert('user_daily_quests', newQuest.toMap());
    return newQuest.copyWith(id: id);
  }

  /// Nhận thưởng điểm danh mỗi ngày (+1 lượt)
  Future<bool> claimDailyLoginSpin(int userId) async {
    final db = await _dbHelper.database;
    final quest = await getTodayQuest(userId);

    if (quest.loginClaimed) {
      return false; // Đã nhận hôm nay rồi
    }

    // 1. Đánh dấu đã nhận nhiệm vụ điểm danh
    await db.update(
      'user_daily_quests',
      {'login_claimed': 1},
      where: 'id = ?',
      whereArgs: [quest.id],
    );

    // 2. Cộng +1 lượt quay
    await updateSpins(userId: userId, delta: 1);
    return true;
  }

  /// Thưởng lượt quay khi đặt đơn hàng thành công (+1 lượt/đơn, tối đa 2 lượt/ngày)
  Future<bool> rewardOrderSpin(int userId) async {
    final db = await _dbHelper.database;
    final quest = await getTodayQuest(userId);

    if (!quest.canEarnFromOrder) {
      return false; // Đã đạt giới hạn 2 lượt từ mua hàng hôm nay
    }

    // 1. Tăng số lượt nhận từ order
    final newOrderEarned = quest.orderSpinsEarned + 1;
    await db.update(
      'user_daily_quests',
      {'order_spins_earned': newOrderEarned},
      where: 'id = ?',
      whereArgs: [quest.id],
    );

    // 2. Cộng +1 lượt quay
    await updateSpins(userId: userId, delta: 1);
    return true;
  }
}

