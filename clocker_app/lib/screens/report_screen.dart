import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_colors.dart';
import '../providers/spacetime_provider.dart';
import '../core/utils/duration_formatter.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacetimeProvider = context.watch<SpacetimeProvider>();

    if (spacetimeProvider.activeSpacetime == null) {
      return const Center(child: Text('请先创建自律时空'));
    }

    final st = spacetimeProvider.activeSpacetime!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('时空报告'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(context, st),
            const SizedBox(height: 20),
            _buildFlowRateChart(context, st, spacetimeProvider),
            const SizedBox(height: 20),
            _buildDisciplineBreakdown(context, st, spacetimeProvider),
            const SizedBox(height: 20),
            _buildInsights(context, st),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, dynamic st) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            '总专注时长',
            '${st.totalFocusHours.toStringAsFixed(1)}h',
            Icons.timer,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            context,
            '完成任务值',
            '${st.totalTaskValue.toStringAsFixed(1)}h',
            Icons.check_circle,
            AppColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            context,
            '当前流速',
            DurationFormatter.formatFlowRate(st.currentFlowRate),
            Icons.speed,
            st.currentFlowRate <= 1.0 ? AppColors.flowSlow : AppColors.flowFast,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowRateChart(BuildContext context, dynamic st, SpacetimeProvider provider) {
    final engine = provider.getEngine()!;

    final dataPoints = <FlSpot>[];
    for (int i = 0; i <= 10; i++) {
      final v = st.c * i / 10;
      final flowRate = engine.calculateFlowRate(v);
      dataPoints.add(FlSpot(i.toDouble(), flowRate));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                '流速曲线 (v → V)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toStringAsFixed(1)}x',
                        style: TextStyle(color: AppColors.textHint, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${(value * 10).toInt()}%',
                        style: TextStyle(color: AppColors.textHint, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dataPoints,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '自律度: ${(s.x * 10).toInt()}%\n流速: ${s.y.toStringAsFixed(2)}x',
                              const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '自律速度 v 占极限 c 的百分比',
              style: TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineBreakdown(BuildContext context, dynamic st, SpacetimeProvider provider) {
    final discipline = st.disciplinePercentage;
    final focusRatio = st.totalFocusHours > 0
        ? (st.totalFocusHours / (st.totalFocusHours + st.totalScreenPenalty)).clamp(0, 1)
        : 0.0;
    final engine = provider.getEngine()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.accent, size: 18),
              const SizedBox(width: 6),
              Text(
                '自律分析',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar('自律度', discipline, AppColors.success),
          const SizedBox(height: 10),
          _buildProgressBar('专注占比', focusRatio, AppColors.primary),
          const SizedBox(height: 10),
          _buildProgressBar('任务完成率', st.totalTaskValue > 0 ? (st.totalTaskValue / (st.totalFocusHours + st.totalTaskValue)).clamp(0, 1) : 0, AppColors.accent),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem('v值', '${st.currentV.toStringAsFixed(1)}h', AppColors.accent),
              _buildMetricItem('洛伦兹因子', engine.lorentzFactor(st.currentV).toStringAsFixed(3), AppColors.primary),
              _buildMetricItem('时间盈亏', DurationFormatter.formatDays(st.timeEarned), st.timeEarned >= 0 ? AppColors.success : AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(
              DurationFormatter.formatPercentage(value),
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 10)),
      ],
    );
  }

  Widget _buildInsights(BuildContext context, dynamic st) {
    final insights = <Map<String, dynamic>>[];

    if (st.disciplinePercentage >= 0.6) {
      insights.add({
        'icon': Icons.bolt,
        'color': AppColors.flowSlow,
        'title': '心流状态',
        'desc': '你的自律度超过60%，已进入心流钟慢模式，额外降低10%-20%流速！',
      });
    }

    if (st.currentFlowRate > 1.5) {
      insights.add({
        'icon': Icons.warning,
        'color': AppColors.danger,
        'title': '流速过快警告',
        'desc': '当前流速${DurationFormatter.formatFlowRate(st.currentFlowRate)}，截止日正在加速到来，请立即行动！',
      });
    }

    if (st.totalFocusHours < 1 && st.totalTaskValue < 1) {
      insights.add({
        'icon': Icons.lightbulb,
        'color': AppColors.warning,
        'title': '开始你的第一步',
        'desc': '完成一个小任务或开启15分钟专注，就能立即降低流速。记住蔡格尼克效应：开始就是成功的一半！',
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.trending_down,
        'color': AppColors.success,
        'title': '时间在为你变慢',
        'desc': '继续保持当前自律节奏，你的时间流速正在持续降低！',
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                '个性化建议',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(i['icon'] as IconData, color: i['color'] as Color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i['title'] as String,
                            style: TextStyle(
                              color: i['color'] as Color,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            i['desc'] as String,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
