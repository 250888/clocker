import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/spacetime_provider.dart';
import '../providers/focus_provider.dart';
import '../models/focus_session.dart';
import '../widgets/pomodoro_timer.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  FocusMode _selectedMode = FocusMode.deepFocus;
  Duration _targetDuration = const Duration(minutes: 25);
  double _cameraOpacity = 1.0;

  final List<Map<String, dynamic>> _durations = [
    {'label': '15分钟', 'duration': const Duration(minutes: 15)},
    {'label': '25分钟', 'duration': const Duration(minutes: 25)},
    {'label': '45分钟', 'duration': const Duration(minutes: 45)},
    {'label': '60分钟', 'duration': const Duration(minutes: 60)},
    {'label': '90分钟', 'duration': const Duration(minutes: 90)},
  ];

  final List<Map<String, dynamic>> _modes = [
    {
      'mode': FocusMode.deepFocus,
      'label': '深度专注',
      'icon': Icons.psychology,
      'color': AppColors.primary,
    },
    {
      'mode': FocusMode.study,
      'label': '刷题模式',
      'icon': Icons.quiz,
      'color': AppColors.accent,
    },
    {
      'mode': FocusMode.reading,
      'label': '阅读模式',
      'icon': Icons.menu_book,
      'color': AppColors.cosmic4,
    },
    {
      'mode': FocusMode.writing,
      'label': '写作模式',
      'icon': Icons.edit,
      'color': AppColors.warning,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final focusProvider = context.read<FocusProvider>();
    if (!focusProvider.isRunning) return;

    final isVisible = state == AppLifecycleState.resumed;
    focusProvider.screenMonitor.reportPageVisibility(isVisible);
  }

  @override
  Widget build(BuildContext context) {
    final spacetimeProvider = context.watch<SpacetimeProvider>();
    final focusProvider = context.watch<FocusProvider>();

    if (spacetimeProvider.activeSpacetime == null) {
      return _buildNoSpacetime(context);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('专注时空')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PomodoroTimer(
              elapsed: focusProvider.elapsed,
              target: focusProvider.targetDuration,
              isRunning: focusProvider.isRunning,
              isPaused: focusProvider.isPaused,
              mode: focusProvider.selectedMode,
              onStart: () => _startFocus(focusProvider, spacetimeProvider),
              onPause: focusProvider.pauseFocus,
              onResume: focusProvider.resumeFocus,
              onEnd: () => _endFocus(focusProvider, spacetimeProvider),
              onModeChange: focusProvider.isRunning ? null : _showModeSelector,
            ),
            const SizedBox(height: 16),
            if (!focusProvider.isRunning) ...[
              _buildDurationSelector(),
              const SizedBox(height: 16),
              _buildModeGrid(),
              const SizedBox(height: 16),
              _buildNoiseSelector(focusProvider),
              const SizedBox(height: 16),
              _buildMonitorToggles(focusProvider),
            ] else ...[
              _buildFocusStats(focusProvider, spacetimeProvider),
              const SizedBox(height: 12),
              _buildMonitorPanel(focusProvider),
              if (focusProvider.enableCamera) ...[
                const SizedBox(height: 12),
                _buildCameraPanel(focusProvider),
              ],
              if (focusProvider.enableAttentionMonitoring) ...[
                const SizedBox(height: 12),
                _buildAttentionPanel(focusProvider),
              ],
              if (focusProvider.enableWhiteNoise) ...[
                const SizedBox(height: 12),
                _buildVolumeControl(focusProvider),
              ],
            ],
            const SizedBox(height: 24),
            _buildRecentSessions(focusProvider, spacetimeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSpacetime(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('请先创建自律时空', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/create'),
            child: const Text('创建时空'),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('专注时长', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: _durations.map((item) {
            final isSelected = _targetDuration == item['duration'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(
                    () => _targetDuration = item['duration'] as Duration,
                  );
                  context.read<FocusProvider>().setTargetDuration(
                    _targetDuration,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: AppColors.primary)
                        : null,
                  ),
                  child: Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textHint,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModeGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('专注模式', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: _modes.map((item) {
            final isSelected = _selectedMode == item['mode'];
            final color = item['color'] as Color;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedMode = item['mode'] as FocusMode);
                context.read<FocusProvider>().setMode(_selectedMode);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: color) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'] as IconData, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.textHint,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoiseSelector(FocusProvider focusProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('白噪音', style: Theme.of(context).textTheme.titleMedium),
            Switch(
              value: focusProvider.enableWhiteNoise,
              onChanged: (v) => focusProvider.configure(enableWhiteNoise: v),
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
        if (focusProvider.enableWhiteNoise) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: focusProvider.audioService.soundOptions.map((sound) {
              final isSelected = focusProvider.selectedNoise == sound['id'];
              return GestureDetector(
                onTap: () => focusProvider.configure(
                  selectedNoise: sound['id'] as String,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (sound['color'] as Color).withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: sound['color'] as Color)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sound['icon'] as IconData,
                        color: sound['color'] as Color,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sound['name'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? sound['color'] as Color
                              : AppColors.textHint,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMonitorToggles(FocusProvider focusProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('监控选项', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('屏幕监控', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              '区分生产性/娱乐应用',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            value: focusProvider.enableScreenMonitoring,
            onChanged: (v) =>
                focusProvider.configure(enableScreenMonitoring: v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('注意力监控', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              '摄像头注意力检测',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            value: focusProvider.enableAttentionMonitoring,
            onChanged: (v) =>
                focusProvider.configure(enableAttentionMonitoring: v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('摄像头画面', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              '显示摄像头实时画面',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            value: focusProvider.enableCamera,
            onChanged: (v) => focusProvider.configure(enableCamera: v),
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFocusStats(
    FocusProvider focusProvider,
    SpacetimeProvider spacetimeProvider,
  ) {
    final st = spacetimeProvider.activeSpacetime;
    if (st == null) return const SizedBox.shrink();
    final engine = spacetimeProvider.getEngine();
    final safeC = st.c > 0 ? st.c : 1.0;
    final currentV = st.currentV + (focusProvider.elapsed.inMinutes / 60.0);
    final newFlowRate = engine != null
        ? engine.calculateFlowRate(currentV.clamp(0.0, safeC))
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '当前v值',
                '${currentV.toStringAsFixed(1)}h',
                AppColors.accent,
              ),
              _buildStatItem(
                '实时流速',
                '${newFlowRate.toStringAsFixed(2)}x',
                newFlowRate <= 1.0 ? AppColors.flowSlow : AppColors.flowFast,
              ),
              _buildStatItem(
                '分心次数',
                '${focusProvider.distractionCount}',
                AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: focusProvider.recordDistraction,
              icon: const Icon(Icons.notifications_off, size: 16),
              label: const Text('记录分心'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorPanel(FocusProvider focusProvider) {
    final screenReport = focusProvider.screenMonitor.getReport();
    final efficiency = focusProvider.screenMonitor.productivityRatio;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor, color: AppColors.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                '屏幕监控',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (efficiency >= 0.7
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '效率 ${(efficiency * 100).toInt()}%',
                  style: TextStyle(
                    color: efficiency >= 0.7
                        ? AppColors.success
                        : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                '生产',
                '${screenReport['productiveMinutes'] ?? 0}分',
                AppColors.success,
              ),
              _buildMiniStat(
                '娱乐',
                '${screenReport['unproductiveMinutes'] ?? 0}分',
                AppColors.danger,
              ),
              _buildMiniStat(
                '切换',
                '${screenReport['appSwitchCount'] ?? 0}次',
                AppColors.info,
              ),
              _buildMiniStat(
                '当前',
                '${screenReport['currentApp'] ?? 'N/A'}',
                AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPanel(FocusProvider focusProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videocam, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                '摄像头监控',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: focusProvider.isCameraActive
                      ? AppColors.success
                      : AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                focusProvider.isCameraActive ? '运行中' : '未启动',
                style: TextStyle(
                  color: focusProvider.isCameraActive
                      ? AppColors.success
                      : AppColors.danger,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '摄像头画面显示在页面右上角，用于注意力检测和人脸追踪',
            style: TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
          if (focusProvider.isCameraActive) ...[
            const SizedBox(height: 10),
            Center(
              child:
                  focusProvider.cameraService.buildCameraPreview() ??
                  Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam,
                            color: AppColors.primary.withValues(alpha: 0.5),
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '摄像头预览',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _cameraOpacity,
                  min: 0.3,
                  max: 1.0,
                  divisions: 7,
                  onChanged: (v) {
                    setState(() => _cameraOpacity = v);
                    focusProvider.cameraService.setOpacity(v);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              Text(
                '透明度',
                style: TextStyle(color: AppColors.textHint, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionPanel(FocusProvider focusProvider) {
    final attention = focusProvider.attentionMonitor;
    final score = attention.attentionScore;
    final scorePercent = (score * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: attention.isInFlowState
              ? AppColors.flowSlow.withValues(alpha: 0.5)
              : AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (attention.isInFlowState) ...[
                Icon(Icons.bolt, color: AppColors.flowSlow, size: 16),
                const SizedBox(width: 4),
                Text(
                  '心流状态',
                  style: TextStyle(
                    color: AppColors.flowSlow,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Icon(Icons.visibility, color: AppColors.info, size: 16),
                const SizedBox(width: 6),
                Text(
                  '注意力监控',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '$scorePercent%',
                style: TextStyle(
                  color: score >= 0.8
                      ? AppColors.success
                      : score >= 0.5
                      ? AppColors.warning
                      : AppColors.danger,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 0.8
                    ? AppColors.success
                    : score >= 0.5
                    ? AppColors.warning
                    : AppColors.danger,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                '人脸',
                attention.faceDetected > 0.5 ? '✓' : '✗',
                attention.faceDetected > 0.5
                    ? AppColors.success
                    : AppColors.danger,
              ),
              _buildMiniStat(
                '眼睛',
                '${(attention.eyeOpenness * 100).toInt()}%',
                attention.eyeOpenness > 0.5
                    ? AppColors.success
                    : AppColors.warning,
              ),
              _buildMiniStat(
                '分心',
                '${attention.distractionEvents}次',
                AppColors.warning,
              ),
              _buildMiniStat(
                '稳定',
                '${(attention.focusStability * 100).toInt()}%',
                AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(FocusProvider focusProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_down, color: AppColors.textSecondary, size: 20),
          Expanded(
            child: Slider(
              value: focusProvider.volume,
              min: 0.0,
              max: 1.0,
              onChanged: (v) => focusProvider.adjustVolume(v),
              activeColor: AppColors.primary,
            ),
          ),
          Icon(Icons.volume_up, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 10)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
    );
  }

  Widget _buildRecentSessions(
    FocusProvider focusProvider,
    SpacetimeProvider spacetimeProvider,
  ) {
    final spacetimeId = spacetimeProvider.activeSpacetime?.id;
    if (spacetimeId == null) return const SizedBox.shrink();
    return FutureBuilder<List<FocusSession>>(
      future: focusProvider.getFocusHistory(spacetimeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final sessions = snapshot.data!.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最近专注', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...sessions.map(
              (s) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      s.wasFlowState ? Icons.bolt : Icons.timer,
                      color: s.wasFlowState
                          ? AppColors.flowSlow
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.modeName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${s.actualDuration.inMinutes}分钟 | v+${s.vValueEarned.toStringAsFixed(1)}h',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (s.wasDistractionFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '零分心',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _modes.map((item) {
            return ListTile(
              leading: Icon(
                item['icon'] as IconData,
                color: item['color'] as Color,
              ),
              title: Text(item['label'] as String),
              onTap: () {
                setState(() => _selectedMode = item['mode'] as FocusMode);
                context.read<FocusProvider>().setMode(_selectedMode);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _startFocus(
    FocusProvider focusProvider,
    SpacetimeProvider spacetimeProvider,
  ) {
    focusProvider.startFocus(spacetimeProvider.activeSpacetime!.id);
  }

  Future<void> _endFocus(
    FocusProvider focusProvider,
    SpacetimeProvider spacetimeProvider,
  ) async {
    await focusProvider.completeFocus();

    if (focusProvider.currentSession != null) {
      final session = focusProvider.currentSession!;
      await spacetimeProvider.addFocusHours(session.vValueEarned);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                Icon(
                  session.wasFlowState ? Icons.bolt : Icons.check_circle,
                  color: session.wasFlowState
                      ? AppColors.flowSlow
                      : AppColors.success,
                ),
                const SizedBox(width: 8),
                const Text('专注完成'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('时长: ${session.actualDuration.inMinutes}分钟'),
                Text('v值: +${session.vValueEarned.toStringAsFixed(2)}h'),
                Text('分心: ${session.distractionCount}次'),
                if (session.wasFlowState)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.bolt, color: AppColors.flowSlow, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '进入心流状态！',
                          style: TextStyle(color: AppColors.flowSlow),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('好的'),
              ),
            ],
          ),
        );
      }
    }
  }
}
