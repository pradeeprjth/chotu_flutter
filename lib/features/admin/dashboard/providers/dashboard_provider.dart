import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/admin_service.dart';

/// Dashboard state
class DashboardState {
  final bool isLoading;
  final String? error;
  final DashboardMetrics? metrics;
  final DashboardCharts? charts;
  final List<RecentOrderData> recentOrders;
  final DateRange selectedRange;

  DashboardState({
    this.isLoading = false,
    this.error,
    this.metrics,
    this.charts,
    this.recentOrders = const [],
    this.selectedRange = DateRange.week,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardMetrics? metrics,
    DashboardCharts? charts,
    List<RecentOrderData>? recentOrders,
    DateRange? selectedRange,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      metrics: metrics ?? this.metrics,
      charts: charts ?? this.charts,
      recentOrders: recentOrders ?? this.recentOrders,
      selectedRange: selectedRange ?? this.selectedRange,
    );
  }
}

/// Date range for filtering
enum DateRange {
  today,
  week,
  month,
}

/// Dashboard provider
class DashboardNotifier extends StateNotifier<DashboardState> {
  final AdminService _adminService;

  DashboardNotifier(this._adminService) : super(DashboardState()) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _adminService.getDashboardMetrics(),
        _adminService.getDashboardCharts(
          range: state.selectedRange == DateRange.month ? 'month' : 'week',
        ),
        _adminService.getRecentOrders(limit: 10),
      ]);

      state = state.copyWith(
        isLoading: false,
        metrics: results[0] as DashboardMetrics,
        charts: results[1] as DashboardCharts,
        recentOrders: results[2] as List<RecentOrderData>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  void setDateRange(DateRange range) {
    state = state.copyWith(selectedRange: range);
    loadDashboardData();
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Failed to load dashboard data';
  }
}

/// Dashboard provider instance
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) {
    final adminService = ref.watch(adminServiceProvider);
    return DashboardNotifier(adminService);
  },
);
