import 'package:flutter_test/flutter_test.dart';
import 'package:prm/models/voucher.dart';
import 'package:prm/models/wheel_slice.dart';
import 'package:prm/models/user_quest.dart';

void main() {
  group('Voucher Model Discount Calculation Tests', () {
    test('Fixed discount calculation', () {
      final voucher = Voucher(
        code: 'TEST20K',
        title: 'Giảm 20k',
        discountType: 'FIXED',
        discountValue: 20000,
        minOrderValue: 200000,
      );

      // Đơn hàng chưa đạt mức tối thiểu
      expect(voucher.calculateDiscount(150000), 0.0);

      // Đơn hàng đạt mức tối thiểu
      expect(voucher.calculateDiscount(250000), 20000.0);
    });

    test('Percent discount calculation with maxDiscount cap', () {
      final voucher = Voucher(
        code: 'TEST10',
        title: 'Giảm 10%',
        discountType: 'PERCENT',
        discountValue: 10,
        minOrderValue: 300000,
        maxDiscount: 50000,
      );

      // Đơn 400k -> 10% = 40k (< 50k max)
      expect(voucher.calculateDiscount(400000), 40000.0);

      // Đơn 1 triệu -> 10% = 100k (> 50k max) -> chặn ở 50k
      expect(voucher.calculateDiscount(1000000), 50000.0);
    });

    test('Free shipping discount calculation', () {
      final voucher = Voucher(
        code: 'TESTSHIP',
        title: 'Freeship',
        discountType: 'FREE_SHIP',
        discountValue: 30000,
        minOrderValue: 100000,
      );

      expect(voucher.calculateDiscount(150000, shippingFee: 25000), 25000.0);
    });
  });

  group('Wheel Configuration Tests', () {
    test('Wheel has exactly 8 slices with unique indices', () {
      final slices = DefaultWheelConfig.slices;
      expect(slices.length, 8);

      final indices = slices.map((s) => s.index).toSet();
      expect(indices.length, 8);
    });

    test('Slot 8 is 30k discount as customized', () {
      final slice8 = DefaultWheelConfig.slices.firstWhere((s) => s.index == 7);
      expect(slice8.label, '30.000₫');
      expect(slice8.voucherCode, 'FLASH30K');
      expect(slice8.isVoucher, true);
    });
  });

  group('UserDailyQuest Model Tests', () {
    test('Daily Quest limits order spins to max 2', () {
      final quest = UserDailyQuest(
        userId: 3,
        questDate: '2026-11-09',
        loginClaimed: false,
        orderSpinsEarned: 1,
      );

      expect(quest.canClaimLogin, true);
      expect(quest.canEarnFromOrder, true);

      final completedQuest = quest.copyWith(orderSpinsEarned: 2, loginClaimed: true);
      expect(completedQuest.canEarnFromOrder, false);
      expect(completedQuest.canClaimLogin, false);
    });
  });
}

