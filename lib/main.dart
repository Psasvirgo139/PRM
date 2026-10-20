import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Database SQLite và nạp dữ liệu mẫu ban đầu
  await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Các providers sẽ được các thành viên thêm vào đây:
        // ChangeNotifierProvider(create: (_) => ProductProvider()),
        // ChangeNotifierProvider(create: (_) => CartProvider()),
        // ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp.router(
        title: 'PRM393 E-Commerce',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 1,
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
