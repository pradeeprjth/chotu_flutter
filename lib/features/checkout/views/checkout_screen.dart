import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../cart/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../addresses/providers/addresses_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _paymentMethod = 'COD';
  int _selectedAddressIndex = 0;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    // Load addresses and set default address index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addressesProvider.notifier).loadAddresses();
      
      final user = ref.read(authProvider).user;
      if (user != null && user.addresses.isNotEmpty) {
        final defaultIndex = user.addresses.indexWhere((addr) => addr.isDefault);
        if (defaultIndex != -1) {
          setState(() {
            _selectedAddressIndex = defaultIndex;
          });
        }
      }
    });
  }

  Future<void> _placeOrder() async {
    final addresses = ref.read(addressesProvider).addresses;

    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a delivery address first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final order = await ref.read(ordersProvider.notifier).createOrder(
        addressIndex: _selectedAddressIndex,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        setState(() => _isPlacingOrder = false);

        if (order != null) {
          // Clear cart after successful order
          ref.read(cartProvider.notifier).clearCart();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order placed successfully! #${order.orderNumber}'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to orders screen
          context.go('/orders');
        } else {
          final error = ref.read(ordersProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to place order. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final addressesState = ref.watch(addressesProvider);
    final addresses = addressesState.addresses;
    final selectedAddress = addresses.isNotEmpty && _selectedAddressIndex < addresses.length
        ? addresses[_selectedAddressIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: cartState.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Cart is empty'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Delivery Address
                        const Text(
                          'Delivery Address',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: addresses.isNotEmpty
                                ? Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  selectedAddress?.label ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  selectedAddress?.fullAddress ?? '',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (addresses.length > 1)
                                            TextButton(
                                              onPressed: () => _showAddressSelector(context, addresses),
                                              child: const Text('Change'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  )
                                : ListTile(
                                    leading: const Icon(Icons.add_location, color: Colors.orange),
                                    title: const Text('Add Delivery Address'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => context.push('/addresses/new'),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Order Summary
                        const Text(
                          'Order Summary',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                ...cartState.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.product.name} x ${item.quantity}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        '\u20B9${item.itemTotal.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Payment Method
                        const Text(
                          'Payment Method',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                value: 'COD',
                                groupValue: _paymentMethod,
                                onChanged: (value) {
                                  setState(() => _paymentMethod = value!);
                                },
                                title: const Text('Cash on Delivery'),
                                secondary: const Icon(Icons.money),
                              ),
                              RadioListTile<String>(
                                value: 'ONLINE',
                                groupValue: _paymentMethod,
                                onChanged: (value) {
                                  setState(() => _paymentMethod = value!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Online payment integration coming soon'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                                title: const Text('Pay Online'),
                                secondary: const Icon(Icons.credit_card),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom checkout section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 14)),
                            Text('\u20B9${cartState.subtotal.toStringAsFixed(0)}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee', style: TextStyle(fontSize: 14)),
                            Text('\u20B9${cartState.deliveryCharges.toStringAsFixed(0)}'),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\u20B9${cartState.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: addresses.isEmpty || _isPlacingOrder
                                ? null
                                : _placeOrder,
                            child: _isPlacingOrder
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text('Place Order ($_paymentMethod)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showAddressSelector(BuildContext context, List addresses) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Delivery Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...addresses.asMap().entries.map((entry) {
              final index = entry.key;
              final address = entry.value;
              return RadioListTile<int>(
                value: index,
                groupValue: _selectedAddressIndex,
                onChanged: (value) {
                  setState(() {
                    _selectedAddressIndex = value!;
                  });
                  Navigator.pop(context);
                },
                title: Text(address.label),
                subtitle: Text(
                  address.fullAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/addresses/new');
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
