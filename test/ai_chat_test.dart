import 'package:flutter_test/flutter_test.dart';
import 'package:prm/models/chat_message.dart';
import 'package:prm/models/product.dart';
import 'package:prm/repositories/product_repository.dart';
import 'package:prm/services/ai_chat_service.dart';

class MockProductRepository extends ProductRepository {
  @override
  Future<List<Product>> getAllProducts() async {
    return [
      Product(
        id: 1,
        categoryId: 1,
        name: 'iPhone 15 Pro Max 256GB',
        description: 'Titan tự nhiên, chip A17 Pro',
        price: 29990000.0,
        stockQuantity: 10,
        imageUrl: 'https://example.com/iphone.jpg',
      ),
      Product(
        id: 2,
        categoryId: 1,
        name: 'Samsung Galaxy S24 Ultra',
        description: 'Galaxy AI, camera 200MP',
        price: 27490000.0,
        stockQuantity: 8,
        imageUrl: 'https://example.com/s24.jpg',
      ),
      Product(
        id: 11,
        categoryId: 2,
        name: 'MacBook Air M3 13 inch',
        description: 'Apple M3, pin 18 tiếng, 1.24kg',
        price: 26990000.0,
        stockQuantity: 5,
        imageUrl: 'https://example.com/macbook.jpg',
      ),
      Product(
        id: 21,
        categoryId: 3,
        name: 'AirPods Pro 2 USB-C',
        description: 'Chống ồn 2x, chip H2',
        price: 5490000.0,
        stockQuantity: 20,
        imageUrl: 'https://example.com/airpods.jpg',
      ),
    ];
  }
}

void main() {
  group('AI Chatbox & ChatMessage Tests', () {
    test('ChatMessage model toMap and fromMap works correctly', () {
      final msg = ChatMessage(
        id: 100,
        userId: 3,
        sender: 'ai',
        content: 'Đây là câu trả lời của AI TechBot',
        suggestedProductIds: [1, 2, 11],
        createdAt: DateTime(2026, 11, 11, 12, 0, 0),
      );

      final map = msg.toMap();
      expect(map['id'], 100);
      expect(map['user_id'], 3);
      expect(map['sender'], 'ai');
      expect(map['content'], 'Đây là câu trả lời của AI TechBot');
      expect(map['suggested_product_ids'], '[1,2,11]');

      final parsed = ChatMessage.fromMap(map);
      expect(parsed.id, 100);
      expect(parsed.isAi, true);
      expect(parsed.isUser, false);
      expect(parsed.suggestedProductIds, [1, 2, 11]);
    });

    test('AiChatService handles greetings accurately', () async {
      final service = AiChatService(productRepo: MockProductRepository());
      final res = await service.generateResponse('Xin chào shop!');
      expect(res.text.contains('PRM TechBot'), true);
    });

    test('AiChatService provides voucher and lucky wheel info', () async {
      final service = AiChatService(productRepo: MockProductRepository());
      final res = await service.generateResponse('Có mã giảm giá voucher nào không shop?');
      expect(res.text.contains('VÒNG QUAY MAY MẮN') || res.text.contains('MÃ GIẢM GIÁ'), true);
      expect(res.text.contains('FREESHIP'), true);
    });

    test('AiChatService provides warranty policy details', () async {
      final service = AiChatService(productRepo: MockProductRepository());
      final res = await service.generateResponse('Chính sách bảo hành và đổi trả thế nào?');
      expect(res.text.contains('12 tháng'), true);
      expect(res.text.contains('30 ngày'), true);
    });

    test('AiChatService advises products and attaches suggested IDs', () async {
      final service = AiChatService(productRepo: MockProductRepository());
      final res = await service.generateResponse('Tư vấn điện thoại iPhone chụp ảnh đẹp');
      expect(res.suggestedProductIds.contains(1), true);
    });
  });
}
