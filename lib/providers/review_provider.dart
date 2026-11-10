import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../repositories/review_repository.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewRepository _repository;

  ReviewProvider({ReviewRepository? repository})
      : _repository = repository ?? ReviewRepository();

  List<Review> _allReviews = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _starFilter;
  bool _filterOnlyWithImages = false;
  bool _isVerifiedBuyer = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get starFilter => _starFilter;
  bool get filterOnlyWithImages => _filterOnlyWithImages;
  bool get isVerifiedBuyer => _isVerifiedBuyer;

  int get totalReviews => _allReviews.length;

  double get averageRating {
    if (_allReviews.isEmpty) return 0.0;
    final sum = _allReviews.fold<double>(0.0, (prev, r) => prev + r.rating);
    final avg = sum / _allReviews.length;
    return (avg * 10).roundToDouble() / 10;
  }

  Map<int, int> get starCounts {
    final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _allReviews) {
      final star = r.rating.round();
      if (counts.containsKey(star)) {
        counts[star] = (counts[star] ?? 0) + 1;
      }
    }
    return counts;
  }

  int get withImagesCount {
    return _allReviews.where((r) => r.images.isNotEmpty).length;
  }

  List<Review> get filteredReviews {
    return _allReviews.where((review) {
      if (_filterOnlyWithImages && review.images.isEmpty) {
        return false;
      }
      if (_starFilter != null && review.rating.round() != _starFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  // Tải danh sách đánh giá của sản phẩm và kiểm tra xác minh đơn hàng
  Future<void> loadReviews(int productId, {int? currentUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allReviews = await _repository.getReviewsByProductId(productId);
      if (currentUserId != null) {
        _isVerifiedBuyer = await _repository.hasUserPurchasedProduct(currentUserId, productId);
      } else {
        _isVerifiedBuyer = false;
      }
    } catch (e) {
      _errorMessage = 'Không thể tải đánh giá: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật bộ lọc
  void setFilter({int? star, bool? onlyWithImages}) {
    if (star != null) {
      // Nếu bấm lại vào star đang chọn thì bỏ lọc
      _starFilter = (_starFilter == star) ? null : star;
    }
    if (onlyWithImages != null) {
      _filterOnlyWithImages = onlyWithImages;
    }
    notifyListeners();
  }

  void resetFilter() {
    _starFilter = null;
    _filterOnlyWithImages = false;
    notifyListeners();
  }

  // Gửi đánh giá mới
  Future<bool> submitReview({
    required int productId,
    required User user,
    required double rating,
    required String comment,
    required List<String> images,
  }) async {
    try {
      final isVerified = await _repository.hasUserPurchasedProduct(user.id!, productId);

      final newReview = Review(
        productId: productId,
        userId: user.id!,
        userName: user.fullName,
        userAvatar: user.avatarUrl,
        rating: rating,
        comment: comment.trim(),
        images: images,
        isVerifiedBuyer: isVerified,
        createdAt: DateTime.now().toIso8601String(),
      );

      final reviewId = await _repository.addReview(newReview);
      if (reviewId > 0) {
        // Nạp lại danh sách đánh giá
        await loadReviews(productId, currentUserId: user.id);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Gửi đánh giá thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  // Xóa đánh giá (chỉ tác giả hoặc admin)
  Future<bool> deleteReview(int reviewId, int productId, {int? currentUserId}) async {
    try {
      final success = await _repository.deleteReview(reviewId);
      if (success) {
        await loadReviews(productId, currentUserId: currentUserId);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Xóa đánh giá thất bại: $e';
      notifyListeners();
      return false;
    }
  }
}

