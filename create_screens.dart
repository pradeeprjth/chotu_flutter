import 'dart:io';

void main() {
  final screens = {
    'lib/features/auth/views/login_screen.dart': ['LoginScreen', 'Login', false],
    'lib/features/auth/views/register_screen.dart': ['RegisterScreen', 'Register', false],
    'lib/features/catalog/views/home_screen.dart': ['HomeScreen', 'Home', false],
    'lib/features/catalog/views/category_screen.dart': ['CategoryScreen', 'Category', true, 'categoryId'],
    'lib/features/catalog/views/product_detail_screen.dart': ['ProductDetailScreen', 'Product Detail', true, 'productId'],
    'lib/features/cart/views/cart_screen.dart': ['CartScreen', 'Cart', false],
    'lib/features/checkout/views/checkout_screen.dart': ['CheckoutScreen', 'Checkout', false],
    'lib/features/orders/views/orders_list_screen.dart': ['OrdersListScreen', 'Orders', false],
    'lib/features/orders/views/order_detail_screen.dart': ['OrderDetailScreen', 'Order Detail', true, 'orderId'],
    'lib/features/addresses/views/addresses_screen.dart': ['AddressesScreen', 'Addresses', false],
    'lib/features/addresses/views/address_form_screen.dart': ['AddressFormScreen', 'Address Form', true, 'addressIndex', 'int'],
    'lib/features/profile/views/profile_screen.dart': ['ProfileScreen', 'Profile', false],
    'lib/features/admin/dashboard/dashboard_screen.dart': ['AdminDashboard', 'Admin Dashboard', false],
    'lib/features/admin/products/products_list_screen.dart': ['ProductsListScreen', 'Products', false],
    'lib/features/admin/products/product_form_screen.dart': ['ProductFormScreen', 'Product Form', true, 'productId'],
    'lib/features/admin/inventory/inventory_screen.dart': ['InventoryScreen', 'Inventory', false],
    'lib/features/admin/orders/admin_orders_screen.dart': ['AdminOrdersScreen', 'Admin Orders', false],
    'lib/features/admin/orders/admin_order_detail_screen.dart': ['AdminOrderDetailScreen', 'Admin Order Detail', true, 'orderId'],
    'lib/features/admin/delivery/delivery_partners_screen.dart': ['DeliveryPartnersScreen', 'Delivery Partners', false],
    'lib/features/delivery_partner/views/delivery_orders_screen.dart': ['DeliveryOrdersScreen', 'Delivery Orders', false],
    'lib/features/delivery_partner/views/delivery_order_detail_screen.dart': ['DeliveryOrderDetailScreen', 'Delivery Order Detail', true, 'orderId'],
  };

  int created = 0;
  for (final entry in screens.entries) {
    final file = File(entry.key);
    final className = entry.value[0] as String;
    final title = entry.value[1] as String;
    final hasParam = entry.value.length > 2 ? entry.value[2] as bool : false;
    final paramName = entry.value.length > 3 ? entry.value[3] as String : '';
    final paramType = entry.value.length > 4 ? entry.value[4] as String : 'String';

    String content;
    if (hasParam) {
      content = '''
import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  final $paramType${paramType == 'int' ? '' : '?'} $paramName;

  const $className({super.key, ${paramType == 'int' ? 'required ' : ''}this.$paramName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$title')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('$title Screen'),
            if ($paramName != null)
              Text('ID: \$$paramName'),
            const SizedBox(height: 16),
            const Text('To be implemented'),
          ],
        ),
      ),
    );
  }
}
''';
    } else {
      content = '''
import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$title')),
      body: const Center(
        child: Text('$title Screen - To be implemented'),
      ),
    );
  }
}
''';
    }

    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    created++;
    print('Created: ${entry.key}');
  }

  print('\n✅ Created $created placeholder screens!');
  print('\nNext steps:');
  print('1. Run: flutter pub get');
  print('2. Run: flutter run');
}
