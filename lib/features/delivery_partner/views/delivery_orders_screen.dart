import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/delivery_provider.dart';
import '../../../core/models/order_model.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';

class DeliveryOrdersScreen extends ConsumerStatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  ConsumerState<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends ConsumerState<DeliveryOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load profile and deliveries when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final deliveryState = ref.watch(deliveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(deliveryProvider.notifier).loadAll(),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => _showProfileSheet(context, ref, authState, deliveryState),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats and earnings section
          _buildStatsSection(deliveryState),

          // Tab bar
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Assigned'),
                      if (deliveryState.assignedCount > 0) ...[
                        const SizedBox(width: 4),
                        _Badge(count: deliveryState.assignedCount, color: AppColors.warning),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('En Route'),
                      if (deliveryState.enRouteCount > 0) ...[
                        const SizedBox(width: 4),
                        _Badge(count: deliveryState.enRouteCount, color: AppColors.info),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Completed'),
              ],
            ),
          ),

          // Order lists
          Expanded(
            child: deliveryState.isLoadingOrders && deliveryState.orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : deliveryState.ordersError != null && deliveryState.orders.isEmpty
                    ? _buildErrorState(deliveryState.ordersError!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _DeliveryOrdersList(
                            orders: deliveryState.assignedOrders,
                            status: 'PREPARING',
                            isUpdating: deliveryState.isUpdatingStatus,
                            onRefresh: () => ref.read(deliveryProvider.notifier).loadDeliveries(),
                            onUpdateStatus: _updateDeliveryStatus,
                          ),
                          _DeliveryOrdersList(
                            orders: deliveryState.enRouteOrders,
                            status: 'OUT_FOR_DELIVERY',
                            isUpdating: deliveryState.isUpdatingStatus,
                            onRefresh: () => ref.read(deliveryProvider.notifier).loadDeliveries(),
                            onUpdateStatus: _updateDeliveryStatus,
                          ),
                          _DeliveryOrdersList(
                            orders: deliveryState.completedOrders,
                            status: 'DELIVERED',
                            isUpdating: deliveryState.isUpdatingStatus,
                            onRefresh: () => ref.read(deliveryProvider.notifier).loadDeliveries(),
                            onUpdateStatus: _updateDeliveryStatus,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(DeliveryState deliveryState) {
    final stats = deliveryState.stats;
    final isLoading = deliveryState.isLoadingProfile;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Earnings row
          Row(
            children: [
              Expanded(
                child: _EarningsCard(
                  title: "Today's Earnings",
                  amount: stats.todayEarnings,
                  icon: Icons.today,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _EarningsCard(
                  title: "This Week",
                  amount: stats.weekEarnings,
                  icon: Icons.calendar_view_week,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Stats row
          Row(
            children: [
              _StatItem(
                icon: Icons.assignment,
                label: 'Pending',
                count: deliveryState.assignedCount,
                color: AppColors.warning,
              ),
              _StatItem(
                icon: Icons.local_shipping,
                label: 'En Route',
                count: deliveryState.enRouteCount,
                color: AppColors.info,
              ),
              _StatItem(
                icon: Icons.check_circle,
                label: 'Today',
                count: stats.todayDeliveries,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text('Failed to load deliveries', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(error, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => ref.read(deliveryProvider.notifier).loadAll(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref, AuthState authState, DeliveryState deliveryState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Profile info
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text(
                  authState.user?.name.isNotEmpty == true
                      ? authState.user!.name[0].toUpperCase()
                      : 'D',
                  style: const TextStyle(color: Colors.white, fontSize: 28),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                authState.user?.name ?? deliveryState.profile?.name ?? 'Delivery Partner',
                style: AppTypography.titleLarge,
              ),
              Text(
                authState.user?.phone ?? deliveryState.profile?.phone ?? '',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Stats summary
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ProfileStat(
                      label: 'Total Deliveries',
                      value: '${deliveryState.stats.totalDeliveries}',
                    ),
                    _ProfileStat(
                      label: 'Total Earnings',
                      value: '\u20B9${deliveryState.stats.totalEarnings.toStringAsFixed(0)}',
                    ),
                    _ProfileStat(
                      label: 'Rating',
                      value: deliveryState.profile?.rating.toStringAsFixed(1) ?? '0.0',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Availability toggle
              SwitchListTile(
                title: const Text('Available for Deliveries'),
                subtitle: Text(
                  deliveryState.isAvailable ? 'You can receive new orders' : 'You will not receive new orders',
                  style: AppTypography.bodySmall,
                ),
                value: deliveryState.isAvailable,
                activeColor: AppColors.primary,
                onChanged: deliveryState.isLoadingProfile
                    ? null
                    : (value) async {
                        final success = await ref.read(deliveryProvider.notifier).toggleAvailability();
                        if (success && context.mounted) {
                          setModalState(() {});
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.md),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    ref.read(deliveryProvider.notifier).clearState();
                    context.go('/auth/login');
                    await ref.read(authProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text('Logout', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateDeliveryStatus(String orderId, String newStatus) async {
    final success = await ref.read(deliveryProvider.notifier).updateDeliveryStatus(orderId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status updated to ${OrderStatus.getDisplayText(newStatus)}'
                : 'Failed to update status',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

/// Profile stat widget
class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Earnings card widget
class _EarningsCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final bool isLoading;

  const _EarningsCard({
    required this.title,
    required this.amount,
    required this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: AppSpacing.sm),
          isLoading
              ? Container(
                  width: 60,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  '\u20B9${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge widget
class _Badge extends StatelessWidget {
  final int count;
  final Color color;

  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DeliveryOrdersList extends StatelessWidget {
  final List<Order> orders;
  final String status;
  final bool isUpdating;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String orderId, String newStatus) onUpdateStatus;

  const _DeliveryOrdersList({
    required this.orders,
    required this.status,
    required this.isUpdating,
    required this.onRefresh,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'DELIVERED' ? Icons.check_circle_outline : Icons.inbox_outlined,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              status == 'DELIVERED' ? 'No delivered orders yet' : 'No orders in this category',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _DeliveryOrderCard(
            order: order,
            isUpdating: isUpdating,
            onPickUp: () => onUpdateStatus(order.id, 'OUT_FOR_DELIVERY'),
            onDeliver: () => onUpdateStatus(order.id, 'DELIVERED'),
            onViewDetails: () => context.push('/delivery/orders/${order.id}'),
          );
        },
      ),
    );
  }
}

class _DeliveryOrderCard extends StatelessWidget {
  final Order order;
  final bool isUpdating;
  final VoidCallback onPickUp;
  final VoidCallback onDeliver;
  final VoidCallback onViewDetails;

  const _DeliveryOrderCard({
    required this.order,
    required this.isUpdating,
    required this.onPickUp,
    required this.onDeliver,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd MMM, hh:mm a').format(order.createdAt),
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\u20B9${order.total.toStringAsFixed(0)}',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: order.paymentMethod == 'COD'
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.paymentMethod == 'COD' ? 'COD' : 'Paid',
                          style: TextStyle(
                            fontSize: 10,
                            color: order.paymentMethod == 'COD' ? AppColors.warning : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),

              // Customer info
              if (order.customerName != null && order.customerName!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      order.customerName!,
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
              ],

              // Delivery address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 18, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.deliveryAddress.label,
                          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          order.deliveryAddress.fullAddress,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Call/Navigate buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, color: AppColors.primary),
                        iconSize: 20,
                        onPressed: () => _makePhoneCall(order.customerPhone),
                        tooltip: 'Call Customer',
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigation, color: AppColors.info),
                        iconSize: 20,
                        onPressed: () => _openMaps(order.deliveryAddress.fullAddress),
                        tooltip: 'Navigate',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Items count
              Text(
                '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),

              // Action button
              if (order.status == 'PREPARING' || order.status == 'CONFIRMED')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isUpdating ? null : onPickUp,
                    icon: isUpdating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.local_shipping, size: 18),
                    label: const Text('Start Delivery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                )
              else if (order.status == 'OUT_FOR_DELIVERY')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isUpdating ? null : onDeliver,
                    icon: isUpdating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle, size: 18),
                    label: const Text('Mark as Delivered'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                )
              else if (order.status == 'DELIVERED')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Delivered',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
