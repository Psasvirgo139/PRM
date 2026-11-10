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
    );
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

    // Seed data
    await _seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Đơn giản hóa quá trình phát triển dev local: drop and recreate
      await db.execute('DROP TABLE IF EXISTS notifications');
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
        'created_at': threeDaysAgo,
      },
    ];

    for (final notif in notifications) {
      await db.insert('notifications', notif);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
