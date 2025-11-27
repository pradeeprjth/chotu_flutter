import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/admin_service.dart';
import '../delivery/providers/admin_delivery_partners_provider.dart';
import 'providers/admin_orders_provider.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';

// Order notes provider (in a real app, this would be persisted)
final orderNotesProvider = StateProvider.family<String, String>((ref, orderId) => '');

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const AdminOrderDetailScreen({super.key, this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _notesController.text = '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(adminOrderDetailProvider(widget.orderId ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          orderAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (order) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'Print Invoice',
                  onPressed: () => _printInvoice(order),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share',
                  onPressed: () => _shareOrder(order),
                ),
              ],
            ),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(error.toString()),
        data: (order) => _buildOrderDetails(order),
      ),
    );
  }

  Widget _buildError([String? error]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text('Order not found', style: AppTypography.titleMedium.copyWith(color: context.textPrimary)),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(error, style: AppTypography.bodySmall.copyWith(color: context.textSecondary)),
          ],
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(AdminOrder order) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminOrderDetailProvider(widget.orderId ?? ''));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order status card
            _buildStatusCard(order),
            const SizedBox(height: AppSpacing.md),

            // Quick actions
            _buildQuickActions(order),
            const SizedBox(height: AppSpacing.md),

            // Customer info
            _buildCustomerCard(order),
            const SizedBox(height: AppSpacing.md),

            // Delivery info
            _buildDeliveryCard(order),
            const SizedBox(height: AppSpacing.md),

            // Delivery partner info
            if (order.deliveryPartner != null)
              _buildDeliveryPartnerCard(order)
            else if (order.orderStatus != 'DELIVERED' && order.orderStatus != 'CANCELLED')
              _buildAssignPartnerCard(order),
            const SizedBox(height: AppSpacing.md),

            // Order items
            _buildOrderItemsCard(order),
            const SizedBox(height: AppSpacing.md),

            // Payment details
            _buildPaymentCard(order),
            const SizedBox(height: AppSpacing.md),

            // Order notes
            _buildNotesCard(order),
            const SizedBox(height: AppSpacing.md),

            // Timeline
            _buildTimelineCard(order),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AdminOrder order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(order.orderStatus),
            _getStatusColor(order.orderStatus).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStatusDisplayText(order.orderStatus),
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  order.paymentStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Placed ${_formatDateTime(order.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '\u20B9${order.totalAmount.toStringAsFixed(0)}',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AdminOrder order) {
    final actions = _getAvailableActions(order.orderStatus);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTypography.titleSmall.copyWith(color: context.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: actions.map((action) {
              return ElevatedButton(
                onPressed: () => _updateOrderStatus(order.id, action['status']!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action['color'] as Color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: Text(action['label']!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableActions(String status) {
    switch (status) {
      case 'PLACED':
        return [
          {'status': 'CONFIRMED', 'label': 'Confirm Order', 'color': AppColors.info},
          {'status': 'CANCELLED', 'label': 'Cancel', 'color': AppColors.error},
        ];
      case 'CONFIRMED':
        return [
          {'status': 'PREPARING', 'label': 'Start Preparing', 'color': AppColors.warning},
          {'status': 'CANCELLED', 'label': 'Cancel', 'color': AppColors.error},
        ];
      case 'PREPARING':
        return [
          {'status': 'OUT_FOR_DELIVERY', 'label': 'Out for Delivery', 'color': AppColors.secondary},
        ];
      case 'OUT_FOR_DELIVERY':
        return [
          {'status': 'DELIVERED', 'label': 'Mark Delivered', 'color': AppColors.success},
        ];
      default:
        return [];
    }
  }

  Widget _buildCustomerCard(AdminOrder order) {
    final customerName = order.user['name'] ?? 'Unknown';
    final customerPhone = order.user['phone'] ?? '-';
    final customerEmail = order.user['email'] ?? '-';

    return _buildInfoCard(
      title: 'Customer Details',
      icon: Icons.person,
      children: [
        _InfoRow(label: 'Name', value: customerName),
        _InfoRow(label: 'Phone', value: customerPhone),
        _InfoRow(label: 'Email', value: customerEmail),
      ],
    );
  }

  Widget _buildDeliveryCard(AdminOrder order) {
    final addressLine1 = order.deliveryAddress['addressLine1'] ?? '';
    final addressLine2 = order.deliveryAddress['addressLine2'] ?? '';
    final city = order.deliveryAddress['city'] ?? '';
    final state = order.deliveryAddress['state'] ?? '';
    final pincode = order.deliveryAddress['pincode'] ?? '';
    final landmark = order.deliveryAddress['landmark'] ?? '';

    return _buildInfoCard(
      title: 'Delivery Address',
      icon: Icons.location_on,
      children: [
        _InfoRow(label: 'Address', value: addressLine1),
        if (addressLine2.isNotEmpty)
          _InfoRow(label: '', value: addressLine2),
        _InfoRow(label: 'City', value: '$city, $state'),
        _InfoRow(label: 'Pincode', value: pincode),
        if (landmark.isNotEmpty)
          _InfoRow(label: 'Landmark', value: landmark),
      ],
    );
  }

  Widget _buildDeliveryPartnerCard(AdminOrder order) {
    // Handle both formats: { user: { name, phone }, vehicleType, vehicleNumber }
    // or direct user populate: { name, phone }
    final partnerData = order.deliveryPartner;
    final partnerName = partnerData?['user']?['name'] ?? partnerData?['name'] ?? 'Unknown';
    final partnerPhone = partnerData?['user']?['phone'] ?? partnerData?['phone'] ?? '-';
    final vehicleType = partnerData?['vehicleType'] ?? '-';
    final vehicleNumber = partnerData?['vehicleNumber'] ?? '-';

    return _buildInfoCard(
      title: 'Delivery Partner',
      icon: Icons.delivery_dining,
      children: [
        _InfoRow(label: 'Name', value: partnerName),
        _InfoRow(label: 'Phone', value: partnerPhone),
        _InfoRow(label: 'Vehicle', value: '$vehicleType - $vehicleNumber'),
        _InfoRow(
          label: 'Status',
          value: order.orderStatus == 'OUT_FOR_DELIVERY' ? 'En Route' : 'Assigned',
        ),
      ],
    );
  }

  Widget _buildAssignPartnerCard(AdminOrder order) {
    // Check if order is in an assignable status
    final assignableStatuses = ['CONFIRMED', 'PREPARING'];
    final canAssign = assignableStatuses.contains(order.orderStatus);
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: canAssign
            ? AppColors.warning.withValues(alpha: 0.1)
            : (isDark ? AppColors.grey800 : AppColors.grey100),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: canAssign
              ? AppColors.warning.withValues(alpha: 0.3)
              : (isDark ? AppColors.grey700 : AppColors.grey300),
        ),
      ),
      child: Row(
        children: [
          Icon(
            canAssign ? Icons.warning_amber : Icons.info_outline,
            color: canAssign ? AppColors.warning : context.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Delivery Partner Assigned',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  canAssign
                      ? 'Assign a delivery partner to proceed'
                      : 'Confirm the order first to assign a delivery partner',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canAssign ? () => _showAssignPartnerDialog(order.id) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAssign ? AppColors.warning : (isDark ? AppColors.grey700 : AppColors.grey300),
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark ? AppColors.grey700 : AppColors.grey300,
              disabledForegroundColor: context.textSecondary,
            ),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.titleSmall.copyWith(color: context.textPrimary)),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(AdminOrder order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary;
    final surfaceColor = isDark ? AppColors.grey800 : AppColors.grey100;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Order Items (${order.items.length})', style: AppTypography.titleSmall.copyWith(color: textColor)),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          ...order.items.map((item) {
            final productName = item['product']?['name'] ?? 'Unknown Product';
            final quantity = item['quantity'] ?? 0;
            final price = (item['price'] ?? 0).toDouble();
            final total = quantity * price;
            final imageUrl = (item['product']?['images'] as List?)?.isNotEmpty == true
                ? item['product']['images'][0] as String
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  // Item image
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl == null
                        ? Icon(Icons.image, color: AppColors.grey400)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '$quantity x \u20B9${price.toStringAsFixed(0)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\u20B9${total.toStringAsFixed(0)}',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(AdminOrder order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Payment Details', style: AppTypography.titleSmall.copyWith(color: context.textPrimary)),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _PaymentRow(label: 'Total', value: '\u20B9${order.totalAmount.toStringAsFixed(0)}', isBold: true),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: AppTypography.labelSmall.copyWith(color: context.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: context.subtleSurface,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  order.paymentMethod,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(AdminOrder order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.note, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Order Notes', style: AppTypography.titleSmall.copyWith(color: context.textPrimary)),
                ],
              ),
              IconButton(
                icon: Icon(_isEditingNotes ? Icons.check : Icons.edit, size: 18),
                onPressed: () {
                  if (_isEditingNotes) {
                    // Save notes
                    ref.read(orderNotesProvider(order.id).notifier).state = _notesController.text;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notes saved'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                  setState(() {
                    _isEditingNotes = !_isEditingNotes;
                  });
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(AppSpacing.sm),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_isEditingNotes)
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add notes about this order...',
                border: OutlineInputBorder(),
              ),
            )
          else
            Text(
              _notesController.text.isEmpty
                  ? 'No notes added'
                  : _notesController.text,
              style: AppTypography.bodySmall.copyWith(
                color: _notesController.text.isEmpty
                    ? context.textTertiary
                    : context.textPrimary,
                fontStyle: _notesController.text.isEmpty ? FontStyle.italic : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(AdminOrder order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Order Timeline', style: AppTypography.titleSmall.copyWith(color: context.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _TimelineItem(
            title: 'Order Placed',
            time: _formatDateTime(order.createdAt),
            isCompleted: true,
            isFirst: true,
          ),
          _TimelineItem(
            title: 'Confirmed',
            time: order.orderStatus != 'PLACED' ? _formatDateTime(order.createdAt) : null,
            isCompleted: order.orderStatus != 'PLACED',
          ),
          _TimelineItem(
            title: 'Preparing',
            time: null,
            isCompleted: ['PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED'].contains(order.orderStatus),
          ),
          _TimelineItem(
            title: 'Out for Delivery',
            time: order.deliveryAssignedAt != null ? _formatDateTime(order.deliveryAssignedAt!) : null,
            isCompleted: ['OUT_FOR_DELIVERY', 'DELIVERED'].contains(order.orderStatus),
          ),
          _TimelineItem(
            title: 'Delivered',
            time: order.deliveredAt != null ? _formatDateTime(order.deliveredAt!) : null,
            isCompleted: order.orderStatus == 'DELIVERED',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PLACED':
        return AppColors.grey500;
      case 'CONFIRMED':
        return AppColors.info;
      case 'PREPARING':
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

  String _getStatusDisplayText(String status) {
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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM, hh:mm a').format(dateTime);
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final success = await ref.read(adminOrdersProvider.notifier).updateOrderStatus(orderId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Status updated to ${_getStatusDisplayText(newStatus)}'
              : 'Failed to update status'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        ref.invalidate(adminOrderDetailProvider(orderId));
      }
    }
  }

  void _showAssignPartnerDialog(String orderId) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final partners = ref.watch(availableDeliveryPartnersProvider);

          return AlertDialog(
            title: const Text('Assign Delivery Partner'),
            content: SizedBox(
              width: 300,
              child: partners.when(
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
                data: (partnersList) {
                  if (partnersList.isEmpty) {
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

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: partnersList.map((partner) {
                        final name = partner.user['name'] ?? 'Unknown';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.success.withOpacity(0.1),
                            child: Icon(
                              Icons.delivery_dining,
                              color: AppColors.success,
                              size: 20,
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(
                            '${partner.vehicleType} - ${partner.vehicleNumber}',
                            style: AppTypography.labelSmall,
                          ),
                          onTap: () => Navigator.pop(context, partner.id),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      final success = await ref.read(adminOrdersProvider.notifier).assignDeliveryPartner(orderId, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Delivery partner assigned' : 'Failed to assign'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) {
          ref.invalidate(adminOrderDetailProvider(orderId));
        }
      }
    }
  }

  void _printInvoice(AdminOrder order) {
    // Generate invoice text
    final invoice = StringBuffer();
    invoice.writeln('='.padLeft(40, '='));
    invoice.writeln('INVOICE');
    invoice.writeln('='.padLeft(40, '='));
    invoice.writeln('');
    invoice.writeln('Order: ${order.orderNumber}');
    invoice.writeln('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}');
    invoice.writeln('');
    invoice.writeln('Items:');
    invoice.writeln('-'.padLeft(40, '-'));

    for (final item in order.items) {
      final name = item['product']?['name'] ?? 'Unknown';
      final qty = item['quantity'] ?? 0;
      final price = item['price'] ?? 0;
      final total = qty * price;
      invoice.writeln('$name');
      invoice.writeln('  $qty x \u20B9$price = \u20B9$total');
    }

    invoice.writeln('-'.padLeft(40, '-'));
    invoice.writeln('='.padLeft(40, '='));
    invoice.writeln('TOTAL: \u20B9${order.totalAmount}');
    invoice.writeln('='.padLeft(40, '='));
    invoice.writeln('');
    invoice.writeln('Payment: ${order.paymentMethod} (${order.paymentStatus})');
    invoice.writeln('');
    invoice.writeln('Delivery Address:');
    invoice.writeln(order.deliveryAddress['addressLine1'] ?? '');
    invoice.writeln('${order.deliveryAddress['city']}, ${order.deliveryAddress['state']}');
    invoice.writeln(order.deliveryAddress['pincode'] ?? '');

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: invoice.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareOrder(AdminOrder order) {
    final shareText = '''
Order: ${order.orderNumber}
Status: ${_getStatusDisplayText(order.orderStatus)}
Total: \u20B9${order.totalAmount}
Items: ${order.items.length}
Date: ${DateFormat('dd MMM yyyy').format(order.createdAt)}
''';

    Clipboard.setData(ClipboardData(text: shareText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order details copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _PaymentRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: context.textPrimary)
                : AppTypography.labelSmall.copyWith(color: context.textSecondary),
          ),
          Text(
            value,
            style: isBold
                ? AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: context.textPrimary)
                : AppTypography.labelMedium.copyWith(color: valueColor ?? context.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String? time;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    this.time,
    required this.isCompleted,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final inactiveColor = isDark ? AppColors.grey600 : AppColors.grey300;
    final inactiveLineColor = isDark ? AppColors.grey700 : AppColors.grey200;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.success : inactiveColor,
                border: Border.all(
                  color: isCompleted ? AppColors.success : inactiveColor,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? AppColors.success : inactiveLineColor,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                  color: isCompleted ? context.textPrimary : context.textTertiary,
                ),
              ),
              if (time != null)
                Text(
                  time!,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              if (!isLast) const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ],
    );
  }
}
