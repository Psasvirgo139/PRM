import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/compare_provider.dart';
import 'providers/voucher_provider.dart';
import 'providers/quest_provider.dart';
import 'providers/lucky_wheel_provider.dart';
import 'providers/review_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Database Factory tương thích đa nền tảng (Web, Windows Desktop, Android/iOS)
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Khởi tạo Database SQLite và nạp dữ liệu mẫu ban đầu
  try {
    await DatabaseHelper.instance.database;
  } catch (e) {
    debugPrint('Database initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        // Các providers tiếp theo do các thành viên tích hợp:
        // ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) {
            final cartProvider = cart ?? CartProvider();
            if (auth.currentUser?.id != null) {
              cartProvider.setUserId(auth.currentUser!.id!);
            }
            return cartProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, notif) {
            final provider = notif ?? NotificationProvider();
            provider.setUserId(auth.currentUser?.id);
            }            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, VoucherProvider>(
          create: (_) => VoucherProvider(),
          update: (_, auth, vp) {
            final provider = vp ?? VoucherProvider();
            if (auth.currentUser?.id != null) {
              provider.setUserId(auth.currentUser!.id!);
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, QuestProvider>(
          create: (_) => QuestProvider(),
          update: (_, auth, qp) {
            final provider = qp ?? QuestProvider();
            if (auth.currentUser?.id != null) {
              provider.setUserId(auth.currentUser!.id!);
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, LuckyWheelProvider>(
          create: (_) => LuckyWheelProvider(),
          update: (_, auth, lwp) {
            final provider = lwp ?? LuckyWheelProvider();
            if (auth.currentUser?.id != null) {
              provider.setUserId(auth.currentUser!.id!);
            }
            return provider;
          },
        ),
        // Các providers tiếp theo do các thành viên tích hợp:
        // ChangeNotifierProvider(create: (_) => ProductProvider()),
        // ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp.router(
        title: 'PRM393 E-Commerce',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
      ),
    );
  }
}
