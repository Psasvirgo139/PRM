import 'package:flutter/material.dart';
import '../models/user_quest.dart';
import '../repositories/quest_repository.dart';

class QuestProvider extends ChangeNotifier {
  final QuestRepository _questRepository = QuestRepository();

  UserDailyQuest? _todayQuest;
  bool _isLoading = false;
  String? _errorMessage;
  int _userId = 3; // Mặc định ID 3 (customer)

  UserDailyQuest? get todayQuest => _todayQuest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  QuestProvider({int? initialUserId}) {
    if (initialUserId != null) {
      _userId = initialUserId;
    }
    loadTodayQuest();
  }

  void setUserId(int newUserId) {
    if (_userId != newUserId) {
      _userId = newUserId;
      loadTodayQuest();
    }
  }

  /// Tải tiến độ nhiệm vụ hôm nay
  Future<void> loadTodayQuest() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _todayQuest = await _questRepository.getTodayQuest(_userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi tải nhiệm vụ: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nhận thưởng điểm danh mỗi ngày (+1 lượt)
  Future<bool> claimDailyLogin() async {
    try {
      final success = await _questRepository.claimDailyLoginSpin(_userId);
      if (success) {
        await loadTodayQuest();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Kích hoạt thưởng khi đặt đơn hàng thành công (+1 lượt/đơn, tối đa 2/ngày)
  Future<bool> rewardOrderCompleted() async {
    try {
      final success = await _questRepository.rewardOrderSpin(_userId);
      if (success) {
        await loadTodayQuest();
      }
      return success;
    } catch (e) {
      debugPrint('Lỗi thưởng lượt từ order: $e');
      return false;
    }
  }
}

