import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/order/order_history_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../models/product.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/product/product_detail_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final product = state.extra as Product?;
        return ProductDetailScreen(productId: id, initialProduct: product);
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
  ],
);
