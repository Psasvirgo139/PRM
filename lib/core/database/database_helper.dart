import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shop_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    // Đảm bảo bổ sung các thiết bị demo so sánh đối đầu nếu chưa có
    try {
      final res = await db.query('products', where: 'name LIKE ?', whereArgs: ['%Xiaomi 14 Ultra%']);
      if (res.isEmpty) {
        final now = DateTime.now().toIso8601String();
        await db.insert('products', {
          'category_id': 1,
          'name': 'Xiaomi 14 Ultra 512GB',
          'description': 'Camera Leica Summilux cảm biến 1 inch, chip Snapdragon 8 Gen 3, sạc siêu nhanh 90W.',
          'price': 24990000.0,
          'stock_quantity': 10,
          'image_url': 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=500',
          'created_at': now,
        });
        await db.insert('products', {
          'category_id': 2,
          'name': 'Dell XPS 13 9340 (2024)',
          'description': 'Intel Core Ultra 7, màn hình 13.4 inch OLED 3K cảm ứng, phím tàng hình sang trọng, 1.19kg.',
          'price': 34990000.0,
          'stock_quantity': 6,
          'image_url': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=500',
          'created_at': now,
        });
        await db.insert('products', {
          'category_id': 2,
          'name': 'Asus ROG Zephyrus G14 (2024)',
          'description': 'Ryzen 9 8945HS, RTX 4060, 32GB RAM, màn hình OLED 120Hz 3K Nebula, thiết kế nhôm CNC.',
          'price': 39990000.0,
          'stock_quantity': 4,
          'image_url': 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=500',
          'created_at': now,
        });
      }
    } catch (_) {}
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users (Hỗ trợ phân quyền Admin, Employee và Customer)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        role TEXT NOT NULL DEFAULT 'CUSTOMER',
        avatar_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT
      )
    ''');

    // 3. Products
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        image_url TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 4. Cart Items (Gắn liền với từng User)
    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        UNIQUE(user_id, product_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 5. Orders (Đơn hàng thuộc về User)
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        order_code TEXT UNIQUE NOT NULL,
        customer_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        note TEXT,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0,
        shipping_fee REAL DEFAULT 0,
        final_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 6. Order Items
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // 7. Notifications (Thông báo cho Customer, Employee, Admin)
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'ORDER',
        related_id INTEGER,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // 8. Vouchers (Hệ thống Voucher)
    await db.execute('''
      CREATE TABLE vouchers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        discount_type TEXT NOT NULL,
        discount_value REAL NOT NULL,
        min_order_value REAL DEFAULT 0,
        max_discount REAL DEFAULT 0,
        color_hex TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 9. User Vouchers (Kho voucher cá nhân)
    await db.execute('''
      CREATE TABLE user_vouchers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        voucher_id INTEGER NOT NULL,
        is_used INTEGER NOT NULL DEFAULT 0,
        used_at TEXT,
        acquired_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE CASCADE
      )
    ''');

    // 10. User Spins (Tổng lượt quay khả dụng)
    await db.execute('''
      CREATE TABLE user_spins (
        user_id INTEGER PRIMARY KEY,
        spins_left INTEGER NOT NULL DEFAULT 1,
        total_spins_used INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 11. User Daily Quests (Tiến độ nhiệm vụ mỗi ngày)
    await db.execute('''
      CREATE TABLE user_daily_quests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        quest_date TEXT NOT NULL,
        login_claimed INTEGER NOT NULL DEFAULT 0,
        order_spins_earned INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, quest_date)
      )
    ''');
    
    // 12. Reviews & Ratings (Đánh giá sản phẩm kèm ảnh thực tế)
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        user_avatar TEXT,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        images TEXT,
        is_verified_buyer INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Seed data
    await _seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Đơn giản hóa quá trình phát triển dev local: drop and recreate
      await db.execute('DROP TABLE IF EXISTS notifications');
      await db.execute('DROP TABLE IF EXISTS user_daily_quests');
      await db.execute('DROP TABLE IF EXISTS user_spins');
      await db.execute('DROP TABLE IF EXISTS user_vouchers');
      await db.execute('DROP TABLE IF EXISTS vouchers');
      await db.execute('DROP TABLE IF EXISTS reviews');
      await db.execute('DROP TABLE IF EXISTS order_items');
      await db.execute('DROP TABLE IF EXISTS orders');
      await db.execute('DROP TABLE IF EXISTS cart_items');
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS users');
      await _createDB(db, newVersion);
      return;
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'ORDER',
          related_id INTEGER,
          is_read INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 7) {
      // Đảm bảo bảng notifications tồn tại
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'ORDER',
          related_id INTEGER,
          is_read INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Nạp toàn diện bộ thông báo mẫu theo yêu cầu cho Admin, Employee, Customer
      await _seedNotifications(db);
        CREATE TABLE IF NOT EXISTS reviews (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          user_name TEXT NOT NULL,
          user_avatar TEXT,
          rating REAL NOT NULL,
          comment TEXT NOT NULL,
          images TEXT,
          is_verified_buyer INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      await _seedReviewsData(db);
    }
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // 1. Seed Users (Tài khoản mẫu Admin, Employee và Customer)
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'full_name': 'Quản Trị Viên (Admin)',
      'email': 'admin@shop.com',
      'phone': '0901112233',
      'address': 'Trụ sở Quản lý, Tòa nhà FPT',
      'role': 'ADMIN',
      'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      'created_at': now,
    });

    await db.insert('users', {
      'username': 'employee',
      'password': 'emp123',
      'full_name': 'Trần Văn Nhân Viên (Employee)',
      'email': 'employee@shop.com',
      'phone': '0909998877',
      'address': 'Chi nhánh FPT Shop',
      'role': 'EMPLOYEE',
      'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'created_at': now,
    });

    await db.insert('users', {
      'username': 'customer',
      'password': 'cust123',
      'full_name': 'Nguyễn Văn A (Khách hàng)',
      'email': 'nguyenvana@gmail.com',
      'phone': '0987654321',
      'address': 'Số 123 Cầu Giấy, Dịch Vọng Hậu, Hà Nội',
      'role': 'CUSTOMER',
      'avatar_url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
      'created_at': now,
    });

    await db.insert('users', {
      'username': 'customer2',
      'password': 'cust123',
      'full_name': 'Trần Thị B (Khách hàng 2)',
      'email': 'tranthib@gmail.com',
      'phone': '0912345678',
      'address': '456 Đường Lê Duẩn, Hải Châu, Đà Nẵng',
      'role': 'CUSTOMER',
      'avatar_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'created_at': now,
    });

    // 2. Seed Categories
    await db.rawInsert("INSERT INTO categories (name, icon) VALUES ('Điện thoại', 'phone_android')");
    await db.rawInsert("INSERT INTO categories (name, icon) VALUES ('Laptop', 'laptop')");
    await db.rawInsert("INSERT INTO categories (name, icon) VALUES ('Phụ kiện', 'headphones')");

    // 3. Seed Products
    final products = [
      {
        'category_id': 1,
        'name': 'iPhone 15 Pro Max 256GB',
        'description': 'Titan tự nhiên, chip A17 Pro mạnh mẽ, camera tiềm vọng 5x.',
        'price': 29990000.0,
        'stock_quantity': 12,
        'image_url': 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=500',
        'created_at': now,
      },
      {
        'category_id': 1,
        'name': 'Samsung Galaxy S24 Ultra',
        'description': 'Galaxy AI, bút S-Pen tích hợp, camera 200MP.',
        'price': 27490000.0,
        'stock_quantity': 8,
        'image_url': 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=500',
        'created_at': now,
      },
      {
        'category_id': 2,
        'name': 'MacBook Air M3 13 inch',
        'description': 'Chip Apple M3 siêu nhanh, pin 18 tiếng, mỏng nhẹ 1.24kg.',
        'price': 26990000.0,
        'stock_quantity': 5,
        'image_url': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500',
        'created_at': now,
      },
      {
        'category_id': 3,
        'name': 'AirPods Pro 2 USB-C',
        'description': 'Chống ồn chủ động gấp 2 lần, chip H2 thế hệ mới.',
        'price': 5490000.0,
        'stock_quantity': 25,
        'image_url': 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=500',
        'created_at': now,
      },
      {
        'category_id': 3,
        'name': 'Bàn phím cơ không dây Keychron K2',
        'description': 'Switch Gateron G Pro, kết nối Bluetooth 5.1 và dây Type-C.',
        'price': 1850000.0,
        'stock_quantity': 3,
        'image_url': 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=500',
        'created_at': now,
      },
      {
        'category_id': 3,
        'name': 'Chuột công thái học Logitech MX Master 3S',
        'description': 'Cảm biến 8K DPI, con lăn MagSpeed siêu êm.',
        'price': 2190000.0,
        'stock_quantity': 0, // Mock hết hàng để test validate tồn kho
        'image_url': 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=500',
        'created_at': now,
      },
      {
        'category_id': 1,
        'name': 'Xiaomi 14 Ultra 512GB',
        'description': 'Camera Leica Summilux cảm biến 1 inch, chip Snapdragon 8 Gen 3, sạc siêu nhanh 90W.',
        'price': 24990000.0,
        'stock_quantity': 10,
        'image_url': 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=500',
        'created_at': now,
      },
      {
        'category_id': 2,
        'name': 'Dell XPS 13 9340 (2024)',
        'description': 'Intel Core Ultra 7, màn hình 13.4 inch OLED 3K cảm ứng, phím tàng hình sang trọng, 1.19kg.',
        'price': 34990000.0,
        'stock_quantity': 6,
        'image_url': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=500',
        'created_at': now,
      },
      {
        'category_id': 2,
        'name': 'Asus ROG Zephyrus G14 (2024)',
        'description': 'Ryzen 9 8945HS, RTX 4060, 32GB RAM, màn hình OLED 120Hz 3K Nebula, thiết kế nhôm CNC.',
        'price': 39990000.0,
        'stock_quantity': 4,
        'image_url': 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=500',
        'created_at': now,
      },
    ];

    for (var p in products) {
      await db.insert('products', p);
    }

    // 4. Seed Orders (Đơn hàng mẫu với các trạng thái khác nhau)
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).toIso8601String();

    // Đơn 1: COMPLETED (hôm qua) — user customer (id=3)
    await db.insert('orders', {
      'user_id': 3,
      'order_code': 'ORD-20261027-001',
      'customer_name': 'Nguyễn Văn A',
      'phone': '0987654321',
      'address': 'Số 123 Cầu Giấy, Dịch Vọng Hậu, Hà Nội',
      'note': 'Giao giờ hành chính',
      'subtotal': 35480000.0,
      'discount': 0.0,
      'shipping_fee': 30000.0,
      'final_amount': 35510000.0,
      'payment_method': 'COD',
      'status': 'COMPLETED',
      'created_at': yesterday,
    });
    await db.insert('order_items', {
      'order_id': 1,
      'product_id': 1,
      'product_name': 'iPhone 15 Pro Max 256GB',
      'product_price': 29990000.0,
      'quantity': 1,
      'subtotal': 29990000.0,
    });
    await db.insert('order_items', {
      'order_id': 1,
      'product_id': 4,
      'product_name': 'AirPods Pro 2 USB-C',
      'product_price': 5490000.0,
      'quantity': 1,
      'subtotal': 5490000.0,
    });

    // Đơn 2: COMPLETED (2 ngày trước) — user customer2 (id=4)
    await db.insert('orders', {
      'user_id': 4,
      'order_code': 'ORD-20261026-001',
      'customer_name': 'Trần Thị B',
      'phone': '0912345678',
      'address': '456 Đường Lê Duẩn, Hải Châu, Đà Nẵng',
      'note': '',
      'subtotal': 26990000.0,
      'discount': 1000000.0,
      'shipping_fee': 0.0,
      'final_amount': 25990000.0,
      'payment_method': 'BANK_TRANSFER',
      'status': 'COMPLETED',
      'created_at': twoDaysAgo,
    });
    await db.insert('order_items', {
      'order_id': 2,
      'product_id': 3,
      'product_name': 'MacBook Air M3 13 inch',
      'product_price': 26990000.0,
      'quantity': 1,
      'subtotal': 26990000.0,
    });

    // Đơn 3: PENDING (hôm nay) — user customer (id=3)
    await db.insert('orders', {
      'user_id': 3,
      'order_code': 'ORD-20261028-001',
      'customer_name': 'Nguyễn Văn A',
      'phone': '0987654321',
      'address': 'Số 123 Cầu Giấy, Dịch Vọng Hậu, Hà Nội',
      'note': 'Giao trước 5h chiều',
      'subtotal': 5490000.0,
      'discount': 0.0,
      'shipping_fee': 30000.0,
      'final_amount': 5520000.0,
      'payment_method': 'COD',
      'status': 'PENDING',
      'created_at': now,
    });
    await db.insert('order_items', {
      'order_id': 3,
      'product_id': 4,
      'product_name': 'AirPods Pro 2 USB-C',
      'product_price': 5490000.0,
      'quantity': 1,
      'subtotal': 5490000.0,
    });

    // Đơn 4: PROCESSING (hôm nay) — user customer2 (id=4)
    await db.insert('orders', {
      'user_id': 4,
      'order_code': 'ORD-20261028-002',
      'customer_name': 'Trần Thị B',
      'phone': '0912345678',
      'address': '456 Đường Lê Duẩn, Hải Châu, Đà Nẵng',
      'note': 'Để ở sảnh',
      'subtotal': 29990000.0,
      'discount': 500000.0,
      'shipping_fee': 0.0,
      'final_amount': 29490000.0,
      'payment_method': 'BANK_TRANSFER',
      'status': 'PROCESSING',
      'created_at': now,
    });
    await db.insert('order_items', {
      'order_id': 4,
      'product_id': 1,
      'product_name': 'iPhone 15 Pro Max 256GB',
      'product_price': 29990000.0,
      'quantity': 1,
      'subtotal': 29990000.0,
    });

    // Đơn 5: CANCELLED (3 ngày trước) — user customer (id=3)
    await db.insert('orders', {
      'user_id': 3,
      'order_code': 'ORD-20261025-001',
      'customer_name': 'Nguyễn Văn A',
      'phone': '0987654321',
      'address': 'Số 123 Cầu Giấy, Dịch Vọng Hậu, Hà Nội',
      'note': '',
      'subtotal': 27490000.0,
      'discount': 0.0,
      'shipping_fee': 30000.0,
      'final_amount': 27520000.0,
      'payment_method': 'COD',
      'status': 'CANCELLED',
      'created_at': threeDaysAgo,
    });
    await db.insert('order_items', {
      'order_id': 5,
      'product_id': 2,
      'product_name': 'Samsung Galaxy S24 Ultra',
      'product_price': 27490000.0,
      'quantity': 1,
      'subtotal': 27490000.0,
    });

    // 5. Seed Notifications theo phân quyền (Customer, Employee, Admin)
    await _seedNotifications(db);
  }

  Future<void> _seedNotifications(Database db) async {
    final stockNotifs = await db.query(
      'notifications',
      where: "type = 'STOCK'",
    );

    // Nếu database đã có thông báo loại STOCK nghĩa là đã nạp bộ seed đầy đủ mới
    if (stockNotifs.isNotEmpty) return;

    // Xóa sạch để seed bộ dữ liệu thông báo chuẩn hóa đồng bộ với các order và product mẫu
    await db.delete('notifications');

    final now = DateTime.now().toIso8601String();
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).toIso8601String();

    final notifications = [
      // ══════════════════════════════════════════════════════════════
      //  1. ADMIN (user_id = 1)
      // ══════════════════════════════════════════════════════════════
      // Báo cáo doanh thu tháng 10 (ngày 1/11)
      {
        'user_id': 1,
        'title': 'Báo cáo doanh thu tháng 10',
        'message': 'Báo cáo doanh thu tháng 10 của bạn đã có, hãy xem ngay.',
        'type': 'REPORT',
        'related_id': null,
        'is_read': 0,
        'created_at': '2026-11-01T08:00:00.000',
      },
      // Báo cáo doanh thu theo mốc hôm nay
      {
        'user_id': 1,
        'title': 'Mốc doanh thu mới',
        'message': 'Doanh thu hôm nay đã đạt mốc 5.000.000 VND',
        'type': 'REPORT',
        'related_id': null,
        'is_read': 0,
        'created_at': now,
      },
      // Báo cáo doanh thu theo mốc hệ thống
      {
        'user_id': 1,
        'title': 'Mốc doanh thu hệ thống',
        'message': 'Doanh thu hệ thống đã đạt mốc 90.000.000 VND',
        'type': 'REPORT',
        'related_id': null,
        'is_read': 1,
        'created_at': yesterday,
      },
      // Cảnh báo hết hàng
      {
        'user_id': 1,
        'title': 'Cảnh báo hết hàng',
        'message': 'Chuột công thái học Logitech MX Master 3S đã hết hàng',
        'type': 'STOCK',
        'related_id': 6,
        'is_read': 0,
        'created_at': now,
      },
      // Cảnh báo tồn kho thấp
      {
        'user_id': 1,
        'title': 'Cảnh báo sắp hết hàng',
        'message': 'Bàn phím cơ không dây Keychron K2 chỉ còn 3 sản phẩm trong kho',
        'type': 'STOCK',
        'related_id': 5,
        'is_read': 0,
        'created_at': now,
      },
      {
        'user_id': 1,
        'title': 'Cảnh báo sắp hết hàng',
        'message': 'MacBook Air M3 13 inch chỉ còn 5 sản phẩm trong kho',
        'type': 'STOCK',
        'related_id': 3,
        'is_read': 1,
        'created_at': yesterday,
      },
      // Thay đổi dữ liệu sản phẩm bởi nhân viên
      {
        'user_id': 1,
        'title': 'Cập nhật sản phẩm',
        'message': 'Sản phẩm iPhone 15 Pro Max 256GB vừa được thay đổi dữ liệu bởi nhân viên Trần Văn Nhân Viên.',
        'type': 'PRODUCT',
        'related_id': 1,
        'is_read': 0,
        'created_at': yesterday,
      },
      {
        'user_id': 1,
        'title': 'Thêm sản phẩm mới',
        'message': 'Sản phẩm Chuột công thái học Logitech MX Master 3S vừa được thêm bởi nhân viên Trần Văn Nhân Viên.',
        'type': 'PRODUCT',
        'related_id': 6,
        'is_read': 1,
        'created_at': twoDaysAgo,
      },

      // ══════════════════════════════════════════════════════════════
      //  2. EMPLOYEE (user_id = 2)
      // ══════════════════════════════════════════════════════════════
      // Đơn hàng mới cần xử lý (Đơn 3 PENDING)
      {
        'user_id': 2,
        'title': 'Đơn hàng mới cần xử lý',
        'message': 'Có đơn hàng mới ORD-20261028-001 từ khách hàng Nguyễn Văn A, giá trị 5.520.000 ₫. Vui lòng kiểm tra và xử lý.',
        'type': 'ORDER',
        'related_id': 3,
        'is_read': 0,
        'created_at': now,
      },
      // Đơn hàng đang xử lý (Đơn 4 PROCESSING)
      {
        'user_id': 2,
        'title': 'Đơn hàng đang xử lý',
        'message': 'Đơn hàng ORD-20261028-002 từ khách hàng Trần Thị B đã được duyệt, đang được xử lý.',
        'type': 'ORDER',
        'related_id': 4,
        'is_read': 0,
        'created_at': now,
      },
      // Đơn hàng bị hủy (Đơn 5 CANCELLED)
      {
        'user_id': 2,
        'title': 'Đơn hàng bị hủy',
        'message': 'Đơn hàng ORD-20261025-001 từ khách hàng Nguyễn Văn A đã bị hủy. Vui lòng kiểm tra và xử lý hoàn hàng.',
        'type': 'ORDER',
        'related_id': 5,
        'is_read': 1,
        'created_at': threeDaysAgo,
      },
      // Cảnh báo hàng tồn kho cho Employee
      {
        'user_id': 2,
        'title': 'Cảnh báo hết hàng',
        'message': 'Chuột công thái học Logitech MX Master 3S đã hết hàng',
        'type': 'STOCK',
        'related_id': 6,
        'is_read': 0,
        'created_at': now,
      },
      {
        'user_id': 2,
        'title': 'Cảnh báo sắp hết hàng',
        'message': 'Bàn phím cơ không dây Keychron K2 chỉ còn 3 sản phẩm trong kho',
        'type': 'STOCK',
        'related_id': 5,
        'is_read': 0,
        'created_at': now,
      },

      // ══════════════════════════════════════════════════════════════
      //  3. CUSTOMER 1 (user_id = 3 - Nguyễn Văn A)
      // ══════════════════════════════════════════════════════════════
      // Đặt hàng thành công (Đơn 3 PENDING)
      {
        'user_id': 3,
        'title': 'Đặt hàng thành công',
        'message': 'Bạn đã đặt đơn hàng ORD-20261028-001, dự kiến giao trong 3 ngày.',
        'type': 'ORDER',
        'related_id': 3,
        'is_read': 0,
        'created_at': now,
      },
      // Trạng thái đơn thay đổi sang hoàn thành (Đơn 1 COMPLETED)
      {
        'user_id': 3,
        'title': 'Đơn hàng giao thành công',
        'message': 'Đơn hàng ORD-20261027-001 đã được giao thành công, vui lòng đánh giá sản phẩm.',
        'type': 'ORDER',
        'related_id': 1,
        'is_read': 1,
        'created_at': yesterday,
      },
      // Đơn hàng bị hủy (Đơn 5 CANCELLED)
      {
        'user_id': 3,
        'title': 'Đơn hàng đã hủy',
        'message': 'Đơn hàng ORD-20261025-001 của bạn đã bị hủy.',
        'type': 'ORDER',
        'related_id': 5,
        'is_read': 1,
        'created_at': threeDaysAgo,
      },
      // Chương trình khuyến mãi
      {
        'user_id': 3,
        'title': 'Siêu Sale Tháng 11',
        'message': 'Giảm giá tới 20% toàn bộ phụ kiện công nghệ và miễn phí giao hàng cho đơn từ 500.000đ!',
        'type': 'PROMOTION',
        'related_id': null,
        'is_read': 0,
        'created_at': now,
      },
      {
        'user_id': 3,
        'title': 'Mã giảm giá cho bạn',
        'message': 'Tặng bạn voucher giảm 200.000 ₫ cho đơn hàng tiếp theo từ 2.000.000 ₫.',
        'type': 'PROMOTION',
        'related_id': null,
        'is_read': 1,
        'created_at': twoDaysAgo,
      },

      // ══════════════════════════════════════════════════════════════
      //  4. CUSTOMER 2 (user_id = 4 - Trần Thị B)
      // ══════════════════════════════════════════════════════════════
      // Trạng thái đơn thay đổi (Đơn 4 PROCESSING)
      {
        'user_id': 4,
        'title': 'Đơn hàng đang xử lý',
        'message': 'Đơn hàng ORD-20261028-002 của bạn đã được duyệt, đang được xử lý.',
        'type': 'ORDER',
        'related_id': 4,
        'is_read': 0,
        'created_at': now,
      },
      // Đơn 2 COMPLETED
      {
        'user_id': 4,
        'title': 'Đơn hàng giao thành công',
        'message': 'Đơn hàng ORD-20261026-001 đã được giao thành công, vui lòng đánh giá sản phẩm.',
        'type': 'ORDER',
        'related_id': 2,
        'is_read': 1,
        'created_at': twoDaysAgo,
      },
      // Chương trình khuyến mãi
      {
        'user_id': 4,
        'title': 'Ưu đãi thành viên mới',
        'message': 'Chào mừng bạn đến với shop! Miễn phí vận chuyển cho tất cả đơn hàng đầu tiên.',
        'type': 'PROMOTION',
        'related_id': null,
        'is_read': 0,
    // 7. Seed Vouchers hệ thống
    final initialVouchers = [
      {
        'code': 'LUCKY20K',
        'title': 'Voucher May Mắn 20K',
        'description': 'Giảm trực tiếp 20.000₫ cho đơn hàng từ 200.000₫',
        'discount_type': 'FIXED',
        'discount_value': 20000.0,
        'min_order_value': 200000.0,
        'max_discount': 0.0,
        'color_hex': '#FF8A00',
        'created_at': now,
      },
      {
        'code': 'FLASH30K',
        'title': 'Voucher Chớp Nhoáng 30K',
        'description': 'Giảm 30.000₫ cho đơn hàng từ 250.000₫',
        'discount_type': 'FIXED',
        'discount_value': 30000.0,
        'min_order_value': 250000.0,
        'max_discount': 0.0,
        'color_hex': '#C2185B',
        'created_at': now,
      },
      {
        'code': 'SUPER50K',
        'title': 'Siêu Voucher 50K',
        'description': 'Giảm 50.000₫ cho đơn hàng công nghệ từ 500.000₫',
        'discount_type': 'FIXED',
        'discount_value': 50000.0,
        'min_order_value': 500000.0,
        'max_discount': 0.0,
        'color_hex': '#E53935',
        'created_at': now,
      },
      {
        'code': 'VIP100K',
        'title': 'Voucher Đại Gia 100K',
        'description': 'Giảm 100.000₫ cho đơn hàng VIP từ 1.000.000₫',
        'discount_type': 'FIXED',
        'discount_value': 100000.0,
        'min_order_value': 1000000.0,
        'max_discount': 0.0,
        'color_hex': '#FFA000',
        'created_at': now,
      },
      {
        'code': 'SALE10',
        'title': 'Giảm Giá 10% Toàn Sàn',
        'description': 'Giảm 10% tối đa 100.000₫ cho đơn từ 300.000₫',
        'discount_type': 'PERCENT',
        'discount_value': 10.0,
        'min_order_value': 300000.0,
        'max_discount': 100000.0,
        'color_hex': '#7B1FA2',
        'created_at': now,
      },
      {
        'code': 'FREESHIP',
        'title': 'Miễn Phí Vận Chuyển',
        'description': 'Tài trợ tối đa 30.000₫ phí giao hàng cho đơn từ 150.000₫',
        'discount_type': 'FREE_SHIP',
        'discount_value': 30000.0,
        'min_order_value': 150000.0,
        'max_discount': 30000.0,
        'color_hex': '#0288D1',
        'created_at': now,
      },
    ];

    for (var v in initialVouchers) {
      await db.insert('vouchers', v);
    }

    // 8. Seed Lượt quay mặc định cho các Users
    await db.insert('user_spins', {
      'user_id': 1, // admin
      'spins_left': 1,
      'total_spins_used': 0,
      'updated_at': now,
    });
    await db.insert('user_spins', {
      'user_id': 2, // employee
      'spins_left': 1,
      'total_spins_used': 0,
      'updated_at': now,
    });
    await db.insert('user_spins', {
      'user_id': 3, // customer (cho sẵn 3 lượt để test quay thoải mái)
      'spins_left': 3,
      'total_spins_used': 0,
      'updated_at': now,
    });
    await db.insert('user_spins', {
      'user_id': 4, // customer2
      'spins_left': 2,
      'total_spins_used': 0,
      'updated_at': now,
    });

    // 9. Seed sẵn 1 Voucher mẫu vào kho của user customer (id=3) để demo
    await db.insert('user_vouchers', {
      'user_id': 3,
      'voucher_id': 1, // LUCKY20K
      'is_used': 0,
      'acquired_at': now,
    });
    await db.insert('user_vouchers', {
      'user_id': 3,
      'voucher_id': 6, // FREESHIP
      'is_used': 0,
      'acquired_at': now,
    });
    // 5. Seed Reviews
    await _seedReviewsData(db);
  }

  Future<void> _seedReviewsData(Database db) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1)).toIso8601String();
    final twoDaysAgo = now.subtract(const Duration(days: 2)).toIso8601String();
    final threeDaysAgo = now.subtract(const Duration(days: 3)).toIso8601String();
    final fourDaysAgo = now.subtract(const Duration(days: 4)).toIso8601String();

    final reviews = [
      // Product 1: iPhone 15 Pro Max
      {
        'product_id': 1,
        'user_id': 3,
        'user_name': 'Nguyễn Văn A',
        'user_avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
        'rating': 5.0,
        'comment': 'Máy cầm rất đầm tay, viền titan tự nhiên nhìn cực kỳ sang trọng. Camera zoom 5x chụp nét căng, pin trâu dùng cả ngày từ sáng đến tối vẫn còn 35%. Rất hài lòng với dịch vụ giao hàng nhanh của shop!',
        'images': jsonEncode([
          'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=600',
          'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=600',
        ]),
        'is_verified_buyer': 1,
        'created_at': yesterday,
      },
      {
        'product_id': 1,
        'user_id': 4,
        'user_name': 'Trần Thị B',
        'user_avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        'rating': 5.0,
        'comment': 'Giao hàng siêu nhanh chỉ trong 2 tiếng tại nội thành! Đóng gói cẩn thận 3 lớp chống sốc, nguyên seal chính hãng VN/A kích hoạt bảo hành đủ 12 tháng Apple.',
        'images': jsonEncode([
          'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=600',
        ]),
        'is_verified_buyer': 1,
        'created_at': twoDaysAgo,
      },
      {
        'product_id': 1,
        'user_id': 2,
        'user_name': 'Lê Minh Khang',
        'user_avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        'rating': 4.0,
        'comment': 'Màn hình ProMotion 120Hz mượt mà, dynamic island tiện dụng. Điểm trừ nhẹ là hộp không kèm củ sạc nên phải mua thêm củ sạc nhanh 30W.',
        'images': jsonEncode([]),
        'is_verified_buyer': 0,
        'created_at': threeDaysAgo,
      },
      // Product 4: AirPods Pro 2
      {
        'product_id': 4,
        'user_id': 3,
        'user_name': 'Nguyễn Văn A',
        'user_avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
        'rating': 5.0,
        'comment': 'Chống ồn chủ động đỉnh chóp, ngồi quán cafe bật ANC là im bặt tiếng ồn. Âm bass trầm ấm, cổng Type-C tiện lợi chung sạc với điện thoại.',
        'images': jsonEncode([
          'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=600',
        ]),
        'is_verified_buyer': 1,
        'created_at': yesterday,
      },
      // Product 3: MacBook Air M3
      {
        'product_id': 3,
        'user_id': 4,
        'user_name': 'Trần Thị B',
        'user_avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        'rating': 5.0,
        'comment': 'MacBook Air M3 mỏng nhẹ tinh tế, khởi động tức thì. Bàn phím gõ êm, trackpad rê vuốt mượt mà, pin dùng làm việc cả ngày không cần cắm sạc.',
        'images': jsonEncode([
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600',
        ]),
        'is_verified_buyer': 1,
        'created_at': fourDaysAgo,
      },
      // Product 5: Keychron K2
      {
        'product_id': 5,
        'user_id': 3,
        'user_name': 'Hoàng Nam',
        'user_avatar': null,
        'rating': 5.0,
        'comment': 'Bàn phím cơ gõ rất đầm tay, switch G Pro mượt không bị rung lắc. Kết nối bluetooth 3 thiết bị chuyển qua lại rất mượt.',
        'images': jsonEncode([
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600',
        ]),
        'is_verified_buyer': 0,
        'created_at': threeDaysAgo,
      },
    ];

    for (final notif in notifications) {
      await db.insert('notifications', notif);
    for (final r in reviews) {
      await db.insert('reviews', r);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
