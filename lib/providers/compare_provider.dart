import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/product_spec.dart';
import '../repositories/compare_repository.dart';

class CompareProvider extends ChangeNotifier {
  final CompareRepository _repository = CompareRepository();

  final List<Product> _selectedProducts = [];
  final Map<int, ProductSpecs> _specsCache = {};

  bool _showOnlyDifferences = false;
  bool _highlightDifferences = true;
  bool _highlightBestSpecs = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Product> get selectedProducts => List.unmodifiable(_selectedProducts);
  bool get showOnlyDifferences => _showOnlyDifferences;
  bool get highlightDifferences => _highlightDifferences;
  bool get highlightBestSpecs => _highlightBestSpecs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get count => _selectedProducts.length;
  bool get canCompare => _selectedProducts.length >= 2;
  bool get isFull => _selectedProducts.length >= 3;

  bool isInCompare(int productId) {
    return _selectedProducts.any((p) => p.id == productId);
  }

  ProductSpecs? getSpecsForProduct(int productId) {
    return _specsCache[productId];
  }

  /// Thêm sản phẩm vào danh sách so sánh (tối đa 3 sản phẩm)
  Future<bool> addProduct(Product product) async {
    if (product.id == null) return false;

    // Đã có trong danh sách
    if (isInCompare(product.id!)) {
      _errorMessage = 'Sản phẩm "${product.name}" đã có trong bảng so sánh!';
      notifyListeners();
      return false;
    }

    // Đã đạt tối đa 3 sản phẩm
    if (_selectedProducts.length >= 3) {
      _errorMessage = 'Chỉ có thể so sánh tối đa 3 sản phẩm cùng lúc!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedProducts.add(product);

      // Nạp thông số kỹ thuật nếu chưa có trong cache
      if (!_specsCache.containsKey(product.id)) {
        final specs = await _repository.getProductSpecs(product);
        _specsCache[product.id!] = specs;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi nạp thông số: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Xóa sản phẩm khỏi bảng so sánh
  void removeProduct(int productId) {
    _selectedProducts.removeWhere((p) => p.id == productId);
    _specsCache.remove(productId);
    notifyListeners();
  }

  /// Thay thế sản phẩm tại một vị trí cột so sánh
  Future<void> replaceProduct(int index, Product newProduct) async {
    if (index < 0 || index >= _selectedProducts.length) return;
    if (newProduct.id == null) return;

    // Nếu sản phẩm mới đã có ở cột khác -> bỏ qua
    if (isInCompare(newProduct.id!) && _selectedProducts[index].id != newProduct.id) {
      _errorMessage = 'Sản phẩm đã có trong bảng so sánh!';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final oldId = _selectedProducts[index].id;
      if (oldId != null) _specsCache.remove(oldId);

      _selectedProducts[index] = newProduct;

      final specs = await _repository.getProductSpecs(newProduct);
      _specsCache[newProduct.id!] = specs;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi thay đổi sản phẩm: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa toàn bộ sản phẩm đang so sánh
  void clear() {
    _selectedProducts.clear();
    _specsCache.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Bật/tắt chế độ "Chỉ xem điểm khác biệt"
  void toggleShowOnlyDifferences() {
    _showOnlyDifferences = !_showOnlyDifferences;
    notifyListeners();
  }

  /// Bật/tắt làm nổi bật thông số khác biệt
  void toggleHighlightDifferences() {
    _highlightDifferences = !_highlightDifferences;
    notifyListeners();
  }

  /// Bật/tắt đánh dấu thông số vượt trội
  void toggleHighlightBestSpecs() {
    _highlightBestSpecs = !_highlightBestSpecs;
    notifyListeners();
  }

  /// Lấy danh sách nhóm thông số hợp nhất của tất cả sản phẩm đang so sánh
  List<SpecGroup> getMergedGroups() {
    if (_selectedProducts.isEmpty) return [];

    final Map<String, SpecGroup> groupMap = {};

    for (final p in _selectedProducts) {
      final specs = _specsCache[p.id];
      if (specs == null) continue;

      for (final g in specs.groups) {
        if (!groupMap.containsKey(g.id)) {
          groupMap[g.id] = SpecGroup(
            id: g.id,
            name: g.name,
            icon: g.icon,
            items: List.from(g.items),
          );
        } else {
          // Gộp các spec item chưa có
          final existingGroup = groupMap[g.id]!;
          final existingKeys = existingGroup.items.map((i) => i.key).toSet();
          for (final item in g.items) {
            if (!existingKeys.contains(item.key)) {
              existingGroup.items.add(item);
              existingKeys.add(item.key);
            }
          }
        }
      }
    }

    return groupMap.values.toList();
  }

  /// Tính toán kết quả so sánh đối đầu cho 1 nhóm thông số (Differential Highlight & Winner Calculation)
  List<SpecComparisonResult> getGroupComparisonResults(SpecGroup group) {
    if (_selectedProducts.isEmpty) return [];

    final List<SpecComparisonResult> results = [];

    for (final referenceItem in group.items) {
      final key = referenceItem.key;
      final List<SpecItem?> productItems = [];

      for (final p in _selectedProducts) {
        final specs = _specsCache[p.id];
        final item = specs?.findSpec(key);
        productItems.add(item);
      }

      // 1. Kiểm tra xem các sản phẩm có giá trị khác nhau không
      final values = productItems.map((item) => item?.value.trim().toLowerCase() ?? 'n/a').toSet();
      final bool isDifferent = values.length > 1;

      // 2. Tìm sản phẩm có thông số tốt nhất (Best/Winner) nếu có dữ liệu numericValue
      int? bestIndex;
      if (_highlightBestSpecs && isDifferent) {
        double? bestValue;
        for (int i = 0; i < productItems.length; i++) {
          final item = productItems[i];
          if (item?.numericValue == null) continue;

          final val = item!.numericValue!;
          if (bestValue == null) {
            bestValue = val;
            bestIndex = i;
          } else {
            if (item.isHigherBetter) {
              if (val > bestValue) {
                bestValue = val;
                bestIndex = i;
              }
            } else {
              // Giá trị càng thấp càng tốt (ví dụ: trọng lượng nhẹ hơn, tiến trình nm nhỏ hơn)
              if (val < bestValue) {
                bestValue = val;
                bestIndex = i;
              }
            }
          }
        }
      }

      // 3. Nếu bật "Chỉ hiện điểm khác biệt" và tất cả thông số giống nhau -> bỏ qua
      if (_showOnlyDifferences && !isDifferent) {
        continue;
      }

      results.add(SpecComparisonResult(
        referenceItem: referenceItem,
        productItems: productItems,
        isDifferent: isDifferent,
        bestProductIndex: bestIndex,
      ));
    }

    return results;
  }

  /// Nạp sẵn 2 sản phẩm điện thoại tiêu biểu để tiện demo đối đầu ngay lập tức
  Future<void> loadDefaultDemoComparison() async {
    if (_selectedProducts.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final products = await _repository.getComparableProducts();
      // Ưu tiên chọn iPhone 15 Pro Max và Samsung Galaxy S24 Ultra
      Product? p1 = products.where((p) => p.name.contains('iPhone 15')).firstOrNull;
      Product? p2 = products.where((p) => p.name.contains('S24 Ultra')).firstOrNull;

      p1 ??= products.isNotEmpty ? products[0] : null;
      p2 ??= products.length > 1 ? products[1] : null;

      if (p1 != null) await addProduct(p1);
      if (p2 != null) await addProduct(p2);

      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }
}

