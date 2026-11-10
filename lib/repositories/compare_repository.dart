import 'package:flutter/material.dart';

import '../core/database/database_helper.dart';
import '../models/product.dart';
import '../models/product_spec.dart';

class CompareRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Lấy toàn bộ thông số chi tiết của sản phẩm theo ID
  Future<ProductSpecs> getProductSpecs(Product product) async {
    // 1. Kiểm tra nếu có dữ liệu cấu hình thông số chuẩn
    final knownSpecs = _getKnownProductSpecs(product);
    if (knownSpecs != null) {
      return knownSpecs;
    }

    // 2. Tự động sinh thông số thông minh dựa trên danh mục & tên sản phẩm
    return _generateDynamicSpecs(product);
  }

  /// Lấy danh sách sản phẩm có thể so sánh cùng phân khúc/danh mục
  Future<List<Product>> getComparableProducts({
    int? categoryId,
    int? excludeProductId,
    String? searchQuery,
  }) async {
    final db = await _dbHelper.database;
    String whereClause = '1 = 1';
    final List<dynamic> whereArgs = [];

    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    if (excludeProductId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeProductId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR description LIKE ?)';
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final rows = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'price DESC',
    );

    return rows.map((r) => Product.fromMap(r)).toList();
  }

  /// Dữ liệu thông số chi tiết mô hình hóa chuẩn xác cho các thiết bị flagship
  ProductSpecs? _getKnownProductSpecs(Product product) {
    final nameLower = product.name.toLowerCase();

    // 1. iPhone 15 Pro Max
    if (nameLower.contains('iphone 15 pro max')) {
      return ProductSpecs(
        productId: product.id ?? 1,
        productName: product.name,
        categoryName: 'Điện thoại',
        groups: [
          const SpecGroup(
            id: 'perf',
            name: 'Hiệu năng & Vi xử lý',
            icon: Icons.memory_rounded,
            items: [
              SpecItem(
                key: 'chip',
                label: 'Vi xử lý (CPU/Chip)',
                value: 'Apple A17 Pro (3nm, 6 nhân CPU, 6 nhân GPU)',
                numericValue: 3.0,
                unit: 'nm',
                isHigherBetter: false, // 3nm nhỏ hơn, tiến trình tiên tiến hơn
              ),
              SpecItem(
                key: 'ram',
                label: 'Dung lượng RAM',
                value: '8 GB LPDDR5X',
                numericValue: 8.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'rom',
                label: 'Bộ nhớ trong (ROM)',
                value: '256 GB NVMe',
                numericValue: 256.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ai',
                label: 'Nhân xử lý AI/Neural',
                value: '16 nhân Neural Engine (35 TOPS)',
                numericValue: 35.0,
                unit: 'TOPS',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'display',
            name: 'Màn hình & Hiển thị',
            icon: Icons.smartphone_rounded,
            items: [
              SpecItem(
                key: 'screen_size',
                label: 'Kích thước màn hình',
                value: '6.7 inch Super Retina XDR',
                numericValue: 6.7,
                unit: 'inch',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'panel',
                label: 'Công nghệ tấm nền',
                value: 'OLED (Super Retina XDR, Dynamic Island)',
              ),
              SpecItem(
                key: 'refresh_rate',
                label: 'Tần số quét',
                value: '120 Hz ProMotion tự thích ứng 1-120Hz',
                numericValue: 120.0,
                unit: 'Hz',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'brightness',
                label: 'Độ sáng tối đa',
                value: '2.000 nits (ngoài trời)',
                numericValue: 2000.0,
                unit: 'nits',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'resolution',
                label: 'Độ phân giải',
                value: '2796 x 1290 pixels (460 ppi)',
                numericValue: 460.0,
                unit: 'ppi',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'camera',
            name: 'Camera & Nhiếp ảnh',
            icon: Icons.camera_alt_rounded,
            items: [
              SpecItem(
                key: 'rear_camera',
                label: 'Camera chính (Sau)',
                value: '48 MP (f/1.78, OIS dịch chuyển cảm biến)',
                numericValue: 48.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'tele_camera',
                label: 'Camera Telephoto',
                value: '12 MP tiềm vọng tetraprism zoom quang 5x',
                numericValue: 5.0,
                unit: 'x',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ultra_wide',
                label: 'Camera góc siêu rộng',
                value: '12 MP (120 độ, f/2.2)',
                numericValue: 12.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'front_camera',
                label: 'Camera selfie (Trước)',
                value: '12 MP TrueDepth tự động lấy nét',
                numericValue: 12.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'video',
                label: 'Quay video tối đa',
                value: '4K ProRes 60fps qua USB-C, Log video',
              ),
            ],
          ),
          const SpecGroup(
            id: 'battery',
            name: 'Pin & Sạc nhanh',
            icon: Icons.battery_charging_full_rounded,
            items: [
              SpecItem(
                key: 'battery_cap',
                label: 'Dung lượng pin',
                value: '4.422 mAh',
                numericValue: 4422.0,
                unit: 'mAh',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'fast_charge',
                label: 'Công suất sạc nhanh',
                value: '20W có dây (50% trong 30 phút)',
                numericValue: 20.0,
                unit: 'W',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'wireless_charge',
                label: 'Sạc không dây',
                value: '15W MagSafe / Qi2',
                numericValue: 15.0,
                unit: 'W',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'design',
            name: 'Thiết kế, Độ bền & Hệ điều hành',
            icon: Icons.design_services_rounded,
            items: [
              SpecItem(
                key: 'weight',
                label: 'Trọng lượng máy',
                value: '221 g',
                numericValue: 221.0,
                unit: 'g',
                isHigherBetter: false, // Máy càng nhẹ càng thoải mái cầm nắm
              ),
              SpecItem(
                key: 'material',
                label: 'Chất liệu khung viền',
                value: 'Titanium Grade 5 siêu nhẹ & bền bỉ',
              ),
              SpecItem(
                key: 'waterproof',
                label: 'Chuẩn chống nước/bụi',
                value: 'IP68 (ngâm nước sâu 6m trong 30 phút)',
              ),
              SpecItem(
                key: 'os',
                label: 'Hệ điều hành',
                value: 'iOS 17 (Hỗ trợ cập nhật 5+ năm)',
              ),
              SpecItem(
                key: 'port',
                label: 'Cổng kết nối',
                value: 'USB-C 3.2 Gen 2 (Tốc độ lên tới 10Gbps)',
              ),
            ],
          ),
        ],
      );
    }

    // 2. Samsung Galaxy S24 Ultra
    if (nameLower.contains('galaxy s24 ultra') || nameLower.contains('s24 ultra')) {
      return ProductSpecs(
        productId: product.id ?? 2,
        productName: product.name,
        categoryName: 'Điện thoại',
        groups: [
          const SpecGroup(
            id: 'perf',
            name: 'Hiệu năng & Vi xử lý',
            icon: Icons.memory_rounded,
            items: [
              SpecItem(
                key: 'chip',
                label: 'Vi xử lý (CPU/Chip)',
                value: 'Snapdragon 8 Gen 3 for Galaxy (4nm, 8 nhân)',
                numericValue: 4.0,
                unit: 'nm',
                isHigherBetter: false,
              ),
              SpecItem(
                key: 'ram',
                label: 'Dung lượng RAM',
                value: '12 GB LPDDR5X',
                numericValue: 12.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'rom',
                label: 'Bộ nhớ trong (ROM)',
                value: '256 GB UFS 4.0',
                numericValue: 256.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ai',
                label: 'Nhân xử lý AI/Neural',
                value: 'NPU Qualcomm cải tiến (Galaxy AI đa năng)',
                numericValue: 45.0,
                unit: 'TOPS',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'display',
            name: 'Màn hình & Hiển thị',
            icon: Icons.smartphone_rounded,
            items: [
              SpecItem(
                key: 'screen_size',
                label: 'Kích thước màn hình',
                value: '6.8 inch Dynamic AMOLED 2X',
                numericValue: 6.8,
                unit: 'inch',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'panel',
                label: 'Công nghệ tấm nền',
                value: 'Dynamic AMOLED 2X, Kính Corning Armor chống chói 75%',
              ),
              SpecItem(
                key: 'refresh_rate',
                label: 'Tần số quét',
                value: '120 Hz LTPO (tự điều chỉnh 1-120Hz)',
                numericValue: 120.0,
                unit: 'Hz',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'brightness',
                label: 'Độ sáng tối đa',
                value: '2.600 nits (cực đại)',
                numericValue: 2600.0,
                unit: 'nits',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'resolution',
                label: 'Độ phân giải',
                value: 'Quad HD+ 3120 x 1440 pixels (505 ppi)',
                numericValue: 505.0,
                unit: 'ppi',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'camera',
            name: 'Camera & Nhiếp ảnh',
            icon: Icons.camera_alt_rounded,
            items: [
              SpecItem(
                key: 'rear_camera',
                label: 'Camera chính (Sau)',
                value: '200 MP (f/1.7, OIS góc rộng)',
                numericValue: 200.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'tele_camera',
                label: 'Camera Telephoto',
                value: '50 MP zoom quang 5x + 10 MP zoom quang 3x (100x Space Zoom)',
                numericValue: 50.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ultra_wide',
                label: 'Camera góc siêu rộng',
                value: '12 MP (120 độ, f/2.2)',
                numericValue: 12.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'front_camera',
                label: 'Camera selfie (Trước)',
                value: '12 MP Dual Pixel PDAF',
                numericValue: 12.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'video',
                label: 'Quay video tối đa',
                value: '8K 30fps / 4K 120fps siêu mượt',
              ),
            ],
          ),
          const SpecGroup(
            id: 'battery',
            name: 'Pin & Sạc nhanh',
            icon: Icons.battery_charging_full_rounded,
            items: [
              SpecItem(
                key: 'battery_cap',
                label: 'Dung lượng pin',
                value: '5.000 mAh',
                numericValue: 5000.0,
                unit: 'mAh',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'fast_charge',
                label: 'Công suất sạc nhanh',
                value: '45W có dây (65% trong 30 phút)',
                numericValue: 45.0,
                unit: 'W',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'wireless_charge',
                label: 'Sạc không dây',
                value: '15W Fast Wireless + Sạc ngược 4.5W',
                numericValue: 15.0,
                unit: 'W',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'design',
            name: 'Thiết kế, Độ bền & Hệ điều hành',
            icon: Icons.design_services_rounded,
            items: [
              SpecItem(
                key: 'weight',
                label: 'Trọng lượng máy',
                value: '232 g',
                numericValue: 232.0,
                unit: 'g',
                isHigherBetter: false,
              ),
              SpecItem(
                key: 'material',
                label: 'Chất liệu khung viền',
                value: 'Titanium bền bỉ & Kính cường lực Gorilla Armor',
              ),
              SpecItem(
                key: 'waterproof',
                label: 'Chuẩn chống nước/bụi',
                value: 'IP68 (ngâm nước 1.5m trong 30 phút)',
              ),
              SpecItem(
                key: 'os',
                label: 'Hệ điều hành',
                value: 'Android 14, One UI 6.1 (Cam kết cập nhật 7 năm)',
              ),
              SpecItem(
                key: 'special',
                label: 'Tính năng đặc biệt',
                value: 'Bút S-Pen tích hợp trong thân máy, Galaxy AI dịch trực tiếp',
              ),
            ],
          ),
        ],
      );
    }

    // 3. Xiaomi 14 Ultra
    if (nameLower.contains('xiaomi 14 ultra') || nameLower.contains('xiaomi 14')) {
      return ProductSpecs(
        productId: product.id ?? 7,
        productName: product.name,
        categoryName: 'Điện thoại',
        groups: [
          const SpecGroup(
            id: 'perf',
            name: 'Hiệu năng & Vi xử lý',
            icon: Icons.memory_rounded,
            items: [
              SpecItem(
                key: 'chip',
                label: 'Vi xử lý (CPU/Chip)',
                value: 'Snapdragon 8 Gen 3 (4nm, Tản nhiệt buồng hơi lỏng kép)',
                numericValue: 4.0,
                unit: 'nm',
                isHigherBetter: false,
              ),
              SpecItem(
                key: 'ram',
                label: 'Dung lượng RAM',
                value: '16 GB LPDDR5X',
                numericValue: 16.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'rom',
                label: 'Bộ nhớ trong (ROM)',
                value: '512 GB UFS 4.0',
                numericValue: 512.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ai',
                label: 'Nhân xử lý AI/Neural',
                value: 'NPU Qualcomm AI Engine thế hệ mới',
                numericValue: 45.0,
                unit: 'TOPS',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'display',
            name: 'Màn hình & Hiển thị',
            icon: Icons.smartphone_rounded,
            items: [
              SpecItem(
                key: 'screen_size',
                label: 'Kích thước màn hình',
                value: '6.73 inch LTPO AMOLED C8',
                numericValue: 6.73,
                unit: 'inch',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'panel',
                label: 'Công nghệ tấm nền',
                value: 'AMOLED 68 tỷ màu, Dolby Vision, HDR10+',
              ),
              SpecItem(
                key: 'refresh_rate',
                label: 'Tần số quét',
                value: '120 Hz LTPO thích ứng mượt mà',
                numericValue: 120.0,
                unit: 'Hz',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'brightness',
                label: 'Độ sáng tối đa',
                value: '3.000 nits đỉnh cao ngoài trời',
                numericValue: 3000.0,
                unit: 'nits',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'resolution',
                label: 'Độ phân giải',
                value: 'WQHD+ 3200 x 1440 pixels (522 ppi)',
                numericValue: 522.0,
                unit: 'ppi',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'camera',
            name: 'Camera & Nhiếp ảnh',
            icon: Icons.camera_alt_rounded,
            items: [
              SpecItem(
                key: 'rear_camera',
                label: 'Camera chính (Sau)',
                value: '50 MP cảm biến 1-inch Sony LYT-900 (Khẩu độ biến thiên f/1.63 - f/4.0)',
                numericValue: 50.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'tele_camera',
                label: 'Camera Telephoto',
                value: '50 MP zoom 3.2x + 50 MP tiềm vọng zoom 5x Leica',
                numericValue: 50.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ultra_wide',
                label: 'Camera góc siêu rộng',
                value: '50 MP Leica (122 độ, chụp Macro 5cm)',
                numericValue: 50.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'front_camera',
                label: 'Camera selfie (Trước)',
                value: '32 MP góc rộng 4K',
                numericValue: 32.0,
                unit: 'MP',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'video',
                label: 'Quay video tối đa',
                value: '8K 30fps trên cả 4 camera sau, 4K 120fps',
              ),
            ],
          ),
          const SpecGroup(
            id: 'battery',
            name: 'Pin & Sạc nhanh',
            icon: Icons.battery_charging_full_rounded,
            items: [
              SpecItem(
                key: 'battery_cap',
                label: 'Dung lượng pin',
                value: '5.000 mAh công nghệ Silicon-Carbon',
                numericValue: 5000.0,
                unit: 'mAh',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'fast_charge',
                label: 'Công suất sạc nhanh',
                value: '90W HyperCharge có dây (100% trong 33 phút)',
                numericValue: 90.0,
                unit: 'W',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'wireless_charge',
                label: 'Sạc không dây',
                value: '80W Không dây siêu tốc (100% trong 46 phút)',
                numericValue: 80.0,
                unit: 'W',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'design',
            name: 'Thiết kế, Độ bền & Hệ điều hành',
            icon: Icons.design_services_rounded,
            items: [
              SpecItem(
                key: 'weight',
                label: 'Trọng lượng máy',
                value: '219.8 g',
                numericValue: 219.8,
                unit: 'g',
                isHigherBetter: false,
              ),
              SpecItem(
                key: 'material',
                label: 'Chất liệu khung viền',
                value: 'Khung nhôm nguyên khối gia cường 6M42 & Da sinh học Nano',
              ),
              SpecItem(
                key: 'waterproof',
                label: 'Chuẩn chống nước/bụi',
                value: 'IP68 bền bỉ',
              ),
              SpecItem(
                key: 'os',
                label: 'Hệ điều hành',
                value: 'Xiaomi HyperOS (nền tảng Android 14)',
              ),
              SpecItem(
                key: 'special',
                label: 'Tính năng đặc biệt',
                value: 'Hệ thống quang học Leica Summilux cao cấp bậc nhất thế giới',
              ),
            ],
          ),
        ],
      );
    }

    // 4. MacBook Air M3
    if (nameLower.contains('macbook air') || nameLower.contains('macbook')) {
      return ProductSpecs(
        productId: product.id ?? 3,
        productName: product.name,
        categoryName: 'Laptop',
        groups: [
          const SpecGroup(
            id: 'perf',
            name: 'Hiệu năng & Vi xử lý',
            icon: Icons.laptop_chromebook_rounded,
            items: [
              SpecItem(
                key: 'chip',
                label: 'Bộ vi xử lý (CPU)',
                value: 'Apple M3 (8 nhân CPU, 10 nhân GPU, Ray Tracing phần cứng)',
                numericValue: 8.0,
                unit: 'nhân',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ram',
                label: 'Dung lượng RAM',
                value: '16 GB Unified Memory (Băng thông 100GB/s)',
                numericValue: 16.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ssd',
                label: 'Ổ cứng lưu trữ SSD',
                value: '512 GB SSD NVMe siêu tốc',
                numericValue: 512.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ai',
                label: 'Bộ xử lý thần kinh NPU',
                value: '16 nhân Neural Engine (18 TOPS)',
                numericValue: 18.0,
                unit: 'TOPS',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'display',
            name: 'Màn hình & Đồ họa',
            icon: Icons.monitor_rounded,
            items: [
              SpecItem(
                key: 'screen_size',
                label: 'Kích thước màn hình',
                value: '13.6 inch Liquid Retina viền mỏng',
                numericValue: 13.6,
                unit: 'inch',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'resolution',
                label: 'Độ phân giải',
                value: '2560 x 1664 pixels (224 ppi), 1 tỷ màu P3',
                numericValue: 224.0,
                unit: 'ppi',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'brightness',
                label: 'Độ sáng màn hình',
                value: '500 nits, công nghệ True Tone',
                numericValue: 500.0,
                unit: 'nits',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ext_monitor',
                label: 'Xuất màn hình ngoài',
                value: 'Hỗ trợ tối đa 2 màn hình ngoài khi gập máy',
              ),
            ],
          ),
          const SpecGroup(
            id: 'battery',
            name: 'Thời lượng Pin & Sạc',
            icon: Icons.battery_charging_full_rounded,
            items: [
              SpecItem(
                key: 'battery_life',
                label: 'Thời lượng pin thực tế',
                value: 'Lên tới 18 giờ phát video / 15 giờ lướt web',
                numericValue: 18.0,
                unit: 'giờ',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'battery_wh',
                label: 'Dung lượng pin (Wh)',
                value: '52.6 Wh Lithium-polymer',
                numericValue: 52.6,
                unit: 'Wh',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'charging_port',
                label: 'Cổng sạc & Công suất',
                value: 'Cổng sạc MagSafe 3 hít từ tính tiện lợi, sạc nhanh 70W',
                numericValue: 70.0,
                unit: 'W',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'design',
            name: 'Kích thước, Trọng lượng & Kết nối',
            icon: Icons.devices_rounded,
            items: [
              SpecItem(
                key: 'weight',
                label: 'Trọng lượng máy',
                value: '1.24 kg (siêu mỏng 1.13 cm)',
                numericValue: 1.24,
                unit: 'kg',
                isHigherBetter: false,
              ),
              SpecItem(
                key: 'material',
                label: 'Chất liệu vỏ máy',
                value: '100% Nhôm tái chế nguyên khối cao cấp',
              ),
              SpecItem(
                key: 'ports',
                label: 'Cổng kết nối',
                value: '2x Thunderbolt 4 / USB-C, Jack 3.5mm tai nghe, MagSafe 3',
              ),
              SpecItem(
                key: 'os',
                label: 'Hệ điều hành',
                value: 'macOS Sonoma mượt mà, bảo mật cao',
              ),
            ],
          ),
        ],
      );
    }

    // 5. Dell XPS 13
    if (nameLower.contains('dell xps') || nameLower.contains('xps 13')) {
      return ProductSpecs(
        productId: product.id ?? 8,
        productName: product.name,
        categoryName: 'Laptop',
        groups: [
          const SpecGroup(
            id: 'perf',
            name: 'Hiệu năng & Vi xử lý',
            icon: Icons.laptop_chromebook_rounded,
            items: [
              SpecItem(
                key: 'chip',
                label: 'Bộ vi xử lý (CPU)',
                value: 'Intel Core Ultra 7 155H (16 nhân, 22 luồng, Intel Arc)',
                numericValue: 16.0,
                unit: 'nhân',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ram',
                label: 'Dung lượng RAM',
                value: '16 GB LPDDR5X 7467MHz',
                numericValue: 16.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ssd',
                label: 'Ổ cứng lưu trữ SSD',
                value: '512 GB PCIe 4.0 NVMe',
                numericValue: 512.0,
                unit: 'GB',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'ai',
                label: 'Bộ xử lý thần kinh NPU',
                value: 'Intel AI Boost NPU chuyên dụng',
                numericValue: 34.0,
                unit: 'TOPS',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'display',
            name: 'Màn hình & Đồ họa',
            icon: Icons.monitor_rounded,
            items: [
              SpecItem(
                key: 'screen_size',
                label: 'Kích thước màn hình',
                value: '13.4 inch OLED 3K Cảm ứng',
                numericValue: 13.4,
                unit: 'inch',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'resolution',
                label: 'Độ phân giải',
                value: '3K 2880 x 1800 pixels (100% DCI-P3)',
                numericValue: 255.0,
                unit: 'ppi',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'brightness',
                label: 'Độ sáng màn hình',
                value: '500 nits, kính cường lực Gorilla Glass 3',
                numericValue: 500.0,
                unit: 'nits',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'battery',
            name: 'Thời lượng Pin & Sạc',
            icon: Icons.battery_charging_full_rounded,
            items: [
              SpecItem(
                key: 'battery_life',
                label: 'Thời lượng pin thực tế',
                value: 'Khoảng 12 giờ làm việc văn phòng',
                numericValue: 12.0,
                unit: 'giờ',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'battery_wh',
                label: 'Dung lượng pin (Wh)',
                value: '55 Wh ExpressCharge',
                numericValue: 55.0,
                unit: 'Wh',
                isHigherBetter: true,
              ),
              SpecItem(
                key: 'charging_port',
                label: 'Cổng sạc & Công suất',
                value: 'Sạc Type-C PD 60W',
                numericValue: 60.0,
                unit: 'W',
                isHigherBetter: true,
              ),
            ],
          ),
          const SpecGroup(
            id: 'design',
            name: 'Kích thước, Trọng lượng & Kết nối',
            icon: Icons.devices_rounded,
            items: [
              SpecItem(
                key: 'weight',
                label: 'Trọng lượng máy',
                value: '1.19 kg (siêu gọn nhẹ)',
                numericValue: 1.19,
                unit: 'kg',
                isHigherBetter: false,
              ),
              SpecItem(
                key: 'material',
                label: 'Chất liệu vỏ máy',
                value: 'Nhôm CNC phay tinh xảo & Touchpad tàng hình',
              ),
              SpecItem(
                key: 'os',
                label: 'Hệ điều hành',
                value: 'Windows 11 Home bản quyền',
              ),
            ],
          ),
        ],
      );
    }

    return null;
  }

  /// Tự động sinh thông số thông minh cho bất kỳ sản phẩm nào khác
  ProductSpecs _generateDynamicSpecs(Product product) {
    final catId = product.categoryId ?? 3;
    final catName = catId == 1
        ? 'Điện thoại'
        : catId == 2
            ? 'Laptop'
            : 'Phụ kiện công nghệ';

    return ProductSpecs(
      productId: product.id ?? 0,
      productName: product.name,
      categoryName: catName,
      groups: [
        SpecGroup(
          id: 'general',
          name: 'Thông tin chung & Giá bán',
          icon: Icons.info_outline_rounded,
          items: [
            SpecItem(
              key: 'brand_type',
              label: 'Phân khúc thiết bị',
              value: product.price > 20000000
                  ? 'Cao cấp (Flagship)'
                  : product.price > 5000000
                      ? 'Tầm trung cận cao cấp'
                      : 'Phổ thông / Phụ kiện',
            ),
            SpecItem(
              key: 'stock',
              label: 'Tình trạng kho hàng',
              value: product.stockQuantity > 0 ? 'Còn hàng (${product.stockQuantity} món)' : 'Tạm hết hàng',
              numericValue: product.stockQuantity.toDouble(),
              unit: 'món',
              isHigherBetter: true,
            ),
            SpecItem(
              key: 'warranty',
              label: 'Chế độ bảo hành',
              value: '12 tháng chính hãng 1 đổi 1 trong 30 ngày',
            ),
          ],
        ),
        SpecGroup(
          id: 'features',
          name: 'Đặc tính kỹ thuật chính',
          icon: Icons.featured_play_list_rounded,
          items: [
            SpecItem(
              key: 'main_feature',
              label: 'Tính năng cốt lõi',
              value: product.description.isNotEmpty ? product.description : 'Thiết bị công nghệ tiêu chuẩn',
            ),
            const SpecItem(
              key: 'connectivity',
              label: 'Chuẩn kết nối',
              value: 'Bluetooth 5.3 / USB-C / Không dây đa nền tảng',
            ),
            const SpecItem(
              key: 'build_quality',
              label: 'Độ hoàn thiện',
              value: 'Gia công cao cấp, kiểm định chất lượng nghiêm ngặt',
            ),
          ],
        ),
      ],
    );
  }
}

