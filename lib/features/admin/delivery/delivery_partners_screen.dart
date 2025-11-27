import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/admin_service.dart';
import 'providers/admin_delivery_partners_provider.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';

class DeliveryPartnersScreen extends ConsumerStatefulWidget {
  const DeliveryPartnersScreen({super.key});

  @override
  ConsumerState<DeliveryPartnersScreen> createState() => _DeliveryPartnersScreenState();
}

class _DeliveryPartnersScreenState extends ConsumerState<DeliveryPartnersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      final state = ref.read(adminDeliveryPartnersProvider);
      if (!state.isLoading &&
          state.pagination != null &&
          state.pagination!.page < state.pagination!.totalPages) {
        ref.read(adminDeliveryPartnersProvider.notifier).loadNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnersState = ref.watch(adminDeliveryPartnersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partners'),
        actions: [
          // Availability filter
          PopupMenuButton<bool?>(
            icon: Icon(
              Icons.filter_list,
              color: partnersState.availabilityFilter != null ? AppColors.primary : null,
            ),
            tooltip: 'Filter by availability',
            onSelected: (value) {
              ref.read(adminDeliveryPartnersProvider.notifier).filterByAvailability(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Partners'),
              ),
              const PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    SizedBox(width: 8),
                    Text('Available Only'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: AppColors.grey500, size: 18),
                    SizedBox(width: 8),
                    Text('Unavailable Only'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(adminDeliveryPartnersProvider.notifier).loadPartners(refresh: true);
            },
          ),
        ],
      ),
      body: partnersState.isLoading && partnersState.partners.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : partnersState.error != null && partnersState.partners.isEmpty
              ? _buildError(partnersState.error!)
              : Column(
                  children: [
                    // Filter info bar
                    if (partnersState.availabilityFilter != null)
                      _buildFilterBar(partnersState),
                    // Partners list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref.read(adminDeliveryPartnersProvider.notifier).loadPartners(refresh: true),
                        child: partnersState.partners.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: partnersState.partners.length + (partnersState.isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= partnersState.partners.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(AppSpacing.md),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final partner = partnersState.partners[index];
                                  return _DeliveryPartnerCard(
                                    partner: partner,
                                    onToggleAvailability: () => _toggleAvailability(partner),
                                    onEdit: () => _showEditDialog(context, partner),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePartnerDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text('Failed to load delivery partners', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(error, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => ref.read(adminDeliveryPartnersProvider.notifier).loadPartners(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining, size: 64, color: AppColors.grey300),
          const SizedBox(height: AppSpacing.md),
          Text('No delivery partners found', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add delivery partners to manage deliveries',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AdminDeliveryPartnersState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.availabilityFilter! ? 'Available' : 'Unavailable',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => ref.read(adminDeliveryPartnersProvider.notifier).filterByAvailability(null),
                  child: Icon(Icons.close, size: 14, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '${state.partners.length} partners',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _toggleAvailability(AdminDeliveryPartner partner) async {
    final success = await ref.read(adminDeliveryPartnersProvider.notifier).toggleAvailability(
      partner.id,
      !partner.isAvailable,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Partner ${partner.isAvailable ? 'set to unavailable' : 'set to available'}'
                : 'Failed to update availability',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showCreatePartnerDialog(BuildContext context) {
    final userIdController = TextEditingController();
    final vehicleTypeController = TextEditingController(text: 'bike');
    final vehicleNumberController = TextEditingController();
    final licenseNumberController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Delivery Partner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Enter user ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: vehicleTypeController.text,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'bike', child: Text('Bike')),
                  DropdownMenuItem(value: 'scooter', child: Text('Scooter')),
                  DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
                  DropdownMenuItem(value: 'car', child: Text('Car')),
                ],
                onChanged: (value) {
                  vehicleTypeController.text = value ?? 'bike';
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  hintText: 'e.g., MH02AB1234',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  hintText: 'Enter license number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (userIdController.text.isEmpty ||
                  vehicleNumberController.text.isEmpty ||
                  licenseNumberController.text.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              final partner = await ref.read(adminDeliveryPartnersProvider.notifier).createPartner(
                userId: userIdController.text,
                vehicleType: vehicleTypeController.text,
                vehicleNumber: vehicleNumberController.text,
                licenseNumber: licenseNumberController.text,
              );

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(partner != null ? 'Partner added successfully' : 'Failed to add partner'),
                  backgroundColor: partner != null ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, AdminDeliveryPartner partner) {
    final vehicleTypeController = TextEditingController(text: partner.vehicleType);
    final vehicleNumberController = TextEditingController(text: partner.vehicleNumber);
    final licenseNumberController = TextEditingController(text: partner.licenseNumber);
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    final partnerName = partner.user['name']?.toString() ?? 'Partner';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit $partnerName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: vehicleTypeController.text,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'bike', child: Text('Bike')),
                  DropdownMenuItem(value: 'scooter', child: Text('Scooter')),
                  DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
                  DropdownMenuItem(value: 'car', child: Text('Car')),
                ],
                onChanged: (value) {
                  vehicleTypeController.text = value ?? 'bike';
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final success = await ref.read(adminDeliveryPartnersProvider.notifier).updatePartner(
                partner.id,
                {
                  'vehicleType': vehicleTypeController.text,
                  'vehicleNumber': vehicleNumberController.text,
                  'licenseNumber': licenseNumberController.text,
                },
              );

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Partner updated successfully' : 'Failed to update partner'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPartnerCard extends StatelessWidget {
  final AdminDeliveryPartner partner;
  final VoidCallback onToggleAvailability;
  final VoidCallback onEdit;

  const _DeliveryPartnerCard({
    required this.partner,
    required this.onToggleAvailability,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = partner.user['name']?.toString() ?? 'Unknown';
    final phone = partner.user['phone']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: partner.isAvailable
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.grey200,
              child: Icon(
                Icons.person,
                color: partner.isAvailable ? AppColors.success : AppColors.grey500,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Partner info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _VehicleBadge(
                        type: partner.vehicleType,
                        number: partner.vehicleNumber,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusBadge(
                        isAvailable: partner.isAvailable,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                Switch(
                  value: partner.isAvailable,
                  onChanged: (_) => onToggleAvailability(),
                  activeTrackColor: AppColors.successLight,
                  activeThumbColor: AppColors.success,
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleBadge extends StatelessWidget {
  final String type;
  final String number;

  const _VehicleBadge({
    required this.type,
    required this.number,
  });

  IconData _getVehicleIcon() {
    switch (type.toLowerCase()) {
      case 'bike':
        return Icons.motorcycle;
      case 'scooter':
        return Icons.electric_scooter;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'car':
        return Icons.directions_car;
      default:
        return Icons.delivery_dining;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getVehicleIcon(), size: 12, color: AppColors.info),
          const SizedBox(width: 4),
          Text(
            number,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isAvailable;

  const _StatusBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: (isAvailable ? AppColors.success : AppColors.grey500).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: TextStyle(
          fontSize: 10,
          color: isAvailable ? AppColors.success : AppColors.grey500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
