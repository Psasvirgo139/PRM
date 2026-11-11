import '../core/database/database_helper.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final DatabaseHelper _dbHelper;

  ChatRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Lấy lịch sử tin nhắn (sắp xếp tăng dần theo thời gian)
  Future<List<ChatMessage>> getMessages({int? userId}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> res;

    if (userId != null) {
      res = await db.query(
        'chat_messages',
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [userId],
        orderBy: 'created_at ASC, id ASC',
      );
    } else {
      res = await db.query(
        'chat_messages',
        where: 'user_id IS NULL',
        orderBy: 'created_at ASC, id ASC',
      );
    }

    return res.map((m) => ChatMessage.fromMap(m)).toList();
  }

  // Lưu tin nhắn mới vào database
  Future<int> insertMessage(ChatMessage message) async {
    final db = await _dbHelper.database;
    return await db.insert('chat_messages', message.toMap());
  }

  // Xóa toàn bộ lịch sử trò chuyện
  Future<int> clearHistory({int? userId}) async {
    final db = await _dbHelper.database;
    if (userId != null) {
      return await db.delete(
        'chat_messages',
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [userId],
      );
    } else {
      return await db.delete(
        'chat_messages',
        where: 'user_id IS NULL',
      );
    }
  }
}

