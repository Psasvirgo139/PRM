import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/payos_config.dart';
import '../models/payos_payment_data.dart';

class PayOSService {
  static final PayOSService _instance = PayOSService._internal();
  factory PayOSService() => _instance;
  PayOSService._internal();

  /// Tạo chữ ký HMAC_SHA256 theo chuẩn payOS
  /// Dữ liệu theo thứ tự bảng chữ cái: amount, cancelUrl, description, orderCode, returnUrl
  static String generateSignature({
    required int amount,
    required String cancelUrl,
    required String description,
    required int orderCode,
    required String returnUrl,
    required String checksumKey,
  }) {
    final rawData =
        'amount=$amount&cancelUrl=$cancelUrl&description=$description&orderCode=$orderCode&returnUrl=$returnUrl';
    final key = utf8.encode(checksumKey);
    final bytes = utf8.encode(rawData);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Sinh mã orderCode dạng số nguyên duy nhất cho mỗi giao dịch payOS (9 chữ số)
  static int generateUniqueOrderCode() {
    final now = DateTime.now();
    // Tạo số nguyên từ timestamp để đảm bảo tính duy nhất và không bị trùng
    return (now.millisecondsSinceEpoch ~/ 1000);
  }

  /// Làm sạch nội dung mô tả đơn hàng (payOS giới hạn tối đa 25 ký tự và không dấu)
  static String sanitizeDescription(String input) {
    String clean = input
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y')
        .replaceAll(RegExp(r'[đ]'), 'd')
        .replaceAll(RegExp(r'[Đ]'), 'D')
        .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');

    clean = clean.trim();
    if (clean.length > 25) {
      clean = clean.substring(0, 25);
    }
    return clean.isEmpty ? 'Thanh toan don hang' : clean;
  }

  /// Tạo link thanh toán PayOS
  Future<PayOSPaymentData> createPaymentLink({
    required int orderCode,
    required int amount,
    required String description,
    List<Map<String, dynamic>>? items,
    String? cancelUrl,
    String? returnUrl,
  }) async {
    final effectiveCancelUrl = cancelUrl ?? PayOSConfig.defaultCancelUrl;
    final effectiveReturnUrl = returnUrl ?? PayOSConfig.defaultReturnUrl;
    final cleanDesc = sanitizeDescription(description);

    final signature = generateSignature(
      amount: amount,
      cancelUrl: effectiveCancelUrl,
      description: cleanDesc,
      orderCode: orderCode,
      returnUrl: effectiveReturnUrl,
      checksumKey: PayOSConfig.checksumKey,
    );

    final payload = {
      'orderCode': orderCode,
      'amount': amount,
      'description': cleanDesc,
      'cancelUrl': effectiveCancelUrl,
      'returnUrl': effectiveReturnUrl,
      'signature': signature,
      if (items != null && items.isNotEmpty) 'items': items,
    };

    final headers = {
      'x-client-id': PayOSConfig.clientId,
      'x-api-key': PayOSConfig.apiKey,
      'Content-Type': 'application/json',
    };

    final url = Uri.parse('${PayOSConfig.baseUrl}/v2/payment-requests');

    if (kDebugMode) {
      debugPrint('[PayOS] Request POST $url');
      debugPrint('[PayOS] Body: ${jsonEncode(payload)}');
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (kDebugMode) {
      debugPrint('[PayOS] Response: ${response.statusCode} - ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['code'] == '00') {
        final data = json['data'] as Map<String, dynamic>;
        return PayOSPaymentData.fromJson(data);
      } else {
        throw Exception(json['desc'] ?? 'Lỗi tạo thanh toán PayOS: ${json['code']}');
      }
    } else {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['desc'] ?? 'Lỗi máy chủ PayOS (${response.statusCode})');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Lỗi kết nối tới PayOS: ${response.statusCode}');
      }
    }
  }

  /// Lấy thông tin trạng thái thanh toán từ PayOS
  Future<PayOSPaymentStatus> getPaymentInformation(int orderCode) async {
    final headers = {
      'x-client-id': PayOSConfig.clientId,
      'x-api-key': PayOSConfig.apiKey,
    };

    final url = Uri.parse('${PayOSConfig.baseUrl}/v2/payment-requests/$orderCode');

    final response = await http.get(url, headers: headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['code'] == '00') {
        final data = json['data'] as Map<String, dynamic>;
        return PayOSPaymentStatus.fromJson(data);
      } else {
        throw Exception(json['desc'] ?? 'Không lấy được thông tin đơn: ${json['code']}');
      }
    } else {
      throw Exception('Lỗi kiểm tra trạng thái thanh toán: ${response.statusCode}');
    }
  }

  /// Hủy link thanh toán trên PayOS
  Future<bool> cancelPaymentLink(int orderCode, {String? reason}) async {
    final headers = {
      'x-client-id': PayOSConfig.clientId,
      'x-api-key': PayOSConfig.apiKey,
      'Content-Type': 'application/json',
    };

    final url = Uri.parse('${PayOSConfig.baseUrl}/v2/payment-requests/$orderCode/cancel');
    final payload = {
      'cancellationReason': reason ?? 'Người dùng hủy thanh toán',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['code'] == '00';
    }
    return false;
  }
}

