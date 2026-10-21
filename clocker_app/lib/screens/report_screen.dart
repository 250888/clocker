import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_colors.dart';
import '../models/spacetime.dart';
import '../core/engine/lorentz_engine.dart';
import '../providers/spacetime_provider.dart';
import '../core/utils/duration_formatter.dart';
import '../widgets/dawn_backdrop.dart';
import '../widgets/instrument_empty_state.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacetimeProvider = context.watch<SpacetimeProvider>();

    if (spacetimeProvider.activeSpacetime == null) {
      return const DawnEmptyPage(
      appBarTitle: '时空报告',
      title: '尚未创建自律时空',
      hint: '有专注记录后，这里会出现一周的时空报告',
    );
    }

    final st = spacetimeProvider.activeSpacetime!;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('时空报告'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DawnBackdrop(showTrails: false)),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              16,
              32,
            ),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(context, st),
            const SizedBox(height: 20),
            _buildFlowRateChart(context, st, spacetimeProvider),
            const SizedBox(height: 20),
            _buildDisciplineBreakdown(context, st, spacetimeProvider),
            const SizedBox(height: 20),
            _buildTimeBalance(context, st, spacetimeProvider),
            const SizedBox(height: 20),
                _buildInsights(context, st),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, Spacetime st) {
    final netHours = (st.timeEarnedDays - st.timeLostDays) * 24;
    final positive = netHours >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '本 周 净 赚',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${positive ? '+' : '−'}${netHours.abs().toStringAsFixed(1)}',
              style: TextStyle(
                color: positive ? AppColors.textPrimary : AppColors.danger,
                fontSize: 52,
                fontWeight: FontWeight.w300,
                height: 1,
                letterSpacing: -2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 6),
              child: Text(
                'h',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMetric(
                  '总专注',
                  '${st.totalFocusHours.toStringAsFixed(1)}h',
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.hairline),
              Expanded(
                child: _buildMetric(
                  '任务值',
                  '${st.totalTaskValue.toStringAsFixed(1)}h',
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.hairline),
              Expanded(
                child: _buildMetric(
                  '当前流速',
                  DurationFormatter.formatFlowRate(st.effectiveFlowRate),
                  color: st.effectiveFlowRate <= 1.0
                      ? AppColors.flowSlow
                      : AppColors.flowFast,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.textHint, fontSize: 10),
        ),
      ],
    );
  }

  /// γ = 1/√(1−(v/c)²)：引擎的 lorentzFactor 返回的是 1/γ（时间收缩因子），这里取倒数。
  double _gammaOf(LorentzEngine engine, Spacetime st) {
    final factor = engine.lorentzFactor(st.currentV);
    if (factor <= 0.0001) return 999;
    return 1 / factor;
  }

  Widget _buildFlowRateChart(
    BuildContext context,
    Spacetime st,
    SpacetimeProvider provider,
  ) {
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
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(10),
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
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.hairline,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toStringAsFixed(1)}x',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        '${(value * 10).toInt()}%',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                        .map(
                          (s) => LineTooltipItem(
                            '自律度: ${(s.x * 10).toInt()}%\n流速: ${s.y.toStringAsFixed(2)}x',
                            const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        )
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

  Widget _buildDisciplineBreakdown(
    BuildContext context,
    Spacetime st,
    SpacetimeProvider provider,
  ) {
    final discipline = st.disciplinePercentage;
    final focusRatio = st.totalFocusHours > 0
        ? (st.totalFocusHours / (st.totalFocusHours + st.totalScreenPenalty))
              .clamp(0.0, 1.0)
        : 0.0;
    final engine = provider.getEngine()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.accent, size: 18),
              const SizedBox(width: 6),
              Text('自律分析', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar('自律度', discipline, AppColors.success),
          const SizedBox(height: 10),
          _buildProgressBar('专注占比', focusRatio, AppColors.primary),
          const SizedBox(height: 10),
          _buildProgressBar(
            '任务完成率',
            st.totalTaskValue > 0
                ? (st.totalTaskValue / (st.totalFocusHours + st.totalTaskValue))
                      .clamp(0.0, 1.0)
                : 0.0,
            AppColors.accent,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                'v值',
                '${st.currentV.toStringAsFixed(1)}h',
                AppColors.accent,
              ),
              _buildMetricItem(
                '洛伦兹因子 γ',
                _gammaOf(engine, st).toStringAsFixed(2),
                AppColors.primary,
              ),
              _buildMetricItem(
                '时间盈亏',
                DurationFormatter.formatHours(st.timeEarnedDays * 24),
                st.timeEarnedDays >= 0 ? AppColors.success : AppColors.danger,
              ),
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
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            Text(
              DurationFormatter.formatPercentage(value),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 10)),
      ],
    );
  }

  Widget _buildTimeBalance(
    BuildContext context,
    Spacetime st,
    SpacetimeProvider provider,
  ) {
    final earnedH = st.timeEarnedDays * 24;
    final lostH = st.timeLostDays * 24;
    final net = earnedH - lostH;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text('时间盈亏报告', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeBalanceItem(
                context,
                '已赚取',
                DurationFormatter.formatHours(earnedH),
                Icons.add_circle_outline,
                AppColors.success,
              ),
              Container(width: 1, height: 40, color: AppColors.surfaceLight),
              _buildTimeBalanceItem(
                context,
                '已损失',
                DurationFormatter.formatHours(lostH),
                Icons.remove_circle_outline,
                AppColors.danger,
              ),
              Container(width: 1, height: 40, color: AppColors.surfaceLight),
              _buildTimeBalanceItem(
                context,
                '净盈亏',
                DurationFormatter.formatHours(net),
                net >= 0 ? Icons.trending_up : Icons.trending_down,
                net >= 0 ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                '时空冻结',
                '${st.timeFreezesUsed}/1次',
                st.canFreeze ? AppColors.accent : AppColors.textHint,
              ),
              _buildMetricItem(
                '时间回溯',
                '${st.timeRewindsUsed}次',
                st.canRewind ? AppColors.accent : AppColors.textHint,
              ),
              _buildMetricItem(
                '娱乐惩罚',
                '${st.totalScreenPenalty.toStringAsFixed(1)}h',
                st.totalScreenPenalty > 0
                    ? AppColors.danger
                    : AppColors.textHint,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBalanceItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 10)),
      ],
    );
  }

  Widget _buildInsights(BuildContext context, Spacetime st) {
    final insights = <Map<String, dynamic>>[];

    if (st.disciplinePercentage >= 0.6) {
      final effectiveRate = st.effectiveFlowRate;
      final bonusPercent =
          ((st.currentFlowRate - effectiveRate) / st.currentFlowRate * 100)
              .toStringAsFixed(0);
      insights.add({
        'icon': Icons.bolt,
        'color': AppColors.flowSlow,
        'title': '心流钟慢模式已激活',
        'desc':
            '自律度超过60%，流速额外降低约$bonusPercent%，当前有效流速${DurationFormatter.formatFlowRate(effectiveRate)}。继续保持！',
      });
    }

    if (st.currentFlowRate > 1.5) {
      insights.add({
        'icon': Icons.warning,
        'color': AppColors.danger,
        'title': '流速过快警告',
        'desc':
            '当前流速${DurationFormatter.formatFlowRate(st.currentFlowRate)}，截止日正在加速到来，请立即行动！',
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
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text('个性化建议', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    i['icon'] as IconData,
                    color: i['color'] as Color,
                    size: 18,
                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
