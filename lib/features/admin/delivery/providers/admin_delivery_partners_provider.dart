import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/admin_service.dart';

/// Admin delivery partners state
class AdminDeliveryPartnersState {
  final bool isLoading;
  final String? error;
  final List<AdminDeliveryPartner> partners;
  final Pagination? pagination;
  final bool? availabilityFilter;

  AdminDeliveryPartnersState({
    this.isLoading = false,
    this.error,
    this.partners = const [],
    this.pagination,
    this.availabilityFilter,
  });

  AdminDeliveryPartnersState copyWith({
    bool? isLoading,
    String? error,
    List<AdminDeliveryPartner>? partners,
    Pagination? pagination,
    bool? availabilityFilter,
    bool clearError = false,
    bool clearAvailabilityFilter = false,
  }) {
    return AdminDeliveryPartnersState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      partners: partners ?? this.partners,
      pagination: pagination ?? this.pagination,
      availabilityFilter: clearAvailabilityFilter ? null : availabilityFilter ?? this.availabilityFilter,
    );
  }
}

/// Admin delivery partners notifier
class AdminDeliveryPartnersNotifier extends StateNotifier<AdminDeliveryPartnersState> {
  final AdminService _adminService;

  AdminDeliveryPartnersNotifier(this._adminService) : super(AdminDeliveryPartnersState()) {
    loadPartners();
  }

  Future<void> loadPartners({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _adminService.getDeliveryPartners(
        isAvailable: state.availabilityFilter,
        page: 1,
        limit: 20,
      );

      state = state.copyWith(
        isLoading: false,
        partners: result.partners,
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading) return;
    if (state.pagination == null) return;
    if (state.pagination!.page >= state.pagination!.totalPages) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _adminService.getDeliveryPartners(
        isAvailable: state.availabilityFilter,
        page: state.pagination!.page + 1,
        limit: 20,
      );

      state = state.copyWith(
        isLoading: false,
        partners: [...state.partners, ...result.partners],
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  void filterByAvailability(bool? isAvailable) {
    if (isAvailable == state.availabilityFilter) return;

    state = state.copyWith(
      availabilityFilter: isAvailable,
      clearAvailabilityFilter: isAvailable == null,
      partners: [],
      pagination: null,
    );
    loadPartners();
  }

  Future<AdminDeliveryPartner?> createPartner({
    required String userId,
    required String vehicleType,
    required String vehicleNumber,
    required String licenseNumber,
  }) async {
    try {
      final partner = await _adminService.createDeliveryPartner(
        userId: userId,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        licenseNumber: licenseNumber,
      );

      // Refresh the list
      loadPartners(refresh: true);
      return partner;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return null;
    }
  }

  Future<bool> updatePartner(String partnerId, Map<String, dynamic> updates) async {
    try {
      final updatedPartner = await _adminService.updateDeliveryPartner(partnerId, updates);

      // Update locally
      final updatedPartners = state.partners.map((p) {
        if (p.id == partnerId) {
          return updatedPartner;
        }
        return p;
      }).toList();

      state = state.copyWith(partners: updatedPartners);
      return true;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> toggleAvailability(String partnerId, bool isAvailable) async {
    return updatePartner(partnerId, {'isAvailable': isAvailable});
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred';
  }
}

/// Admin delivery partners provider instance
final adminDeliveryPartnersProvider = StateNotifierProvider<AdminDeliveryPartnersNotifier, AdminDeliveryPartnersState>(
  (ref) {
    final adminService = ref.watch(adminServiceProvider);
    return AdminDeliveryPartnersNotifier(adminService);
  },
);

/// Available delivery partners for assignment
final availableDeliveryPartnersProvider = FutureProvider<List<AdminDeliveryPartner>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  final result = await adminService.getDeliveryPartners(isAvailable: true, limit: 100);
  return result.partners;
});
