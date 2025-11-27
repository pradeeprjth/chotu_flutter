# Chotu Flutter App - Implementation Guide

This guide provides a comprehensive overview of implementing the Chotu Flutter application based on the frontend.md specification.

## Project Structure

```
lib/
├── app/
│   ├── app_widget.dart          # Main app widget with theme and router
│   ├── router.dart               # GoRouter configuration
│   └── theme.dart                # App theme definitions
├── core/
│   ├── api/
│   │   ├── api_config.dart      # API base URL and configuration
│   │   ├── api_client.dart      # Dio HTTP client with interceptors
│   │   └── api_service.dart     # Retrofit API service definitions
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── product_model.dart
│   │   ├── category_model.dart
│   │   ├── cart_model.dart
│   │   ├── order_model.dart
│   │   └── delivery_partner_model.dart
│   ├── services/
│   │   ├── auth_service.dart    # Authentication logic
│   │   ├── storage_service.dart # Secure storage wrapper
│   │   └── location_service.dart
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── loading_indicator.dart
│   │   └── error_widget.dart
│   └── utils/
│       ├── constants.dart
│       ├── validators.dart
│       └── extensions.dart
├── features/
│   ├── auth/
│   │   ├── views/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── widgets/
│   ├── catalog/
│   │   ├── views/
│   │   │   ├── home_screen.dart
│   │   │   ├── category_screen.dart
│   │   │   └── product_detail_screen.dart
│   │   ├── providers/
│   │   │   ├── categories_provider.dart
│   │   │   └── products_provider.dart
│   │   └── widgets/
│   │       ├── product_card.dart
│   │       └── category_card.dart
│   ├── cart/
│   │   ├── views/
│   │   │   └── cart_screen.dart
│   │   ├── providers/
│   │   │   └── cart_provider.dart
│   │   └── widgets/
│   │       └── cart_item_card.dart
│   ├── checkout/
│   │   ├── views/
│   │   │   └── checkout_screen.dart
│   │   └── providers/
│   │       └── checkout_provider.dart
│   ├── orders/
│   │   ├── views/
│   │   │   ├── orders_list_screen.dart
│   │   │   └── order_detail_screen.dart
│   │   ├── providers/
│   │   │   └── orders_provider.dart
│   │   └── widgets/
│   │       ├── order_card.dart
│   │       └── order_status_timeline.dart
│   ├── addresses/
│   │   ├── views/
│   │   │   ├── addresses_screen.dart
│   │   │   └── address_form_screen.dart
│   │   └── providers/
│   │       └── addresses_provider.dart
│   ├── profile/
│   │   ├── views/
│   │   │   └── profile_screen.dart
│   │   └── providers/
│   │       └── profile_provider.dart
│   ├── admin/
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── products/
│   │   │   ├── products_list_screen.dart
│   │   │   └── product_form_screen.dart
│   │   ├── inventory/
│   │   │   └── inventory_screen.dart
│   │   ├── orders/
│   │   │   ├── admin_orders_screen.dart
│   │   │   └── admin_order_detail_screen.dart
│   │   └── delivery/
│   │       └── delivery_partners_screen.dart
│   └── delivery_partner/
│       ├── views/
│       │   ├── delivery_orders_screen.dart
│       │   └── delivery_order_detail_screen.dart
│       └── providers/
│           └── delivery_provider.dart
└── main.dart
```

## Setup Steps

### 1. Install Dependencies

```bash
cd chotu_app
flutter pub get
```

### 2. Generate Code

After creating model files with json_annotation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configure API Base URL

Update `lib/core/api/api_config.dart`:

```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL:3000/api/v1';
```

For local development:
- Android emulator: `http://10.0.2.2:3000/api/v1`
- iOS simulator: `http://localhost:3000/api/v1`
- Physical device: `http://YOUR_COMPUTER_IP:3000/api/v1`

### 4. Run the App

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## Implementation Priorities

### Phase 1: Core Infrastructure (Week 1)
1. **API Client Setup**
   - Create Dio client with interceptors
   - Implement 401 handling and token refresh
   - Create Retrofit API service definitions

2. **Authentication Flow**
   - Implement splash screen with token validation
   - Create login screen
   - Create register screen
   - Setup secure storage for tokens
   - Implement auth state management with Riverpod

3. **Routing Setup**
   - Configure GoRouter with role-based guards
   - Define all route paths
   - Implement redirect logic

### Phase 2: Customer Features (Week 2-3)
1. **Catalog & Browse**
   - Home screen with categories
   - Category listing with products
   - Product detail screen
   - Search functionality

2. **Cart Management**
   - Cart screen with item management
   - Add to cart functionality
   - Quantity updates
   - Cart badge in app bar

3. **Checkout & Orders**
   - Checkout screen with address selection
   - Payment method selection
   - Order placement
   - Orders list
   - Order detail with status tracking

