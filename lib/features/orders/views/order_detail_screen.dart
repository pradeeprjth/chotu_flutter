import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/orders_provider.dart';
import '../../../core/models/order_model.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load order details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrderById(widget.orderId);
    });
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(ordersProvider.notifier).cancelOrder(
        widget.orderId,
        reason: 'Cancelled by user',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          final error = ref.read(ordersProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to cancel order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final order = ordersState.selectedOrder;

    if (ordersState.isLoading && order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (ordersState.error != null && order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(ordersState.error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(ordersProvider.notifier).loadOrderById(widget.orderId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(ordersProvider.notifier).loadOrderById(widget.orderId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order status header
              _StatusHeader(order: order),

              // Status timeline
              _StatusTimeline(currentStatus: order.status),

              const Divider(),

              // Order items
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Items',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => _OrderItemRow(item: item)),
                  ],
                ),
              ),

              const Divider(),

              // Price breakdown
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('\u20B9${order.subtotal.toStringAsFixed(0)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee'),
                        Text('\u20B9${order.deliveryFee.toStringAsFixed(0)}'),
                      ],
                    ),
                    if (order.discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount', style: TextStyle(color: Colors.green)),
                          Text(
                            '-\u20B9${order.discount.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\u20B9${order.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Delivery address
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.deliveryAddress.label,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                order.deliveryAddress.fullAddress,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Payment info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order.paymentMethod,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          order.paymentStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: order.paymentStatus == 'PAID' || order.paymentStatus == 'SUCCESS'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Cancel button (if order can be cancelled)
              if (order.canCancel)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: ordersState.isLoading ? null : _cancelOrder,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: ordersState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cancel Order'),
                    ),
                  ),
                ),

              // Help section
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support coming soon')),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Need Help?'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final Order order;

  const _StatusHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: _getStatusColor(order.status).withOpacity(0.1),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(order.status),
            size: 48,
            color: _getStatusColor(order.status),
          ),
          const SizedBox(height: 8),
          Text(
            OrderStatus.getDisplayText(order.status),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(order.status),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (order.deliveryPartnerName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Delivery by: ${order.deliveryPartnerName}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PLACED':
        return Colors.grey;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PREPARING':
        return Colors.orange;
      case 'OUT_FOR_DELIVERY':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PLACED':
        return Icons.receipt_long;
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'PREPARING':
        return Icons.inventory_2;
      case 'OUT_FOR_DELIVERY':
        return Icons.local_shipping;
      case 'DELIVERED':
        return Icons.done_all;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;

  const _StatusTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final statuses = ['PLACED', 'CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED'];
    final isCancelled = currentStatus == 'CANCELLED';
    final currentIndex = statuses.indexOf(currentStatus);

    if (isCancelled) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Order was cancelled',
            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(statuses.length, (index) {
          final isCompleted = index <= currentIndex;
          final isLast = index == statuses.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getShortStatus(statuses[index]),
                        style: TextStyle(
                          fontSize: 8,
                          color: isCompleted ? const Color(0xFF4CAF50) : Colors.grey,
                          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < currentIndex ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getShortStatus(String status) {
    switch (status) {
      case 'PLACED':
        return 'Placed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'OUT_FOR_DELIVERY':
        return 'Shipping';
      case 'DELIVERED':
        return 'Delivered';
      default:
        return status;
    }
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${item.unit} x ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '\u20B9${item.total.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
