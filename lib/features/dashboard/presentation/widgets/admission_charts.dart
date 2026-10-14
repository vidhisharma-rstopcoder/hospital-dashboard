import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:hospital_dashboard/common/widgets/status_chip.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/dashboard/domain/dashboard_stats.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';

class AdmissionCharts extends StatelessWidget {
  const AdmissionCharts({required this.stats, super.key});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;
        final statusCard = _StatusMix(stats: stats);
        final weekCard = _WeekChart(stats: stats);
        if (stacked) {
          return Column(
            children: [statusCard, const SizedBox(height: 16), weekCard],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: weekCard),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: statusCard),
          ],
        );
      },
    );
  }
}

class _StatusMix extends StatelessWidget {
  const _StatusMix({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final sections = PatientStatus.values
        .where((status) => (stats.byStatus[status] ?? 0) > 0)
        .map(
          (status) => PieChartSectionData(
            value: (stats.byStatus[status] ?? 0).toDouble(),
            color: statusColor(status),
            radius: 22,
            showTitle: false,
          ),
        )
        .toList();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'All patients on file',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  child: sections.isEmpty
                      ? const Center(child: Text('No patients'))
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sections: sections,
                                centerSpaceRadius: 58,
                                sectionsSpace: 3,
                                startDegreeOffset: -90,
                              ),
                              duration: const Duration(milliseconds: 700),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${stats.total}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const Text(
                                  'patients',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final status in PatientStatus.values)
                        _StatusRow(
                          status: status,
                          count: stats.byStatus[status] ?? 0,
                          onTap: () =>
                              context.go('/patients?status=${status.label}'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final peak = stats.weekCounts.fold<int>(0, math.max);
    final maxY = (peak == 0 ? 4 : peak + 1).toDouble();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Busiest day  ·  ${stats.busiestDay}',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: AppColors.line, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppColors.ink,
                    getTooltipItems: (spots) {
                      return [
                        for (final spot in spots)
                          LineTooltipItem(
                            '${spot.y.toInt()} ${spot.y.toInt() == 1 ? 'admission' : 'admissions'}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontFamily: appFontFamily,
                            ),
                          ),
                      ];
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: peak > 6 ? 2 : 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= stats.weekLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            stats.weekLabels[index],
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < stats.weekCounts.length; i++)
                        FlSpot(i.toDouble(), stats.weekCounts[i].toDouble()),
                    ],
                    isCurved: true,
                    color: AppColors.teal,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.teal.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatefulWidget {
  const _StatusRow({
    required this.status,
    required this.count,
    required this.onTap,
  });

  final PatientStatus status;
  final int count;
  final VoidCallback onTap;

  @override
  State<_StatusRow> createState() => _StatusRowState();
}

class _StatusRowState extends State<_StatusRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: _hover ? AppColors.mint : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor(widget.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.status.displayLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${widget.count}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: appFontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
