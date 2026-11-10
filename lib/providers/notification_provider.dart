import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  int? _currentUserId;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  int? get currentUserId => _currentUserId;

  /// Đặt user ID và tải lại danh sách thông báo tương ứng (dùng cho ProxyProvider)
  void setUserId(int? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (userId != null) {
        loadNotifications(userId);
      } else {
        clearLocal();
      }
    }
  }

  /// Nạp danh sách thông báo và số lượng chưa đọc của user
  Future<void> loadNotifications([int? userId]) async {
    final targetId = userId ?? _currentUserId;
    if (targetId == null) return;
    _currentUserId = targetId;
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      final notifs = await _repository.getNotifications(targetId);
      final unread = await _repository.getUnreadCount(targetId);
      _notifications = notifs;
      _unreadCount = unread;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Đánh dấu 1 thông báo là đã đọc
  Future<void> markAsRead(int notificationId, [int? userId]) async {
    try {
      await _repository.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Đánh dấu tất cả thông báo của user là đã đọc
  Future<void> markAllAsRead([int? userId]) async {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null) return;
    try {
      await _repository.markAllAsRead(targetUserId);
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Xóa 1 thông báo
  Future<void> deleteNotification(int notificationId, int userId) async {
    try {
      await _repository.deleteNotification(notificationId);
      final removed = _notifications.firstWhere((n) => n.id == notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      if (!removed.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Xóa sạch tất cả thông báo
  Future<void> clearAll(int userId) async {
    try {
      await _repository.clearAllNotifications(userId);
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  /// Xóa state local khi đăng xuất hoặc đổi tài khoản
  void clearLocal() {
    _notifications.clear();
    _unreadCount = 0;
    _currentUserId = null;
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }
}
