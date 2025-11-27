import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/addresses_provider.dart';
import '../../../core/models/user_model.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    // Load addresses when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addressesProvider.notifier).loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressesState = ref.watch(addressesProvider);
    final addresses = addressesState.addresses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
      ),
      body: addressesState.isLoading && addresses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : addressesState.error != null && addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(addressesState.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(addressesProvider.notifier).loadAddresses(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : addresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_off_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No addresses saved',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add an address for delivery',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/addresses/new'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Address'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(addressesProvider.notifier).loadAddresses(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          return _AddressCard(
                            address: address,
                            index: index,
                            isLoading: addressesState.isLoading,
                            onEdit: () => context.push('/addresses/$index/edit'),
                            onDelete: () => _confirmDelete(context, index),
                            onSetDefault: () => _setDefaultAddress(index),
                          );
                        },
                      ),
                    ),
      floatingActionButton: addresses.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.push('/addresses/new'),
              backgroundColor: const Color(0xFF4CAF50),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(addressesProvider.notifier).deleteAddress(index);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Address deleted' : 'Failed to delete address'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _setDefaultAddress(int index) async {
    final success = await ref.read(addressesProvider.notifier).setDefaultAddress(index);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Address set as default' : 'Failed to set default address'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final int index;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.index,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: address.isDefault ? const Color(0xFF4CAF50) : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  address.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                        case 'default':
                          onSetDefault();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (!address.isDefault)
                        const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.fullAddress,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
