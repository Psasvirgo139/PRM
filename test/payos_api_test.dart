import 'package:flutter_test/flutter_test.dart';
import 'package:prm/services/payos_service.dart';

void main() {
  test('PayOS Live API create payment link test', () async {
    final service = PayOSService();
    final orderCode = PayOSService.generateUniqueOrderCode();
    
    final result = await service.createPaymentLink(
      orderCode: orderCode,
      amount: 15000,
      description: 'DH$orderCode',
      items: [
        {
          'name': 'Bàn phím cơ',
          'quantity': 1,
          'price': 15000,
        }
      ],
    );

    expect(result.orderCode, orderCode);
    expect(result.amount, 15000);
    expect(result.checkoutUrl.isNotEmpty, true);
    expect(result.qrCode.isNotEmpty, true);
    expect(result.accountNumber.isNotEmpty, true);

    // Kiểm tra API tra cứu trạng thái
    final status = await service.getPaymentInformation(orderCode);
    expect(status.orderCode, orderCode);
    expect(status.isPending, true);
  });
}

