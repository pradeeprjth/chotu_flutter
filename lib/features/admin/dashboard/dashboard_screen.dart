import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';
import '../../../core/services/admin_service.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/metric_card.dart';
import 'widgets/dashboard_charts.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // Date range selector
          PopupMenuButton<DateRange>(
            icon: const Icon(Icons.date_range),
            tooltip: 'Date Range',
            onSelected: (range) {
              ref.read(dashboardProvider.notifier).setDateRange(range);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: DateRange.today,
                child: Text('Today'),
              ),
              const PopupMenuItem(
                value: DateRange.week,
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: DateRange.month,
                child: Text('This Month'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(dashboardProvider.notifier).loadDashboardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Navigate first, then logout to avoid blank screen
              context.go('/auth/login');
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref),
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboardState.error != null
              ? _buildError(context, ref, dashboardState.error!)
              : _buildDashboard(context, ref, dashboardState),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text('Failed to load dashboard', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(error, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(dashboardProvider.notifier).loadDashboardData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, DashboardState state) {
    final metrics = state.metrics;
    final charts = state.charts;
    if (metrics == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardProvider.notifier).loadDashboardData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue metrics
            Text('Revenue Overview', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.4,
              children: [
                MetricCard(
                  title: 'Today',
                  value: '\u20B9${_formatCurrency(metrics.revenue.today)}',
                  icon: Icons.today,
                  color: AppColors.primary,
                ),
                MetricCard(
                  title: 'This Week',
                  value: '\u20B9${_formatCurrency(metrics.revenue.week)}',
                  icon: Icons.calendar_view_week,
                  color: AppColors.info,
                ),
                MetricCard(
                  title: 'This Month',
                  value: '\u20B9${_formatCurrency(metrics.revenue.month)}',
                  icon: Icons.calendar_month,
                  color: AppColors.secondary,
                ),
                MetricCard(
                  title: 'Active Customers',
                  value: '${metrics.customers.active}',
                  icon: Icons.people,
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Order metrics
            Text('Order Statistics', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.6,
              children: [
                MetricCard(
                  title: 'Total Orders',
                  value: '${metrics.orders.total}',
                  icon: Icons.shopping_bag,
                  color: AppColors.info,
                  onTap: () => context.push('/admin/orders'),
                ),
                MetricCard(
                  title: 'Pending',
                  value: '${metrics.orders.pending}',
                  icon: Icons.pending_actions,
                  color: AppColors.warning,
                  onTap: () => context.push('/admin/orders?status=PLACED'),
                ),
                MetricCard(
                  title: 'Completed',
                  value: '${metrics.orders.completed}',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                  onTap: () => context.push('/admin/orders?status=DELIVERED'),
                ),
                MetricCard(
                  title: 'Cancelled',
                  value: '${metrics.orders.cancelled}',
                  icon: Icons.cancel,
                  color: AppColors.error,
                  onTap: () => context.push('/admin/orders?status=CANCELLED'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Alerts row
            Row(
              children: [
                Expanded(
                  child: AlertMetricCard(
                    title: 'Low Stock Items',
                    count: metrics.inventory.lowStockAlerts,
                    icon: Icons.warning_amber,
                    color: AppColors.warning,
                    onTap: () => context.push('/admin/inventory'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AlertMetricCard(
                    title: 'Available Partners',
                    count: metrics.deliveryPartners.available,
                    icon: Icons.delivery_dining,
                    color: AppColors.info,
                    onTap: () => context.push('/admin/delivery-partners'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Revenue chart
            if (charts != null) ...[
              RevenueChart(data: charts.revenueTrend),
              const SizedBox(height: AppSpacing.lg),

              // Charts row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OrdersByCategoryChart(data: charts.ordersByCategory),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // More charts
              PopularProductsChart(data: charts.popularProducts),
              const SizedBox(height: AppSpacing.lg),

              OrdersByStatusChart(data: charts.ordersByStatus),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Quick actions
            Text('Quick Actions', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _QuickActionButton(
                  icon: Icons.add_box,
                  label: 'Add Product',
                  onTap: () => context.push('/admin/products/new'),
                ),
                _QuickActionButton(
                  icon: Icons.receipt_long,
                  label: 'View Orders',
                  onTap: () => context.push('/admin/orders'),
                ),
                _QuickActionButton(
                  icon: Icons.inventory,
                  label: 'Products',
                  onTap: () => context.push('/admin/products'),
                ),
                _QuickActionButton(
                  icon: Icons.warehouse,
                  label: 'Inventory',
                  onTap: () => context.push('/admin/inventory'),
                ),
                _QuickActionButton(
                  icon: Icons.delivery_dining,
                  label: 'Delivery Partners',
                  onTap: () => context.push('/admin/delivery-partners'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recent orders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () => context.push('/admin/orders'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildRecentOrdersTable(context, state.recentOrders),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersTable(BuildContext context, List<RecentOrderData> orders) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: orders.asMap().entries.map((entry) {
          final index = entry.key;
          final order = entry.value;
          return Column(
            children: [
              _OrderListItem(
                orderNumber: order.orderNumber,
                customer: order.customerName,
                amount: order.amount,
                status: order.status,
                time: _formatTime(order.createdAt),
                onTap: () => context.push('/admin/orders/${order.id}'),
              ),
              if (index < orders.length - 1)
                const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ref.watch(authProvider).user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Orders'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/orders');
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Products'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/products');
            },
          ),
          ListTile(
            leading: const Icon(Icons.warehouse),
            title: const Text('Inventory'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/inventory');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delivery_dining),
            title: const Text('Delivery Partners'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/delivery-partners');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              // Navigate first, then logout to avoid blank screen
              context.go('/auth/login');
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final String orderNumber;
  final String customer;
  final double amount;
  final String status;
  final String time;
  final VoidCallback onTap;

  const _OrderListItem({
    required this.orderNumber,
    required this.customer,
    required this.amount,
    required this.status,
    required this.time,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'CONFIRMED':
        return AppColors.info;
      case 'PACKING':
        return AppColors.warning;
      case 'OUT_FOR_DELIVERY':
        return AppColors.secondary;
      case 'DELIVERED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(
            orderNumber,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              customer,
              style: AppTypography.bodySmall,
            ),
          ),
          Text(
            '\u20B9${amount.toStringAsFixed(0)}',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          status.replaceAll('_', ' '),
          style: TextStyle(
            fontSize: 9,
            color: _getStatusColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
