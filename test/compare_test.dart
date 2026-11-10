import 'package:flutter_test/flutter_test.dart';
import 'package:prm/models/product.dart';
import 'package:prm/providers/compare_provider.dart';
import 'package:prm/repositories/compare_repository.dart';

void main() {
  group('Smart Specs Comparison Tests (Thành viên 4)', () {
    final repository = CompareRepository();

    final p1 = Product(
      id: 1,
      categoryId: 1,
      name: 'iPhone 15 Pro Max 256GB',
      price: 29990000,
      stockQuantity: 10,
    );

    final p2 = Product(
      id: 2,
      categoryId: 1,
      name: 'Samsung Galaxy S24 Ultra',
      price: 27490000,
      stockQuantity: 8,
    );

    final p3 = Product(
      id: 7,
      categoryId: 1,
      name: 'Xiaomi 14 Ultra 512GB',
      price: 24990000,
      stockQuantity: 12,
    );

    test('1. Complex Data Modeling: Specs returned with rich groups and numeric values', () async {
      final specs1 = await repository.getProductSpecs(p1);
      final specs2 = await repository.getProductSpecs(p2);
      final specs3 = await repository.getProductSpecs(p3);

      expect(specs1.groups.isNotEmpty, true);
      expect(specs2.groups.isNotEmpty, true);
      expect(specs3.groups.isNotEmpty, true);

      // Kiểm tra thông số RAM
      final ram1 = specs1.findSpec('ram');
      final ram2 = specs2.findSpec('ram');
      final ram3 = specs3.findSpec('ram');

      expect(ram1?.numericValue, 8.0);
      expect(ram2?.numericValue, 12.0);
      expect(ram3?.numericValue, 16.0);

      // Kiểm tra thông số Pin
      final bat1 = specs1.findSpec('battery_cap');
      final bat2 = specs2.findSpec('battery_cap');
      final bat3 = specs3.findSpec('battery_cap');

      expect(bat1?.numericValue, 4422.0);
      expect(bat2?.numericValue, 5000.0);
      expect(bat3?.numericValue, 5000.0);
    });

    test('2. CompareProvider State: Add, remove, maximum 3 products constraint', () async {
      final provider = CompareProvider();

      expect(provider.count, 0);
      expect(provider.canCompare, false);

      // Thêm sản phẩm 1
      final ok1 = await provider.addProduct(p1);
      expect(ok1, true);
      expect(provider.count, 1);
      expect(provider.canCompare, false);

      // Thêm sản phẩm 2 -> Đủ 2 sản phẩm có thể đối đầu
      final ok2 = await provider.addProduct(p2);
      expect(ok2, true);
      expect(provider.count, 2);
      expect(provider.canCompare, true);

      // Thêm sản phẩm 3 -> Đủ 3 sản phẩm tối đa
      final ok3 = await provider.addProduct(p3);
      expect(ok3, true);
      expect(provider.count, 3);
      expect(provider.isFull, true);

      // Thêm sản phẩm thứ 4 -> Phải từ chối vì tối đa 3 sản phẩm
      final p4 = Product(id: 4, name: 'AirPods Pro', price: 5000000, stockQuantity: 5);
      final ok4 = await provider.addProduct(p4);
      expect(ok4, false);
      expect(provider.count, 3);
      expect(provider.errorMessage, contains('tối đa 3'));

      // Xóa sản phẩm
      provider.removeProduct(p1.id!);
      expect(provider.count, 2);
      expect(provider.isInCompare(p1.id!), false);
    });

    test('3. Differential Highlight & Winner Calculation', () async {
      final provider = CompareProvider();
      await provider.addProduct(p1);
      await provider.addProduct(p2);
      await provider.addProduct(p3);

      final groups = provider.getMergedGroups();
      final perfGroup = groups.firstWhere((g) => g.id == 'perf');

      final comparisonResults = provider.getGroupComparisonResults(perfGroup);
      expect(comparisonResults.isNotEmpty, true);

      // Kiểm tra dòng RAM
      final ramResult = comparisonResults.firstWhere((r) => r.referenceItem.key == 'ram');
      expect(ramResult.isDifferent, true); // 8GB vs 12GB vs 16GB -> Khác biệt
      expect(ramResult.bestProductIndex, 2); // Xiaomi 14 Ultra (16GB) thắng cuộc!

      // Bật chế độ "Chỉ xem điểm khác biệt"
      provider.toggleShowOnlyDifferences();
      expect(provider.showOnlyDifferences, true);

      final diffOnlyResults = provider.getGroupComparisonResults(perfGroup);
      for (final r in diffOnlyResults) {
        expect(r.isDifferent, true); // Tất cả kết quả trả về phải là khác biệt
      }
    });
  });
}
