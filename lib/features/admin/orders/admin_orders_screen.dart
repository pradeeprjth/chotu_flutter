import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/admin_service.dart';
import '../delivery/providers/admin_delivery_partners_provider.dart';
import 'providers/admin_orders_provider.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';

// Local UI state providers
final showFiltersProvider = StateProvider<bool>((ref) => false);

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    // Listen for tab changes to trigger server-side filtering
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final statuses = [null, 'PLACED', 'CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'];
      final status = statuses[_tabController.index];
      ref.read(adminOrdersProvider.notifier).filterByStatus(status);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(adminOrdersProvider);
    final showFilters = ref.watch(showFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          IconButton(
            icon: Icon(
              showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: showFilters ? AppColors.primary : null,
            ),
            tooltip: 'Filters',
            onPressed: () {
              ref.read(showFiltersProvider.notifier).state = !showFilters;
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _exportOrders(ordersState.orders);
              } else if (value == 'refresh') {
                ref.read(adminOrdersProvider.notifier).loadOrders(refresh: true);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export to Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(showFilters ? 170 : 48),
          child: Column(
            children: [
              if (showFilters) _buildFiltersBar(),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Placed'),
                  Tab(text: 'Confirmed'),
                  Tab(text: 'Preparing'),
                  Tab(text: 'Out for Delivery'),
                  Tab(text: 'Delivered'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ordersState.isLoading && ordersState.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ordersState.error != null && ordersState.orders.isEmpty
              ? _buildError(context, ref, ordersState.error!)
              : _buildOrdersContent(ordersState),
    );
  }

  Widget _buildOrdersContent(AdminOrdersState ordersState) {
    // Since we're now using server-side filtering, all tabs show the same filtered data
    return _AdminOrdersList(
      orders: ordersState.orders,
      isLoading: ordersState.isLoading,
      hasMore: ordersState.pagination != null &&
               ordersState.pagination!.page < ordersState.pagination!.totalPages,
      onRefresh: () => ref.read(adminOrdersProvider.notifier).loadOrders(refresh: true),
      onLoadMore: () => ref.read(adminOrdersProvider.notifier).loadNextPage(),
      onStatusChange: _updateStatus,
      onAssignPartner: _assignDeliveryPartner,
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text('Failed to load orders', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(error, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(adminOrdersProvider.notifier).loadOrders(refresh: true);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    final ordersState = ref.watch(adminOrdersProvider);
    final searchQuery = ordersState.searchQuery;
    final statusFilter = ordersState.statusFilter;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active filters summary
          if (searchQuery.isNotEmpty || statusFilter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (searchQuery.isNotEmpty)
                    _FilterChip(
                      label: 'Search: $searchQuery',
                      onDelete: () => ref.read(adminOrdersProvider.notifier).search(''),
                    ),
                  if (statusFilter != null)
                    _FilterChip(
                      label: 'Status: ${statusFilter.replaceAll('_', ' ')}',
                      onDelete: () {
                        ref.read(adminOrdersProvider.notifier).filterByStatus(null);
                        _tabController.animateTo(0);
                      },
                    ),
                ],
              ),
            ),
          // Summary info
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                ordersState.pagination != null
                    ? 'Showing ${ordersState.orders.length} of ${ordersState.pagination!.total} orders'
                    : 'Loading...',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              // Clear filters
              if (searchQuery.isNotEmpty || statusFilter != null)
                TextButton(
                  onPressed: () {
                    ref.read(adminOrdersProvider.notifier).search('');
                    ref.read(adminOrdersProvider.notifier).filterByStatus(null);
                    _tabController.animateTo(0);
                  },
                  child: const Text('Clear Filters'),
                ),
            ],
          ),
        ],
      ),
    );
  }


  void _showSearchDialog(BuildContext context) {
    _searchController.text = ref.read(adminOrdersProvider).searchQuery;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Orders'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Order ID, customer name...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            ref.read(adminOrdersProvider.notifier).search(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(adminOrdersProvider.notifier).search(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }


  Future<void> _updateStatus(String orderId, String newStatus) async {
    final success = await ref.read(adminOrdersProvider.notifier).updateOrderStatus(orderId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Status updated to ${newStatus.replaceAll('_', ' ')}' : 'Failed to update status'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _assignDeliveryPartner(String orderId) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AssignDeliveryPartnerDialog(orderId: orderId),
    );

    if (result != null && mounted) {
      final success = await ref.read(adminOrdersProvider.notifier).assignDeliveryPartner(orderId, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Delivery partner assigned' : 'Failed to assign delivery partner'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  void _exportOrders(List<AdminOrder> orders) {
    // Generate CSV content
    final buffer = StringBuffer();
    buffer.writeln('Order Number,Date,Status,Payment Method,Payment Status,Customer,Amount,Delivery Partner');

    for (final order in orders) {
      final customerName = order.user['name'] ?? 'Unknown';
      final address = order.deliveryAddress['addressLine1'] ?? '';
      final partnerName = order.deliveryPartner?['user']?['name'] ?? 'Not Assigned';
      buffer.writeln(
        '${order.orderNumber},'
        '${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)},'
        '${order.orderStatus},'
        '${order.paymentMethod},'
        '${order.paymentStatus},'
        '"$customerName - $address",'
        '${order.totalAmount},'
        '$partnerName'
      );
    }

    // Copy to clipboard for now (in a real app, this would save to file)
    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order data copied to clipboard (CSV format)'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _AdminOrdersList extends StatelessWidget {
  final List<AdminOrder> orders;
  final bool isLoading;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Future<void> Function(String orderId, String newStatus) onStatusChange;
  final Future<void> Function(String orderId) onAssignPartner;

  const _AdminOrdersList({
    required this.orders,
    required this.isLoading,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onStatusChange,
    required this.onAssignPartner,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.grey300),
            const SizedBox(height: AppSpacing.md),
            Text('No orders found', style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try adjusting your filters',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              hasMore &&
              !isLoading) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: orders.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= orders.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final order = orders[index];
            return _AdminOrderCard(
              order: order,
              onStatusChange: onStatusChange,
              onAssignPartner: onAssignPartner,
            );
          },
        ),
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final AdminOrder order;
  final Future<void> Function(String orderId, String newStatus) onStatusChange;
  final Future<void> Function(String orderId) onAssignPartner;

  const _AdminOrderCard({
    required this.order,
    required this.onStatusChange,
    required this.onAssignPartner,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = order.user['name'] ?? 'Unknown Customer';
    final addressLine = order.deliveryAddress['addressLine1'] ?? '';
    final city = order.deliveryAddress['city'] ?? '';
    final deliveryPartnerName = order.deliveryPartner?['user']?['name'];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => context.push('/admin/orders/${order.id}'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        order.orderNumber,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _PaymentBadge(method: order.paymentMethod),
                    ],
                  ),
                  Text(
                    '\u20B9${order.totalAmount.toStringAsFixed(0)}',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.priceGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Customer name
              Text(
                customerName,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Date and items
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(order.createdAt),
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Address
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$addressLine, $city',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              // Status row with quick actions
              Row(
                children: [
                  _StatusBadge(status: order.orderStatus),
                  const SizedBox(width: AppSpacing.sm),
                  // Payment status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: order.paymentStatus == 'PAID'
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      order.paymentStatus,
                      style: TextStyle(
                        fontSize: 9,
                        color: order.paymentStatus == 'PAID' ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Quick actions
                  if (order.orderStatus == 'PREPARING' || order.orderStatus == 'CONFIRMED')
                    IconButton(
                      onPressed: () => onAssignPartner(order.id),
                      icon: Icon(
                        order.deliveryPartner != null ? Icons.person : Icons.person_add,
                        size: 20,
                        color: order.deliveryPartner != null ? AppColors.success : AppColors.warning,
                      ),
                      tooltip: order.deliveryPartner != null
                          ? 'Partner: $deliveryPartnerName'
                          : 'Assign Delivery Partner',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                    ),
                  IconButton(
                    onPressed: () => context.push('/admin/orders/${order.id}'),
                    icon: const Icon(Icons.print_outlined, size: 20),
                    tooltip: 'Print Invoice',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                  ),
                  // Quick status dropdown
                  _QuickStatusDropdown(
                    currentStatus: order.orderStatus,
                    onStatusChange: (newStatus) => onStatusChange(order.id, newStatus),
                  ),
                ],
              ),
              // Delivery partner info
              if (deliveryPartnerName != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.delivery_dining, size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(
                      deliveryPartnerName,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.info),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatusDropdown extends StatelessWidget {
  final String currentStatus;
  final Function(String) onStatusChange;

  const _QuickStatusDropdown({
    required this.currentStatus,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildStatusMenuItems(currentStatus);
    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      onSelected: onStatusChange,
      icon: const Icon(Icons.more_vert, size: 20),
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemBuilder: (context) => items,
    );
  }

  List<PopupMenuItem<String>> _buildStatusMenuItems(String currentStatus) {
    final items = <PopupMenuItem<String>>[];

    switch (currentStatus) {
      case 'PLACED':
        items.add(const PopupMenuItem(value: 'CONFIRMED', child: Text('Confirm Order')));
        items.add(const PopupMenuItem(value: 'CANCELLED', child: Text('Cancel', style: TextStyle(color: AppColors.error))));
        break;
      case 'CONFIRMED':
        items.add(const PopupMenuItem(value: 'PREPARING', child: Text('Start Preparing')));
        items.add(const PopupMenuItem(value: 'CANCELLED', child: Text('Cancel', style: TextStyle(color: AppColors.error))));
        break;
      case 'PREPARING':
        items.add(const PopupMenuItem(value: 'OUT_FOR_DELIVERY', child: Text('Out for Delivery')));
        break;
      case 'OUT_FOR_DELIVERY':
        items.add(const PopupMenuItem(value: 'DELIVERED', child: Text('Mark Delivered')));
        break;
    }

    return items;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  static String _getDisplayText(String status) {
    switch (status) {
      case 'PLACED':
        return 'Placed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'PLACED':
        color = AppColors.grey500;
        break;
      case 'CONFIRMED':
        color = AppColors.info;
        break;
      case 'PREPARING':
        color = AppColors.warning;
        break;
      case 'OUT_FOR_DELIVERY':
        color = AppColors.secondary;
        break;
      case 'DELIVERED':
        color = AppColors.success;
        break;
      case 'CANCELLED':
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getDisplayText(status),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String method;

  const _PaymentBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        method,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 9,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _FilterChip({
    required this.label,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _AssignDeliveryPartnerDialog extends ConsumerStatefulWidget {
  final String orderId;

  const _AssignDeliveryPartnerDialog({required this.orderId});

  @override
  ConsumerState<_AssignDeliveryPartnerDialog> createState() => _AssignDeliveryPartnerDialogState();
}

class _AssignDeliveryPartnerDialogState extends ConsumerState<_AssignDeliveryPartnerDialog> {
  String? _selectedPartnerId;

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(availableDeliveryPartnersProvider);

    return AlertDialog(
      title: const Text('Assign Delivery Partner'),
      content: SizedBox(
        width: 300,
        child: partnersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: AppSpacing.sm),
                Text('Failed to load partners', style: AppTypography.bodySmall),
                TextButton(
                  onPressed: () => ref.invalidate(availableDeliveryPartnersProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (partners) {
            if (partners.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off_outlined, color: AppColors.grey400, size: 48),
                    const SizedBox(height: AppSpacing.sm),
                    Text('No available partners', style: AppTypography.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'All delivery partners are currently busy',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: partners.map((partner) {
                final name = partner.user['name'] ?? 'Unknown';
                return RadioListTile<String>(
                  value: partner.id,
                  groupValue: _selectedPartnerId,
                  onChanged: (value) {
                    setState(() {
                      _selectedPartnerId = value;
                    });
                  },
                  title: Text(name),
                  subtitle: Text(
                    '${partner.vehicleType} - ${partner.vehicleNumber}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  secondary: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.success.withOpacity(0.1),
                    child: Icon(
                      Icons.delivery_dining,
                      size: 16,
                      color: AppColors.success,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedPartnerId != null
              ? () => Navigator.pop(context, _selectedPartnerId)
              : null,
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
