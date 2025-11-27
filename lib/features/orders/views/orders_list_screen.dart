import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/orders_provider.dart';
import '../../../core/models/order_model.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load orders when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadMyOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: ordersState.isLoading && ordersState.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ordersState.error != null && ordersState.orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(ordersState.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(ordersProvider.notifier).loadMyOrders(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // All orders
                    _OrdersList(
                      orders: ordersState.orders,
                      onRefresh: () => ref.read(ordersProvider.notifier).loadMyOrders(),
                      emptyMessage: 'No orders yet',
                    ),
                    // Active orders
                    _OrdersList(
                      orders: ordersState.activeOrders,
                      onRefresh: () => ref.read(ordersProvider.notifier).loadMyOrders(),
                      emptyMessage: 'No active orders',
                    ),
                    // Completed orders
                    _OrdersList(
                      orders: ordersState.completedOrders,
                      onRefresh: () => ref.read(ordersProvider.notifier).loadMyOrders(),
                      emptyMessage: 'No completed orders',
                    ),
                  ],
                ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  const _OrdersList({
    required this.orders,
    required this.onRefresh,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Your orders will appear here',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(order: order);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/orders/${order.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),

              // Date and time
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items preview
              Text(
                '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

              const Divider(height: 16),

              // Total and action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: \u20B9${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        order.paymentMethod,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color _getStatusColor() {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Text(
        OrderStatus.getDisplayText(status),
        style: TextStyle(
          fontSize: 11,
          color: _getStatusColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
