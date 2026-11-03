import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/order/order_history_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';

import '../../screens/checkout/order_success_screen.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
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
      builder: (context, state) {
        final items = state.extra as List<CartItem>?;
        return CheckoutScreen(initialItems: items);
      },
    ),
    GoRoute(
      path: '/order-success',
      builder: (context, state) {
        final order = state.extra as Order?;
        return OrderSuccessScreen(order: order);
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
  ],
);
