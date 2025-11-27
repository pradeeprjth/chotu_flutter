import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';

class AddressService {
  final ApiClient _apiClient;

  AddressService(this._apiClient);

  // Get all addresses
  Future<List<Address>> getAddresses() async {
    try {
      final response = await _apiClient.get('/users/addresses');

      final data = response.data;
      List<dynamic> addressList;

      if (data is Map && data['data'] != null) {
        addressList = data['data'] as List;
      } else if (data is List) {
        addressList = data;
      } else {
        addressList = [];
      }

      return addressList
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Add new address
  Future<Address> addAddress(Address address) async {
    try {
      final response = await _apiClient.post('/users/addresses', data: address.toJson());

      final data = response.data;
      if (data is Map && data['data'] != null) {
        return Address.fromJson(data['data'] as Map<String, dynamic>);
      }

      return address;
    } catch (e) {
      rethrow;
    }
  }

  // Update address at index
  Future<Address> updateAddress(int index, Address address) async {
    try {
      final response = await _apiClient.put('/users/addresses/$index', data: address.toJson());

      final data = response.data;
      if (data is Map && data['data'] != null) {
        return Address.fromJson(data['data'] as Map<String, dynamic>);
      }

      return address;
    } catch (e) {
      rethrow;
    }
  }

  // Delete address at index
  Future<void> deleteAddress(int index) async {
    try {
      await _apiClient.delete('/users/addresses/$index');
    } catch (e) {
      rethrow;
    }
  }

  // Set default address
  Future<void> setDefaultAddress(int index) async {
    try {
      // Get current addresses
      final addresses = await getAddresses();

      if (index < 0 || index >= addresses.length) {
        throw Exception('Invalid address index');
      }

      // Update the address with isDefault = true
      final address = addresses[index];
      final updatedAddress = Address(
        label: address.label,
        addressLine1: address.addressLine1,
        addressLine2: address.addressLine2,
        city: address.city,
        state: address.state,
        pincode: address.pincode,
        landmark: address.landmark,
        isDefault: true,
      );

      await updateAddress(index, updatedAddress);
    } catch (e) {
      rethrow;
    }
  }
}

// Provider for AddressService
final addressServiceProvider = Provider<AddressService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AddressService(apiClient);
});