4. **Profile & Addresses**
   - Profile screen
   - Address management (CRUD)
   - Set default address

### Phase 3: Admin Panel (Week 4)
1. **Dashboard**
   - Basic statistics
   - Recent orders list

2. **Product Management**
   - Products list with filters
   - Create/edit product form
   - Image upload
   - Category management

3. **Order Management**
   - All orders list with filters
   - Order detail view
   - Delivery partner assignment
   - Status updates

4. **Inventory Management**
   - Inventory list
   - Stock updates

### Phase 4: Delivery Partner (Week 5)
1. **Orders View**
   - Assigned orders list
   - Order detail with customer info

2. **Status Updates**
   - Mark as out for delivery
   - Mark as delivered
   - Report delivery failures

3. **Location (Optional)**
   - Location permission handling
   - Send location updates

## Key Implementation Details

### Authentication

```dart
// auth_provider.dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthState {
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null && accessToken != null;
  bool get isCustomer => user?.role == 'customer';
  bool get isAdmin => user?.role == 'admin';
  bool get isDelivery => user?.role == 'delivery';
}
```

### API Client with Interceptor

```dart
// api_client.dart
class ApiClient {
  static Dio createDio(String? accessToken) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ));

    // Add auth token
    if (accessToken != null) {
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Add logging interceptor
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // Add error handling interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Handle token refresh or logout
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
```

### Router Configuration

```dart
// router.dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnAuthPage = state.location.startsWith('/auth');
      final isSplash = state.location == '/splash';

      if (isSplash) return null;

      if (!isAuthenticated && !isOnAuthPage) {
        return '/auth/login';
      }

      if (isAuthenticated && isOnAuthPage) {
        // Redirect to role-appropriate home
        if (authState.isAdmin) return '/admin';
        if (authState.isDelivery) return '/delivery';
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/splash', builder: (context, state) => SplashScreen()),
      GoRoute(path: '/auth/login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/auth/register', builder: (context, state) => RegisterScreen()),

      // Customer routes
      GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
      GoRoute(path: '/cart', builder: (context, state) => CartScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => CheckoutScreen()),

      // Admin routes
      GoRoute(path: '/admin', builder: (context, state) => AdminDashboard()),

      // Delivery routes
      GoRoute(path: '/delivery', builder: (context, state) => DeliveryOrdersScreen()),
    ],
  );
});
```

### Cart Management

```dart
// cart_provider.dart
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.read(apiServiceProvider));
});

class CartNotifier extends StateNotifier<CartState> {
  final ApiService _apiService;

  CartNotifier(this._apiService) : super(CartState.initial());

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true);
    try {
      final cart = await _apiService.getCart();
      state = state.copyWith(
        cart: cart,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      final cart = await _apiService.addToCart(productId, quantity);
      state = state.copyWith(cart: cart);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      final cart = await _apiService.updateCartItem(productId, quantity);
      state = state.copyWith(cart: cart);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeItem(String productId) async {
    try {
      final cart = await _apiService.removeFromCart(productId);
      state = state.copyWith(cart: cart);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
```

## UI Styling Guidelines

### Theme Configuration

```dart
// theme.dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        primary: const Color(0xFF4CAF50),
        secondary: const Color(0xFFFF9800),
      ),
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }
}
```

### Responsive Breakpoints

```dart
// utils/responsive.dart
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;
}
```

## Testing Strategy

### Unit Tests
- Test providers/business logic
- Test models serialization
- Test utilities and validators

### Widget Tests
- Test individual widgets
- Test screen layouts
- Test user interactions

### Integration Tests
- Test complete user flows
- Test API integration
- Test navigation

## Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Performance Optimization

1. **Image Optimization**
   - Use `CachedNetworkImage` for all network images
   - Implement image compression for uploads

2. **List Performance**
   - Use `ListView.builder` for long lists
   - Implement pagination for large datasets

3. **State Management**
   - Minimize rebuilds with proper provider scoping
   - Use `select` for specific state subscriptions

4. **Bundle Size**
   - Remove unused packages
   - Enable code shrinking in release builds

## Security Best Practices

1. **Token Storage**
   - Store tokens in `flutter_secure_storage`
   - Never log sensitive data

2. **API Security**
   - Always use HTTPS in production
   - Validate all user inputs
   - Implement certificate pinning (optional)

3. **Data Validation**
   - Validate all form inputs
   - Sanitize user-generated content

## Next Steps

1. Complete all model classes with proper JSON serialization
2. Implement complete API service with Retrofit
3. Create reusable UI components
4. Implement all screens per the specification
5. Add comprehensive error handling
6. Implement loading states
7. Add offline support (optional)
8. Implement push notifications (future enhancement)

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Dio Documentation](https://pub.dev/packages/dio)
