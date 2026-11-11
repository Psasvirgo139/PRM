import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/product.dart';
import '../repositories/chat_repository.dart';
import '../repositories/product_repository.dart';
import '../services/ai_chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepo;
  final AiChatService _aiService;
  final ProductRepository _productRepo;

  ChatProvider({
    ChatRepository? chatRepo,
    AiChatService? aiService,
    ProductRepository? productRepo,
  })  : _chatRepo = chatRepo ?? ChatRepository(),
        _aiService = aiService ?? AiChatService(),
        _productRepo = productRepo ?? ProductRepository();

  List<ChatMessage> _messages = [];
  final Map<int, Product> _productCache = {};
  bool _isLoadingHistory = false;
  bool _isTyping = false;
  int? _userId;

  List<ChatMessage> get messages => _messages;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isTyping => _isTyping;

  Product? getCachedProduct(int id) => _productCache[id];

  // Các gợi ý câu hỏi nhanh thông minh
  static const List<String> quickSuggestions = [
    '📱 Tư vấn điện thoại chụp ảnh đẹp',
    '💻 Laptop mỏng nhẹ pin trâu cho sinh viên',
    '🔥 Top laptop gaming mạnh nhất',
    '🎧 Tìm tai nghe chống ồn tốt',
    '🎟️ Mã giảm giá hôm nay có gì?',
    '🛡️ Chính sách bảo hành & đổi trả',
  ];

  // Khởi tạo và nạp lịch sử chat
  Future<void> init(int? userId) async {
    _userId = userId;
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final history = await _chatRepo.getMessages(userId: _userId);
      if (history.isNotEmpty) {
        _messages = history;
        await _cacheProductsForMessages(_messages);
      } else {
        // Nạp tin nhắn chào mừng khởi đầu từ PRM Bot
        final welcomeMsg = ChatMessage(
          userId: _userId,
          sender: 'ai',
          content: 'Xin chào! 👋 Tôi là **PRM TechBot** – Trợ lý ảo tư vấn công nghệ chính hãng của PRM Shop.\n\n'
              'Tôi có thể giúp bạn:\n'
              '• 📱 Tư vấn điện thoại, laptop, phụ kiện theo ngân sách\n'
              '• ⚖️ So sánh thông số kỹ thuật chi tiết các sản phẩm\n'
              '• 🎟️ Cập nhật mã giảm giá & vòng quay may mắn\n'
              '• 🛡️ Tra cứu chính sách bảo hành, giao hàng 24/7\n\n'
              'Hôm nay bạn cần tôi hỗ trợ tìm kiếm thiết bị nào?',
        );
        final id = await _chatRepo.insertMessage(welcomeMsg);
        _messages = [welcomeMsg.copyWith(id: id)];
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // Gửi tin nhắn từ người dùng
  Future<void> sendMessage(String text, {int? userId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final actualUserId = userId ?? _userId;

    // 1. Thêm tin nhắn của User vào danh sách và SQLite
    final userMessage = ChatMessage(
      userId: actualUserId,
      sender: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );

    final userMsgId = await _chatRepo.insertMessage(userMessage);
    _messages.add(userMessage.copyWith(id: userMsgId));
    _isTyping = true;
    notifyListeners();

    // 2. Mô phỏng độ trễ suy nghĩ chân thực của AI (500ms - 800ms)
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      // 3. Tạo câu trả lời từ AI Chat Service
      final aiResponse = await _aiService.generateResponse(trimmed);

      // Nạp trước dữ liệu các sản phẩm được gợi ý vào cache
      if (aiResponse.suggestedProductIds.isNotEmpty) {
        for (final pId in aiResponse.suggestedProductIds) {
          if (!_productCache.containsKey(pId)) {
            final p = await _productRepo.getProductById(pId);
            if (p != null) {
              _productCache[pId] = p;
            }
          }
        }
      }

      // 4. Lưu tin nhắn của AI vào danh sách và SQLite
      final aiMessage = ChatMessage(
        userId: actualUserId,
        sender: 'ai',
        content: aiResponse.text,
        suggestedProductIds: aiResponse.suggestedProductIds,
        createdAt: DateTime.now(),
      );

      final aiMsgId = await _chatRepo.insertMessage(aiMessage);
      _messages.add(aiMessage.copyWith(id: aiMsgId));
    } catch (e) {
      final errorMsg = ChatMessage(
        userId: actualUserId,
        sender: 'ai',
        content: 'Rất tiếc, đã có lỗi xảy ra khi xử lý phản hồi. Bạn vui lòng thử lại nhé!',
      );
      _messages.add(errorMsg);
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  // Xóa toàn bộ lịch sử trò chuyện
  Future<void> clearHistory({int? userId}) async {
    final actualUserId = userId ?? _userId;
    await _chatRepo.clearHistory(userId: actualUserId);
    _messages.clear();

    final welcomeMsg = ChatMessage(
      userId: actualUserId,
      sender: 'ai',
      content: 'Cuộc trò chuyện đã được làm mới! 🤖\n\nBạn đang quan tâm đến dòng điện thoại, laptop hay phụ kiện nào cần tôi tư vấn?',
    );
    final id = await _chatRepo.insertMessage(welcomeMsg);
    _messages = [welcomeMsg.copyWith(id: id)];
    notifyListeners();
  }

  Future<void> _cacheProductsForMessages(List<ChatMessage> list) async {
    final Set<int> allIds = {};
    for (final m in list) {
      allIds.addAll(m.suggestedProductIds);
    }
    for (final id in allIds) {
      if (!_productCache.containsKey(id)) {
        final p = await _productRepo.getProductById(id);
        if (p != null) {
          _productCache[id] = p;
        }
      }
    }
  }
}

