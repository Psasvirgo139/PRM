import '../models/product.dart';
import '../repositories/product_repository.dart';

class AiResponse {
  final String text;
  final List<int> suggestedProductIds;

  AiResponse(this.text, {this.suggestedProductIds = const []});
}

class AiChatService {
  final ProductRepository _productRepo;

  AiChatService({ProductRepository? productRepo})
      : _productRepo = productRepo ?? ProductRepository();

  Future<AiResponse> generateResponse(String userPrompt) async {
    final query = userPrompt.trim().toLowerCase();
    final allProducts = await _productRepo.getAllProducts();

    // ── 1. CHÀO HỎI & GIỚI THIỆU ──
    if (RegExp(r'\b(chào|hello|hi|hey|alo|bạn là ai|bot|trợ lý)\b').hasMatch(query) && query.length < 25) {
      return AiResponse(
        'Xin chào quý khách! 👋\n\n'
        'Tôi là **PRM TechBot** – Trợ lý ảo tư vấn công nghệ 24/7 của PRM Shop.\n\n'
        'Tôi có thể hỗ trợ bạn:\n'
        '• 📱 Tìm điện thoại, laptop, phụ kiện phù hợp túi tiền\n'
        '• ⚖️ So sánh thông số kỹ thuật các sản phẩm đối đầu\n'
        '• 🎟️ Cập nhật mã giảm giá & ưu đãi Vòng quay may mắn\n'
        '• 🛡️ Tra cứu chính sách bảo hành, đổi trả và giao hàng\n\n'
        'Bạn đang tìm kiếm thiết bị công nghệ nào hôm nay?',
      );
    }

    // ── 2. MÃ GIẢM GIÁ & VÒNG QUAY MAY MẮN ──
    if (query.contains('voucher') ||
        query.contains('mã giảm') ||
        query.contains('khuyến mãi') ||
        query.contains('ưu đãi') ||
        query.contains('vòng quay') ||
        query.contains('discount') ||
        query.contains('giảm giá')) {
      return AiResponse(
        '🎁 **ƯU ĐÃI & MÃ GIẢM GIÁ ĐANG ÁP DỤNG HÔM NAY:**\n\n'
        '1. ⚡ **Mã FREESHIP:** Miễn phí vận chuyển toàn quốc cho đơn hàng từ 500.000đ.\n'
        '2. 🎟️ **Mã TECH2026:** Giảm ngay 10% (tối đa 200.000đ) cho khách hàng lần đầu mua hàng.\n'
        '3. 🎡 **Vòng quay may mắn:** Mỗi ngày đăng nhập bạn nhận được **1 lượt quay miễn phí** trên Trang chủ với cơ hội rinh voucher **100k, 50k, 30k** hoặc Freeship!\n\n'
        '👉 Bạn có thể vào mục **"Ví Voucher"** hoặc nhấn banner **"Vòng quay may mắn"** ở Trang chủ để quay thưởng ngay nhé!',
      );
    }

    // ── 3. CHÍNH SÁCH BẢO HÀNH & GIAO HÀNG ──
    if (query.contains('bảo hành') ||
        query.contains('đổi trả') ||
        query.contains('giao hàng') ||
        query.contains('ship') ||
        query.contains('vận chuyển') ||
        query.contains('thanh toán') ||
        query.contains('trả góp')) {
      return AiResponse(
        '🛡️ **CHÍNH SÁCH BÁN HÀNG TẠI PRM SHOP:**\n\n'
        '• 🛡️ **Bảo hành:** Cam kết 100% hàng chính hãng VN/A, bảo hành toàn diện **12 tháng** tại các trung tâm ủy quyền chính thức.\n'
        '• 🔄 **Đổi mới:** Lỗi 1 đổi 1 trong vòng **30 ngày đầu tiên** nếu có lỗi từ nhà sản xuất.\n'
        '• 🚚 **Vận chuyển:**\n'
        '  - Giao hỏa tốc 2 giờ tại nội thành Hà Nội & TP.HCM.\n'
        '  - Giao tiêu chuẩn 1 - 3 ngày toàn quốc. Miễn phí vận chuyển đơn từ 500.000đ.\n'
        '• 💳 **Thanh toán:** Hỗ trợ nhận hàng thanh toán tiền mặt (COD), chuyển khoản ngân hàng và quét mã **VietQR / PayOS** siêu tiện lợi an toàn.\n\n'
        'Bạn có thắc mắc thêm về dòng máy nào cần tôi hỗ trợ không?',
      );
    }

    // ── 4. SO SÁNH SẢN PHẨM ──
    if (query.contains('so sánh') || query.contains('vs') || query.contains('nên mua') || query.contains('khác nhau')) {
      if (query.contains('iphone') && query.contains('samsung')) {
        final matches = _filterProducts(allProducts, ['iphone 15 pro max', 'samsung galaxy s24 ultra']);
        return AiResponse(
          '⚖️ **SO SÁNH: iPhone 15 Pro Max VS Samsung Galaxy S24 Ultra**\n\n'
          '• **iPhone 15 Pro Max:**\n'
          '  + Khung viền Titan nhẹ và bo cong êm tay.\n'
          '  + Chip A17 Pro hiệu năng đồ họa cực mạnh, hỗ trợ quay video ProRes Log chuyên nghiệp.\n'
          '  + Hệ điều hành iOS mượt mà, giữ giá tốt.\n\n'
          '• **Galaxy S24 Ultra:**\n'
          '  + Tích hợp bút S-Pen ghi chú và điều khiển từ xa.\n'
          '  + Bộ công cụ Galaxy AI (phiên dịch cuộc gọi, khoanh vùng tìm kiếm thông minh).\n'
          '  + Camera zoom tiềm vọng 100x và cảm biến chính 200MP.\n\n'
          '💡 *Lời khuyên:* Chọn **iPhone** nếu bạn thích hệ sinh thái Apple và quay phim; chọn **S24 Ultra** nếu bạn thích đa nhiệm, màn hình phẳng chống chói và bút S-Pen!\n\n'
          '👉 Bạn cũng có thể dùng tính năng **So sánh thông số đối đầu** trực tiếp trên thanh công cụ của app để xem chi tiết.',
          suggestedProductIds: matches.map((p) => p.id!).toList(),
        );
      }
    }

    // ── 5. TƯ VẤN LAPTOP ──
    if (query.contains('laptop') ||
        query.contains('máy tính') ||
        query.contains('macbook') ||
        query.contains('gaming') ||
        query.contains('đồ họa') ||
        query.contains('lập trình') ||
        query.contains('sinh viên')) {
      // Laptop Gaming / Đồ họa
      if (query.contains('gaming') || query.contains('chơi game') || query.contains('game')) {
        final matches = _filterProducts(allProducts, ['rog zephyrus', 'legion 5', 'katana 15']);
        return AiResponse(
          '🔥 **TOP LAPTOP GAMING & ĐỒ HỌA MẠNH MẼ NHẤT:**\n\n'
          '1. **Asus ROG Zephyrus G14 (2024):** Mỏng nhẹ cao cấp, màn hình OLED 120Hz 3K, RTX 4060 cân mọi tựa game AAA.\n'
          '2. **Lenovo Legion 5 Pro 16IRX9:** Màn hình 240Hz siêu mượt, chip Intel Gen 14th tản nhiệt cực mát.\n'
          '3. **MSI Katana 15:** Cấu hình Core i7 + RTX 4050 giá cực tốt trong phân khúc tầm trung.\n\n'
          'Dưới đây là các máy đang có sẵn hàng tại shop:',
          suggestedProductIds: matches.map((p) => p.id!).toList(),
        );
      }

      // Laptop Mỏng nhẹ / Học tập / Lập trình
      final matches = _filterProducts(allProducts, ['macbook air m3', 'dell xps 13', 'zenbook 14', 'swift go']);
      return AiResponse(
        '💻 **GỢI Ý LAPTOP MỎNG NHẸ, PIN TRÂU CHO LẬP TRÌNH & VĂN PHÒNG:**\n\n'
        '1. **MacBook Air M3 13 inch:** Pin dùng cả ngày 18 tiếng, mỏng 1.24kg, chạy mượt mà mọi tác vụ văn phòng và code.\n'
        '2. **Dell XPS 13 9340 (2024):** Đỉnh cao thiết kế doanh nhân, màn hình OLED 3K cảm ứng siêu nét.\n'
        '3. **Asus Zenbook 14 OLED:** Màn hình OLED chuẩn màu 100% DCI-P3, pin lớn 75Wh, giá cực kỳ hợp lý.\n'
        '4. **Acer Swift Go 14 OLED:** Trang bị chip Intel Core Ultra AI thế hệ mới, mỏng nhẹ 1.3kg.\n\n'
        'Xem ngay chi tiết các sản phẩm bên dưới:',
        suggestedProductIds: matches.map((p) => p.id!).toList(),
      );
    }

    // ── 6. TƯ VẤN ĐIỆN THOẠI ──
    if (query.contains('điện thoại') ||
        query.contains('phone') ||
        query.contains('iphone') ||
        query.contains('samsung') ||
        query.contains('xiaomi') ||
        query.contains('chụp ảnh')) {
      // Dưới 15 - 20 triệu hoặc giá mềm
      if (query.contains('dưới 10') || query.contains('dưới 15') || query.contains('giá rẻ') || query.contains('tầm trung')) {
        final matches = _filterProducts(allProducts, ['redmi note 13', 'iphone 14 plus', 'galaxy z flip5']);
        return AiResponse(
          '📱 **ĐIỆN THOẠI TẦM TRUNG - GIÁ CỰC TỐT ĐÁNG MUA NHẤT:**\n\n'
          '1. **Xiaomi Redmi Note 13 Pro+:** Camera 200MP OIS, sạc siêu tốc 120W chỉ 19 phút, màn hình cong 1.5K.\n'
          '2. **Samsung Galaxy Z Flip5:** Màn hình ngoài lớn Flex Window, gập mở vỏ sò độc đáo, giá đang giảm sâu.\n'
          '3. **iPhone 14 Plus 128GB:** Màn hình 6.7 inch rộng rãi, thời lượng pin trâu nhất phân khúc.\n\n'
          'Bạn có thể tham khảo trực tiếp các mẫu sau:',
          suggestedProductIds: matches.map((p) => p.id!).toList(),
        );
      }

      // Flagship cao cấp / Chụp ảnh đỉnh cao
      final matches = _filterProducts(allProducts, ['iphone 15 pro max', 'samsung galaxy s24 ultra', 'xiaomi 14 ultra', 'pixel 8 pro']);
      return AiResponse(
        '🌟 **TOP FLAGSHIP CHỤP ẢNH & HIỆU NĂNG ĐỈNH CAO NHẤT:**\n\n'
        '1. **iPhone 15 Pro Max 256GB:** Khung viền Titan siêu nhẹ, camera tele zoom quang 5x sắc nét, quay phim chuyên nghiệp.\n'
        '2. **Samsung Galaxy S24 Ultra:** Camera 200MP, zoom quang học 100x và bộ công cụ Galaxy AI đỉnh cao.\n'
        '3. **Xiaomi 14 Ultra 512GB:** Cụm 4 camera Leica cảm biến lớn 1 inch, khẩu độ vô cấp cho ảnh chụp nghệ thuật.\n'
        '4. **Google Pixel 8 Pro:** Thuật toán xử lý ảnh thông minh độc quyền từ Google, xóa vật thể bằng AI.\n\n'
        'Dưới đây là các sản phẩm chính hãng đang có khuyến mãi tại shop:',
        suggestedProductIds: matches.map((p) => p.id!).toList(),
      );
    }

    // ── 7. TƯ VẤN PHỤ KIỆN (TAI NGHE, BÀN PHÍM, CHUỘT, SẠC) ──
    if (query.contains('phụ kiện') ||
        query.contains('tai nghe') ||
        query.contains('bàn phím') ||
        query.contains('chuột') ||
        query.contains('sạc') ||
        query.contains('pin') ||
        query.contains('đồng hồ') ||
        query.contains('watch')) {
      if (query.contains('tai nghe') || query.contains('chống ồn') || query.contains('loa')) {
        final matches = _filterProducts(allProducts, ['airpods pro 2', 'wh-1000xm5', 'marshall emberton']);
        return AiResponse(
          '🎧 **TOP TAI NGHE & LOA ÂM THANH ĐỈNH CAO:**\n\n'
          '1. **AirPods Pro 2 USB-C:** Chống ồn chủ động gấp 2 lần, kết nối tức thì cho iPhone/Mac, cổng sạc Type-C tiện dụng.\n'
          '2. **Sony WH-1000XM5:** Đỉnh cao chống ồn trùm đầu số 1 thế giới, pin 30 giờ, đàm thoại AI lọc gió trong trẻo.\n'
          '3. **Loa Marshall Emberton II:** Thiết kế cổ điển sang trọng, âm thanh 360 độ True Stereophonic, kháng nước IP67.\n\n'
          'Mời bạn xem chi tiết sản phẩm:',
          suggestedProductIds: matches.map((p) => p.id!).toList(),
        );
      }

      if (query.contains('bàn phím') || query.contains('chuột')) {
        final matches = _filterProducts(allProducts, ['keychron k2', 'mx master 3s', 'magic keyboard', 'g pro x superlight']);
        return AiResponse(
          '⌨️ **BÀN PHÍM CƠ & CHUỘT CÔNG THÁI HỌC TỐT NHẤT:**\n\n'
          '1. **Keychron K2:** Bàn phím cơ gõ êm, kết nối Bluetooth cùng lúc 3 thiết bị Mac/Windows/iPad.\n'
          '2. **Logitech MX Master 3S:** Chuột công thái học cao cấp, con lăn MagSpeed siêu mượt, giảm 90% tiếng ồn.\n'
          '3. **Logitech G Pro X Superlight:** Chuột gaming siêu nhẹ dưới 63g, độ chính xác tuyệt đối cho game thủ.\n\n'
          'Danh sách phụ kiện chính hãng tại shop:',
          suggestedProductIds: matches.map((p) => p.id!).toList(),
        );
      }

      // Phụ kiện chung: Sạc, pin, đồng hồ
      final matches = _filterProducts(allProducts, ['anker 735', 'anker 622', 'apple watch series 9', 'galaxy watch 6']);
      return AiResponse(
        '⚡ **PHỤ KIỆN CÔNG NGHỆ CHÍNH HÃNG NỔI BẬT:**\n\n'
        '• **Củ sạc Anker GaNPrime 65W:** Sạc nhanh 3 thiết bị cùng lúc, công nghệ GaN III siêu nhỏ gọn.\n'
        '• **Pin sạc MagSafe Anker 622:** Hít nam châm từ tính tiện lợi, tích hợp giá đỡ xem phim.\n'
        '• **Apple Watch Series 9 & Galaxy Watch 6:** Theo dõi sức khỏe, điện tâm đồ ECG và nhận thông báo thông minh.\n\n'
        'Các phụ kiện đang có ưu đãi:',
        suggestedProductIds: matches.map((p) => p.id!).toList(),
      );
    }

    // ── 8. TÌM KIẾM THEO TÊN SẢN PHẨM CỤ THỂ ──
    final matchedByKeyword = allProducts.where((p) {
      final nameLower = p.name.toLowerCase();
      return nameLower.contains(query) || query.split(' ').any((word) => word.length > 2 && nameLower.contains(word));
    }).take(4).toList();

    if (matchedByKeyword.isNotEmpty) {
      final names = matchedByKeyword.map((p) => '• **${p.name}**').join('\n');
      return AiResponse(
        '🔍 Tôi đã tìm thấy các sản phẩm phù hợp với yêu cầu của bạn tại PRM Shop:\n\n'
        '$names\n\n'
        'Bạn có thể bấm vào thẻ sản phẩm bên dưới để xem thông số chi tiết hoặc thêm vào giỏ hàng nhé:',
        suggestedProductIds: matchedByKeyword.map((p) => p.id!).toList(),
      );
    }

    // ── 9. PHẢN HỒI MẶC ĐỊNH HỮU ÍCH ──
    final popularProducts = allProducts.take(4).toList();
    return AiResponse(
      'Cảm ơn bạn đã nhắn tin cho PRM Shop! 🤖\n\n'
      'Tôi có thể hỗ trợ bạn tìm kiếm bất kỳ sản phẩm nào về **Điện thoại**, **Laptop** hoặc **Phụ kiện công nghệ**.\n\n'
      '💡 **Bạn có thể thử hỏi tôi các câu như:**\n'
      '• *"Tư vấn điện thoại chụp ảnh đẹp"* \n'
      '• *"Laptop mỏng nhẹ pin trâu cho sinh viên"* \n'
      '• *"Mã giảm giá hôm nay có gì?"* \n'
      '• *"Chính sách bảo hành đổi trả của shop"* \n\n'
      'Dưới đây là một số thiết bị công nghệ bán chạy hàng đầu tại shop:',
      suggestedProductIds: popularProducts.map((p) => p.id!).toList(),
    );
  }

  List<Product> _filterProducts(List<Product> all, List<String> keywords) {
    final List<Product> result = [];
    for (final kw in keywords) {
      for (final p in all) {
        if (p.name.toLowerCase().contains(kw) && !result.any((item) => item.id == p.id)) {
          result.add(p);
          break;
        }
      }
    }
    return result;
  }
}

