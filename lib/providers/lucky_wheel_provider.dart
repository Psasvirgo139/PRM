import 'dart:math';
import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../models/wheel_slice.dart';
import '../repositories/quest_repository.dart';
import '../repositories/voucher_repository.dart';

class LuckyWheelProvider extends ChangeNotifier {
  final QuestRepository _questRepository = QuestRepository();
  final VoucherRepository _voucherRepository = VoucherRepository();

  int _userId = 3; // Mặc định ID 3 (customer)
  int _spinsLeft = 0;
  bool _isLoading = false;
  bool _isSpinning = false;
  String? _errorMessage;

  final List<WheelSlice> _slices = DefaultWheelConfig.slices;
  WheelSlice? _lastResult;
  Voucher? _lastWonVoucher; // Lưu chi tiết voucher nếu trúng

  List<WheelSlice> get slices => _slices;
  int get spinsLeft => _spinsLeft;
  bool get isLoading => _isLoading;
  bool get isSpinning => _isSpinning;
  String? get errorMessage => _errorMessage;
  WheelSlice? get lastResult => _lastResult;
  Voucher? get lastWonVoucher => _lastWonVoucher;

  LuckyWheelProvider({int? initialUserId}) {
    if (initialUserId != null) {
      _userId = initialUserId;
    }
    loadSpins();
  }

  void setUserId(int newUserId) {
    if (_userId != newUserId) {
      _userId = newUserId;
      loadSpins();
    }
  }

  /// Tải số lượt quay hiện tại của User
  Future<void> loadSpins() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _spinsLeft = await _questRepository.getUserSpins(_userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi tải lượt quay: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thuật toán chọn giải thưởng ngẫu nhiên theo trọng số (Weighted Random)
  WheelSlice _pickWeightedSlice() {
    final totalWeight = _slices.fold<int>(0, (sum, slice) => sum + slice.weight);
    final randomValue = Random().nextInt(totalWeight);

    int cumulative = 0;
    for (var slice in _slices) {
      cumulative += slice.weight;
      if (randomValue < cumulative) {
        return slice;
      }
    }
    return _slices.first;
  }

  /// Bắt đầu quay thưởng
  /// Trả về `WheelSlice` mục tiêu để widget điều khiển Animation xoay đến đúng nan đó
  Future<WheelSlice?> startSpin() async {
    if (_isSpinning) return null;

    if (_spinsLeft <= 0) {
      _errorMessage = 'Bạn đã hết lượt quay! Hãy hoàn thành nhiệm vụ để nhận thêm lượt.';
      notifyListeners();
      return null;
    }

    _isSpinning = true;
    _errorMessage = null;
    _lastResult = null;
    _lastWonVoucher = null;

    // 1. Trừ 1 lượt quay ngay khi bắt đầu
    _spinsLeft--;
    notifyListeners();
    await _questRepository.updateSpins(userId: _userId, delta: -1);

    // 2. Chọn giải thưởng theo trọng số
    final targetSlice = _pickWeightedSlice();
    _lastResult = targetSlice;

    return targetSlice;
  }

  /// Gọi khi Animation quay của bánh xe đã dừng hẳn tại giải thưởng
  Future<void> completeSpin(WheelSlice targetSlice) async {
    _isSpinning = false;

    try {
      if (targetSlice.isVoucher && targetSlice.voucherCode != null) {
        // Lưu voucher vào kho cá nhân của user
        final voucher = await _voucherRepository.getVoucherByCode(targetSlice.voucherCode!);
        if (voucher != null && voucher.id != null) {
          await _voucherRepository.addVoucherToUser(
            userId: _userId,
            voucherId: voucher.id!,
          );
          _lastWonVoucher = voucher;
        }
      } else if (targetSlice.isExtraSpin) {
        // Cộng lại 1 lượt quay thưởng
        _spinsLeft++;
        await _questRepository.updateSpins(userId: _userId, delta: 1);
      }
    } catch (e) {
      debugPrint('Lỗi lưu phần thưởng: $e');
    }

    notifyListeners();
  }

  /// Cập nhật lại số lượt quay (ví dụ sau khi nhận nhiệm vụ từ QuestProvider)
  void refreshSpinsFromExternal(int count) {
    _spinsLeft = count;
    notifyListeners();
  }
}

