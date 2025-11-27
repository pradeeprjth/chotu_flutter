import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/delivery_provider.dart';
import '../../../core/models/order_model.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';

class DeliveryOrderDetailScreen extends ConsumerWidget {
  final String? orderId;

  const DeliveryOrderDetailScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryState = ref.watch(deliveryProvider);

    // Find the order from the delivery state
    final order = deliveryState.orders.where((o) => o.id == orderId).firstOrNull;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
              const SizedBox(height: AppSpacing.md),
              Text('Order not found', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            tooltip: 'Call Customer',
            onPressed: () => _makePhoneCall(order.customerPhone),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            _StatusBanner(order: order),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info card
                  _SectionCard(
                    title: 'Customer',
                    icon: Icons.person,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.customerName ?? 'Customer',
                                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (order.customerPhone != null)
                                    Text(
                                      order.customerPhone!,
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone, color: AppColors.primary),
                              onPressed: () => _makePhoneCall(order.customerPhone),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Delivery address card
                  _SectionCard(
                    title: 'Delivery Address',
                    icon: Icons.location_on,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      order.deliveryAddress.label,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    order.deliveryAddress.addressLine1,
                                    style: AppTypography.bodyMedium,
                                  ),
                                  if (order.deliveryAddress.addressLine2?.isNotEmpty == true)
                                    Text(
                                      order.deliveryAddress.addressLine2!,
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  Text(
                                    '${order.deliveryAddress.city}, ${order.deliveryAddress.state} - ${order.deliveryAddress.pincode}',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                  if (order.deliveryAddress.landmark?.isNotEmpty == true) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        Icon(Icons.near_me, size: 14, color: AppColors.textTertiary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Near: ${order.deliveryAddress.landmark}',
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.navigation, color: AppColors.info),
                              onPressed: () => _openMaps(order.deliveryAddress.fullAddress),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openMaps(order.deliveryAddress.fullAddress),
                            icon: const Icon(Icons.directions),
                            label: const Text('Get Directions'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Order items card
                  _SectionCard(
                    title: 'Order Items (${order.items.length})',
                    icon: Icons.shopping_bag,
                    child: Column(
                      children: [
                        ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: item.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                        child: Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppColors.grey400),
                                        ),
                                      )
                                    : const Icon(Icons.inventory_2, color: AppColors.grey400),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${item.unit} x ${item.quantity}',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\u20B9${item.total.toStringAsFixed(0)}',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Payment details card
                  _SectionCard(
                    title: 'Payment Details',
                    icon: Icons.payment,
                    child: Column(
                      children: [
                        _PaymentRow(label: 'Subtotal', value: '\u20B9${order.subtotal.toStringAsFixed(0)}'),
                        _PaymentRow(label: 'Delivery Fee', value: '\u20B9${order.deliveryFee.toStringAsFixed(0)}'),
                        if (order.discount > 0)
                          _PaymentRow(
                            label: 'Discount',
                            value: '-\u20B9${order.discount.toStringAsFixed(0)}',
                            valueColor: AppColors.success,
                          ),
                        const Divider(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '\u20B9${order.total.toStringAsFixed(0)}',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: order.paymentMethod == 'COD'
                                ? AppColors.warning.withValues(alpha: 0.1)
                                : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                order.paymentMethod == 'COD' ? Icons.money : Icons.check_circle,
                                size: 18,
                                color: order.paymentMethod == 'COD' ? AppColors.warning : AppColors.success,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                order.paymentMethod == 'COD'
                                    ? 'Collect \u20B9${order.total.toStringAsFixed(0)} on delivery'
                                    : 'Payment already received',
                                style: AppTypography.labelMedium.copyWith(
                                  color: order.paymentMethod == 'COD' ? AppColors.warning : AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Order info
                  _SectionCard(
                    title: 'Order Info',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        _InfoRow(label: 'Order Number', value: order.orderNumber),
                        _InfoRow(
                          label: 'Placed At',
                          value: DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                        ),
                        _InfoRow(label: 'Payment Method', value: order.paymentMethod),
                        _InfoRow(label: 'Payment Status', value: order.paymentStatus),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActionBar(order: order, ref: ref),
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

class _StatusBanner extends StatelessWidget {
  final Order order;

  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String statusText;

    switch (order.status) {
      case 'PREPARING':
      case 'CONFIRMED':
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        icon = Icons.access_time;
        statusText = 'Ready for Pickup';
        break;
      case 'OUT_FOR_DELIVERY':
        backgroundColor = AppColors.info.withValues(alpha: 0.1);
        textColor = AppColors.info;
        icon = Icons.local_shipping;
        statusText = 'Out for Delivery';
        break;
      case 'DELIVERED':
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        icon = Icons.check_circle;
        statusText = 'Delivered';
        break;
      default:
        backgroundColor = AppColors.grey100;
        textColor = AppColors.textSecondary;
        icon = Icons.info;
        statusText = order.status;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Text(
            statusText,
            style: AppTypography.titleMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PaymentRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BottomActionBar extends ConsumerWidget {
  final Order order;
  final WidgetRef ref;

  const _BottomActionBar({required this.order, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryState = ref.watch(deliveryProvider);
    final isUpdating = deliveryState.isUpdatingStatus;

    // No action needed for delivered orders
    if (order.status == 'DELIVERED') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isUpdating
                ? null
                : () async {
                    final newStatus = order.status == 'OUT_FOR_DELIVERY' ? 'DELIVERED' : 'OUT_FOR_DELIVERY';
                    final success = await ref.read(deliveryProvider.notifier).updateDeliveryStatus(order.id, newStatus);

                    if (context.mounted) {
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

                      if (success && newStatus == 'DELIVERED') {
                        Navigator.pop(context);
                      }
                    }
                  },
            icon: isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    order.status == 'OUT_FOR_DELIVERY' ? Icons.check_circle : Icons.local_shipping,
                  ),
            label: Text(
              order.status == 'OUT_FOR_DELIVERY' ? 'Mark as Delivered' : 'Start Delivery',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: order.status == 'OUT_FOR_DELIVERY' ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
