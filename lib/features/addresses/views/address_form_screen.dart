import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/addresses_provider.dart';
import '../../../core/models/user_model.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final int? addressIndex;

  const AddressFormScreen({super.key, this.addressIndex});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isDefault = false;

  bool get isEditing => widget.addressIndex != null;

  @override
  void initState() {
    super.initState();
    // Load existing address if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditing) {
        _loadExistingAddress();
      }
    });
  }

  void _loadExistingAddress() {
    final addresses = ref.read(addressesProvider).addresses;
    if (widget.addressIndex != null && widget.addressIndex! < addresses.length) {
      final address = addresses[widget.addressIndex!];
      _labelController.text = address.label;
      _addressLine1Controller.text = address.addressLine1;
      _addressLine2Controller.text = address.addressLine2 ?? '';
      _landmarkController.text = address.landmark ?? '';
      _cityController.text = address.city;
      _stateController.text = address.state;
      _pincodeController.text = address.pincode;
      setState(() {
        _isDefault = address.isDefault;
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final address = Address(
      label: _labelController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty ? null : _addressLine2Controller.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      isDefault: _isDefault,
    );

    bool success;
    if (isEditing) {
      success = await ref.read(addressesProvider.notifier).updateAddress(widget.addressIndex!, address);
    } else {
      success = await ref.read(addressesProvider.notifier).addAddress(address);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Address updated' : 'Address added'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        final error = ref.read(addressesProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesState = ref.watch(addressesProvider);
    final isSaving = addressesState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Address Label *',
                  hintText: 'e.g., Home, Office, etc.',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a label';
                  }
                  if (value.trim().length < 2) {
                    return 'Label must be at least 2 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value.trim())) {
                    return 'Label can only contain letters and numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Line 1
              TextFormField(
                controller: _addressLine1Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1 *',
                  hintText: 'Flat/House No., Building, Street',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address';
                  }
                  if (value.trim().length < 5) {
                    return 'Address must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Line 2
              TextFormField(
                controller: _addressLine2Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 2',
                  hintText: 'Area, Colony (Optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Landmark
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  labelText: 'Landmark',
                  hintText: 'Near Park, Opposite Mall (Optional)',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // City and State
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.trim().length < 2) {
                          return 'Too short';
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                          return 'Invalid city';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.trim().length < 2) {
                          return 'Too short';
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                          return 'Invalid state';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pincode
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode *',
                  prefixIcon: Icon(Icons.pin_drop_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pincode';
                  }
                  if (value.length != 6) {
                    return 'Pincode must be 6 digits';
                  }
                  // Valid Indian pincodes start with 1-9
                  if (value.startsWith('0')) {
                    return 'Invalid pincode';
                  }
                  // Check if it's a valid number
                  final pincode = int.tryParse(value);
                  if (pincode == null || pincode < 100000 || pincode > 999999) {
                    return 'Invalid pincode';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Set as default
              CheckboxListTile(
                value: _isDefault,
                onChanged: (value) {
                  setState(() => _isDefault = value ?? false);
                },
                title: const Text('Set as default address'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveAddress,
                  child: isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(isEditing ? 'Update Address' : 'Save Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
