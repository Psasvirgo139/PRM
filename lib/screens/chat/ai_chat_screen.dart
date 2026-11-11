import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../../models/chat_message.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend([String? presetText]) {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;

    final auth = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    chatProvider.sendMessage(text, userId: auth.currentUser?.id);
    _textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa đoạn chat', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử trò chuyện với AI Bot không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              final auth = context.read<AuthProvider>();
              context.read<ChatProvider>().clearHistory(userId: auth.currentUser?.id);
            },
            child: const Text('Xóa sạch'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedProductCard(Product product, CartProvider cart) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 10, top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh sản phẩm
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.backgroundLight,
                  child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                ),
              ),
            ),
          ),

          // Tên và giá
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(product.price),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  // Nút xem chi tiết
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeLight,
                        foregroundColor: AppColors.primaryOrange,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => context.push('/product/${product.id}', extra: product),
                      child: const Text('Xem ngay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ChatProvider chatProvider, CartProvider cart) {
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 60, right: 12, top: 6, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
              topRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                msg.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // AI Message
    final suggestedProducts = msg.suggestedProductIds
        .map((id) => chatProvider.getCachedProduct(id))
        .whereType<Product>()
        .toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 40, top: 8, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Robot AI
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryOrange, AppColors.secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryBlue.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),

            // Bubble content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        topLeft: Radius.circular(4),
                      ),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Khối sản phẩm gợi ý đính kèm
                  if (suggestedProducts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 195,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestedProducts.length,
                        itemBuilder: (context, index) {
                          return _buildSuggestedProductCard(suggestedProducts[index], cart);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: AppColors.orangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primaryOrange, size: 16),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PRM Bot đang soạn câu trả lời...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final cart = context.watch<CartProvider>();
    final messages = chatProvider.messages;
    final isTyping = chatProvider.isTyping;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryOrange, AppColors.secondaryBlue],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'PRM TechBot AI',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.verified_rounded, size: 14, color: AppColors.secondaryBlue),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.accentMint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Trực tuyến 24/7 • Sẵn sàng tư vấn',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới cuộc trò chuyện',
            onPressed: _confirmClearHistory,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Chính sách cửa hàng',
            onPressed: () => _handleSend('Chính sách bảo hành và giao hàng của shop thế nào?'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 850,
        child: Column(
          children: [
            // Danh sách tin nhắn
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: messages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && isTyping) {
                    return _buildTypingIndicator();
                  }
                  final msg = messages[index];
                  return _buildMessageBubble(msg, chatProvider, cart);
                },
              ),
            ),

            // Gợi ý câu hỏi nhanh (Quick Prompt Chips)
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ChatProvider.quickSuggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: AppColors.surfaceWhite,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      label: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                      ),
                      onPressed: isTyping ? null : () => _handleSend(suggestion),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),

            // Thanh nhập tin nhắn
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                minLines: 1,
                                maxLines: 3,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _handleSend(),
                                decoration: const InputDecoration(
                                  hintText: 'Hỏi AI: Tư vấn điện thoại, laptop, mã giảm giá...',
                                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            if (_hasText)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                                onPressed: () => _textController.clear(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nút gửi tin nhắn
                    Material(
                      color: _hasText ? AppColors.primaryOrange : AppColors.borderLight,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: (_hasText && !isTyping) ? () => _handleSend() : null,
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          child: Icon(
                            Icons.send_rounded,
                            size: 19,
                            color: _hasText ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

