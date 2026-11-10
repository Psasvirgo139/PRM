class PayOSPaymentData {
  final String bin;
  final String accountNumber;
  final String accountName;
  final int amount;
  final String description;
  final int orderCode;
  final String currency;
  final String paymentLinkId;
  final String status;
  final String checkoutUrl;
  final String qrCode;

  PayOSPaymentData({
    required this.bin,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.description,
    required this.orderCode,
    this.currency = 'VND',
    required this.paymentLinkId,
    this.status = 'PENDING',
    required this.checkoutUrl,
    required this.qrCode,
  });

  factory PayOSPaymentData.fromJson(Map<String, dynamic> json) {
    return PayOSPaymentData(
      bin: json['bin']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'VND',
      paymentLinkId: json['paymentLinkId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bin': bin,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'amount': amount,
      'description': description,
      'orderCode': orderCode,
      'currency': currency,
      'paymentLinkId': paymentLinkId,
      'status': status,
      'checkoutUrl': checkoutUrl,
      'qrCode': qrCode,
    };
  }

  String get bankName {
    switch (bin) {
      case '970422':
        return 'MB Bank (Quân Đội)';
      case '970415':
        return 'VietinBank';
      case '970436':
        return 'Vietcombank';
      case '970418':
        return 'BIDV';
      case '970407':
        return 'Techcombank';
      case '970423':
        return 'TPBank';
      case '970432':
        return 'VPBank';
      case '970448':
        return 'OCB';
      case '970416':
        return 'ACB';
      default:
        return 'Ngân hàng liên kết VietQR';
    }
  }
}

class PayOSPaymentStatus {
  final String id;
  final int orderCode;
  final int amount;
  final int amountPaid;
  final int amountRemaining;
  final String status;
  final String createdAt;

  PayOSPaymentStatus({
    required this.id,
    required this.orderCode,
    required this.amount,
    required this.amountPaid,
    required this.amountRemaining,
    required this.status,
    required this.createdAt,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isPending => status.toUpperCase() == 'PENDING';

  factory PayOSPaymentStatus.fromJson(Map<String, dynamic> json) {
    return PayOSPaymentStatus(
      id: json['id']?.toString() ?? '',
      orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      amountPaid: (json['amountPaid'] as num?)?.toInt() ?? 0,
      amountRemaining: (json['amountRemaining'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

