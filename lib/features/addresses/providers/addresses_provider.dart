import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/address_service.dart';
import '../../../core/utils/error_handler.dart';

// Addresses state
class AddressesState {
  final List<Address> addresses;
  final bool isLoading;
  final String? error;

  AddressesState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
  });

  AddressesState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    String? error,
  }) {
    return AddressesState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory AddressesState.initial() => AddressesState();

  Address? get defaultAddress =>
      addresses.isEmpty ? null : addresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => addresses.first,
      );
}

// Addresses notifier
class AddressesNotifier extends StateNotifier<AddressesState> {
  final AddressService _addressService;

  AddressesNotifier(this._addressService) : super(AddressesState.initial());

  String _getErrorMessage(dynamic error) {
    return ErrorHandler.getErrorMessage(error);
  }

  // Load addresses
  Future<void> loadAddresses() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final addresses = await _addressService.getAddresses();
      state = state.copyWith(
        addresses: addresses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  // Add address
  Future<bool> addAddress(Address address) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _addressService.addAddress(address);

      // Refresh addresses list
      await loadAddresses();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  // Update address
  Future<bool> updateAddress(int index, Address address) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _addressService.updateAddress(index, address);

      // Refresh addresses list
      await loadAddresses();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  // Delete address
  Future<bool> deleteAddress(int index) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _addressService.deleteAddress(index);

      // Remove from local state
      final updatedAddresses = List<Address>.from(state.addresses);
      if (index >= 0 && index < updatedAddresses.length) {
        updatedAddresses.removeAt(index);
      }

      state = state.copyWith(
        addresses: updatedAddresses,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  // Set default address
  Future<bool> setDefaultAddress(int index) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _addressService.setDefaultAddress(index);

      // Refresh addresses list
      await loadAddresses();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final addressesProvider = StateNotifierProvider<AddressesNotifier, AddressesState>((ref) {
  final addressService = ref.watch(addressServiceProvider);
  return AddressesNotifier(addressService);
});
