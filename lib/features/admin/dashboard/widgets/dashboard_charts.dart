import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../app/colors.dart';
import '../../../../app/typography.dart';
import '../../../../app/design_tokens.dart';
import '../../../../core/services/admin_service.dart';

/// Revenue line chart
class RevenueChart extends StatelessWidget {
  final List<RevenueDataPoint> data;

  const RevenueChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxY = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final minY = data.map((e) => e.amount).reduce((a, b) => a < b ? a : b);

    // Handle case when all values are the same (avoid division by zero)
    final range = maxY - minY;
    final effectiveRange = range > 0 ? range : (maxY > 0 ? maxY : 1000);
    final padding = effectiveRange * 0.1;
    final horizontalInterval = effectiveRange / 4;

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
          Text('Revenue Trend', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.grey200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: AppTypography.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final dateStr = data[index].date;
                          final date = DateTime.tryParse(dateStr);
                          return Text(
                            date != null ? DateFormat('E').format(date) : '',
                            style: AppTypography.labelSmall,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: range > 0 ? minY - padding : minY - effectiveRange * 0.5,
                maxY: range > 0 ? maxY + padding : maxY + effectiveRange * 0.5,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.amount);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '\u20B9${spot.y.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Orders by category pie chart
class OrdersByCategoryChart extends StatelessWidget {
  final List<CategoryOrderData> data;

  const OrdersByCategoryChart({super.key, required this.data});

  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.info,
    AppColors.warning,
    AppColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

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
          Text('Orders by Category', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return PieChartSectionData(
                    value: item.percentage,
                    title: '${item.percentage.toStringAsFixed(0)}%',
                    color: _colors[index % _colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Legend
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: data.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colors[index % _colors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.categoryName,
                    style: AppTypography.labelSmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Popular products bar chart
class PopularProductsChart extends StatelessWidget {
  final List<PopularProductData> data;

  const PopularProductsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxY = data.map((e) => e.orderCount).reduce((a, b) => a > b ? a : b);

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
          Text('Popular Products', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${data[groupIndex].productName}\n${rod.toY.toInt()} orders',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          // Truncate long names
                          final name = data[index].productName;
                          final displayName = name.length > 8
                              ? '${name.substring(0, 8)}...'
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              displayName,
                              style: AppTypography.labelSmall.copyWith(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTypography.labelSmall,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.grey200,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.orderCount.toDouble(),
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Orders by status donut chart
class OrdersByStatusChart extends StatelessWidget {
  final List<OrderStatusData> data;

  const OrdersByStatusChart({super.key, required this.data});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return AppColors.success;
      case 'OUT_FOR_DELIVERY':
        return AppColors.info;
      case 'PACKING':
        return AppColors.warning;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final totalOrders = data.fold<int>(0, (sum, item) => sum + item.count);

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
          Text('Orders by Status', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: data.map((item) {
                      return PieChartSectionData(
                        value: item.count.toDouble(),
                        title: '',
                        color: _getStatusColor(item.status),
                        radius: 30,
                      );
                    }).toList(),
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalOrders',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Status list
          ...data.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.status.replaceAll('_', ' '),
                      style: AppTypography.labelSmall,
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
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
}
