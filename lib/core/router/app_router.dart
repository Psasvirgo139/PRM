import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/order/order_history_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../models/product.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_orders_screen.dart';
import '../../screens/admin/admin_order_detail_screen.dart';
import '../../screens/product/product_detail_screen.dart';

import '../../screens/checkout/order_success_screen.dart';
import '../../screens/notification/notification_screen.dart';
import '../../screens/checkout/payos_payment_screen.dart';
import '../../screens/compare/product_compare_screen.dart';
import '../../models/order.dart';
import '../../models/payos_payment_data.dart';
import '../../models/cart_item.dart';
import '../../screens/lucky_wheel/lucky_wheel_screen.dart';
import '../../screens/voucher/voucher_wallet_screen.dart';

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
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
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
      path: '/admin/orders',
      builder: (context, state) {
        final status = state.uri.queryParameters['status'];
        return AdminOrdersScreen(initialStatus: status);
      },
    ),
    GoRoute(
      path: '/admin/orders/:orderId',
      builder: (context, state) {
        final orderId = int.parse(state.pathParameters['orderId']!);
        return AdminOrderDetailScreen(orderId: orderId);
      },
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
      path: '/payos-payment',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final order = extra['order'] as Order;
        final payosData = extra['payosData'] as PayOSPaymentData;
        return PayOSPaymentScreen(order: order, payosData: payosData);
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
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(  
      path: '/compare',
      builder: (context, state) => const ProductCompareScreen(),
    ),
    GoRoute(
      path: '/lucky-wheel',
      builder: (context, state) => const LuckyWheelScreen(),
    ),
    GoRoute(
      path: '/vouchers',
      builder: (context, state) => const VoucherWalletScreen(),
    ),
  ],
);
