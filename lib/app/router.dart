import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/views/splash_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/catalog/views/home_screen.dart';
import '../features/catalog/views/categories_screen.dart';
import '../features/cart/views/cart_screen.dart';
import '../features/checkout/views/checkout_screen.dart';
import '../features/orders/views/orders_list_screen.dart';
import '../features/orders/views/order_detail_screen.dart';
import '../features/addresses/views/addresses_screen.dart';
import '../features/addresses/views/address_form_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/catalog/views/category_screen.dart';
import '../features/catalog/views/product_detail_screen.dart';
import '../features/admin/dashboard/dashboard_screen.dart';
import '../features/admin/products/products_list_screen.dart';
import '../features/admin/products/product_form_screen.dart';
import '../features/admin/inventory/inventory_screen.dart';
import '../features/admin/orders/admin_orders_screen.dart';
import '../features/admin/orders/admin_order_detail_screen.dart';
import '../features/admin/delivery/delivery_partners_screen.dart';
import '../features/delivery_partner/views/delivery_orders_screen.dart';
import '../features/delivery_partner/views/delivery_order_detail_screen.dart';
import '../features/wishlist/views/wishlist_screen.dart';
import '../features/search/views/search_screen.dart';
import '../core/widgets/navigation/main_scaffold.dart';

/// Navigation shell key for preserving state
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash & Auth routes (no bottom nav)
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer routes with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          // Update the bottom nav index based on the current route
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final container = ProviderScope.containerOf(context);
            final index = getNavIndexFromPath(state.uri.path);
            container.read(bottomNavIndexProvider.notifier).state = index;
          });
          return MainScaffold(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),

          // Categories
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesScreen(),
            ),
          ),

          // Category products (navigated from categories)
          GoRoute(
            path: '/category/:id',
            builder: (context, state) {
              final categoryId = state.pathParameters['id']!;
              return CategoryScreen(categoryId: categoryId);
            },
          ),

          // Product detail
          GoRoute(
            path: '/product/:id',
            builder: (context, state) {
              final productId = state.pathParameters['id']!;
              return ProductDetailScreen(productId: productId);
            },
          ),

          // Search
          GoRoute(
            path: '/search',
            builder: (context, state) {
              final query = state.uri.queryParameters['q'];
              return SearchScreen(initialQuery: query);
            },
          ),

          // Wishlist
          GoRoute(
            path: '/wishlist',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WishlistScreen(),
            ),
          ),

          // Cart
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CartScreen(),
            ),
          ),

          // Checkout
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),

          // Orders list
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OrdersListScreen(),
            ),
          ),

          // Order detail
          GoRoute(
            path: '/orders/:id',
            builder: (context, state) {
              final orderId = state.pathParameters['id']!;
              return OrderDetailScreen(orderId: orderId);
            },
          ),

          // Profile
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),

          // Addresses
          GoRoute(
            path: '/addresses',
            builder: (context, state) => const AddressesScreen(),
          ),
          GoRoute(
            path: '/addresses/new',
            builder: (context, state) => const AddressFormScreen(),
          ),
          GoRoute(
            path: '/addresses/:id/edit',
            builder: (context, state) {
              final addressIndex = int.tryParse(state.pathParameters['id'] ?? '0');
              return AddressFormScreen(addressIndex: addressIndex);
            },
          ),
        ],
      ),

      // Admin routes (no bottom nav - separate flow)
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const ProductsListScreen(),
      ),
      GoRoute(
        path: '/admin/products/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/admin/products/:id/edit',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductFormScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/admin/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/orders/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return AdminOrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/admin/delivery-partners',
        builder: (context, state) => const DeliveryPartnersScreen(),
      ),

      // Delivery Partner routes (no bottom nav - separate flow)
      GoRoute(
        path: '/delivery',
        builder: (context, state) => const DeliveryOrdersScreen(),
      ),
      GoRoute(
        path: '/delivery/orders/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return DeliveryOrderDetailScreen(orderId: orderId);
        },
      ),
    ],
  );
});
