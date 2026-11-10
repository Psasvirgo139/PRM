import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../repositories/voucher_repository.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherRepository _voucherRepository = VoucherRepository();

  List<UserVoucher> _userVouchers = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _userId = 3; // Mặc định ID 3 (customer)

  // Voucher đang được chọn để áp dụng tại màn hình Checkout
  UserVoucher? _selectedVoucherForCheckout;

  List<UserVoucher> get userVouchers => _userVouchers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserVoucher? get selectedVoucherForCheckout => _selectedVoucherForCheckout;

  List<UserVoucher> get availableVouchers =>
      _userVouchers.where((v) => !v.isUsed).toList();

  List<UserVoucher> get usedVouchers =>
      _userVouchers.where((v) => v.isUsed).toList();

  VoucherProvider({int? initialUserId}) {
    if (initialUserId != null) {
      _userId = initialUserId;
    }
    loadUserVouchers();
  }

  void setUserId(int newUserId) {
    if (_userId != newUserId) {
      _userId = newUserId;
      _selectedVoucherForCheckout = null;
      loadUserVouchers();
    }
  }

  /// Tải danh sách voucher trong kho của User
  Future<void> loadUserVouchers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userVouchers = await _voucherRepository.getUserVouchers(_userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi tải kho voucher: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Chọn hoặc hủy chọn voucher cho màn hình Checkout
  void selectVoucherForCheckout(UserVoucher? voucher) {
    if (_selectedVoucherForCheckout?.id == voucher?.id) {
      _selectedVoucherForCheckout = null; // Bấm lần 2 để bỏ chọn
    } else {
      _selectedVoucherForCheckout = voucher;
    }
    notifyListeners();
  }

  /// Tính mức giảm giá cho đơn hàng dựa trên voucher đang chọn
  double calculateCurrentDiscount(double subtotal, {double shippingFee = 30000.0}) {
    if (_selectedVoucherForCheckout == null || _selectedVoucherForCheckout!.voucher == null) {
      return 0.0;
    }
    return _selectedVoucherForCheckout!.voucher!.calculateDiscount(
      subtotal,
      shippingFee: shippingFee,
    );
  }

  /// Đánh dấu voucher đã dùng sau khi đặt hàng thành công
  Future<void> consumeSelectedVoucher() async {
    if (_selectedVoucherForCheckout != null && _selectedVoucherForCheckout!.id != null) {
      try {
        await _voucherRepository.markVoucherAsUsed(
          userVoucherId: _selectedVoucherForCheckout!.id!,
        );
        _selectedVoucherForCheckout = null;
        await loadUserVouchers();
      } catch (e) {
        debugPrint('Lỗi đánh dấu voucher đã dùng: $e');
      }
    }
  }
}

