import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/audio_service.dart';
import '../core/widgets/camera_view.dart';
import '../providers/spacetime_provider.dart';
import '../providers/settings_provider.dart';
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
  double _noiseVolume = 0.5;

  final List<Map<String, dynamic>> _durations = [
    {'label': '15分钟', 'duration': const Duration(minutes: 15)},
    {'label': '25分钟', 'duration': const Duration(minutes: 25)},
    {'label': '45分钟', 'duration': const Duration(minutes: 45)},
    {'label': '60分钟', 'duration': const Duration(minutes: 60)},
    {'label': '90分钟', 'duration': const Duration(minutes: 90)},
  ];

  final List<Map<String, dynamic>> _modes = [
    {'mode': FocusMode.deepFocus, 'label': '深度专注', 'icon': Icons.psychology, 'color': AppColors.primary},
    {'mode': FocusMode.study, 'label': '刷题模式', 'icon': Icons.quiz, 'color': AppColors.accent},
    {'mode': FocusMode.reading, 'label': '阅读模式', 'icon': Icons.menu_book, 'color': AppColors.cosmic4},
    {'mode': FocusMode.writing, 'label': '写作模式', 'icon': Icons.edit, 'color': AppColors.warning},
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
    if (focusProvider.isRunning) {
      final isVisible = state == AppLifecycleState.resumed;
      focusProvider.screenMonitor.reportPageVisibility(isVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacetimeProvider = context.watch<SpacetimeProvider>();
    final focusProvider = context.watch<FocusProvider>();

    if (spacetimeProvider.activeSpacetime == null) {
      return _buildNoSpacetime(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('专注时空'),
      ),
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
            const SizedBox(height: 24),
            if (!focusProvider.isRunning) ...[
              _buildDurationSelector(),
              const SizedBox(height: 16),
              _buildModeGrid(),
              const SizedBox(height: 16),
              _buildWhiteNoiseSelector(),
            ] else ...[
              _buildFocusStats(focusProvider, spacetimeProvider),
              const SizedBox(height: 12),
              _buildMonitorPanel(focusProvider),
              const SizedBox(height: 12),
              if (focusProvider.enableWhiteNoise) _buildVolumeControl(focusProvider),
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
                  setState(() => _targetDuration = item['duration'] as Duration);
                  context.read<FocusProvider>().setTargetDuration(_targetDuration);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(color: AppColors.primary) : null,
                  ),
                  child: Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textHint,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                  color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceLight,
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

  Widget _buildFocusStats(FocusProvider focusProvider, SpacetimeProvider spacetimeProvider) {
    final st = spacetimeProvider.activeSpacetime!;
    final engine = spacetimeProvider.getEngine()!;
    final currentV = st.currentV + (focusProvider.elapsed.inMinutes / 60.0);
    final newFlowRate = engine.calculateFlowRate(currentV.clamp(0, st.c));

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
              _buildStatItem('当前v值', '${currentV.toStringAsFixed(1)}h', AppColors.accent),
              _buildStatItem('实时流速', '${newFlowRate.toStringAsFixed(2)}x',
                  newFlowRate <= 1.0 ? AppColors.flowSlow : AppColors.flowFast),
              _buildStatItem('分心次数', '${focusProvider.distractionCount}', AppColors.warning),
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
    );
  }

  Widget _buildMonitorPanel(FocusProvider focusProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart, color: AppColors.info, size: 18),
              const SizedBox(width: 6),
              Text('实时监控',
                  style: TextStyle(color: AppColors.info, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (focusProvider.attentionMonitor.isInFlowState)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.flowSlow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: AppColors.flowSlow, size: 12),
                      const SizedBox(width: 3),
                      Text('心流', style: TextStyle(color: AppColors.flowSlow, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 摄像头画面
          if (focusProvider.enableAttentionMonitoring) ...[
            _buildMonitorSection(
              icon: Icons.videocam,
              title: '摄像头',
              color: AppColors.success,
              child: CameraView(
                width: double.infinity,
                height: 120,
                isActive: focusProvider.isRunning,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 屏幕监控
          if (focusProvider.enableScreenMonitoring) ...[
            _buildMonitorSection(
              icon: Icons.screen_lock_portrait,
              title: '屏幕监控',
              color: AppColors.accent,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('效率比', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text('${(focusProvider.screenMonitor.productivityRatio * 100).toInt()}%',
                          style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: focusProvider.screenMonitor.productivityRatio,
                      backgroundColor: AppColors.danger.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        focusProvider.screenMonitor.productivityRatio > 0.7
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('当前: ${focusProvider.screenMonitor.currentApp}',
                          style: TextStyle(color: AppColors.textHint, fontSize: 10)),
                      Text('切换: ${focusProvider.screenMonitor.appSwitchCount}次',
                          style: TextStyle(color: AppColors.textHint, fontSize: 10)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('高效: ${focusProvider.screenMonitor.productiveTime.inMinutes}分钟',
                          style: TextStyle(color: AppColors.success, fontSize: 10)),
                      Text('低效: ${focusProvider.screenMonitor.unproductiveTime.inMinutes}分钟',
                          style: TextStyle(color: AppColors.danger, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 注意力监控
          if (focusProvider.enableAttentionMonitoring) ...[
            _buildMonitorSection(
              icon: Icons.visibility,
              title: '注意力监控',
              color: focusProvider.attentionMonitor.isInFlowState ? AppColors.flowSlow : AppColors.primary,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('注意力分数', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text('${(focusProvider.attentionMonitor.attentionScore * 100).toInt()}%',
                          style: TextStyle(
                            color: focusProvider.attentionMonitor.attentionScore > 0.7
                                ? AppColors.success
                                : focusProvider.attentionMonitor.attentionScore > 0.4
                                    ? AppColors.warning
                                    : AppColors.danger,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: focusProvider.attentionMonitor.attentionScore,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        focusProvider.attentionMonitor.attentionScore > 0.7
                            ? AppColors.success
                            : focusProvider.attentionMonitor.attentionScore > 0.4
                                ? AppColors.warning
                                : AppColors.danger,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('分心: ${focusProvider.attentionMonitor.distractionEvents}次',
                          style: TextStyle(color: AppColors.textHint, fontSize: 10)),
                      Text('稳定: ${(focusProvider.attentionMonitor.focusStability * 100).toInt()}%',
                          style: TextStyle(color: AppColors.textHint, fontSize: 10)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('专注: ${focusProvider.attentionMonitor.focusedDuration.inMinutes}分钟',
                          style: TextStyle(color: AppColors.success, fontSize: 10)),
                      Text('连续: ${focusProvider.attentionMonitor.currentFocusStreak.inMinutes}分钟',
                          style: TextStyle(color: AppColors.flowSlow, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.face,
                          size: 10,
                          color: focusProvider.attentionMonitor.faceDetected > 0.5
                              ? AppColors.success : AppColors.danger),
                      const SizedBox(width: 3),
                      Text(focusProvider.attentionMonitor.faceDetected > 0.5 ? '人脸: 在' : '人脸: 离开',
                          style: TextStyle(
                              color: focusProvider.attentionMonitor.faceDetected > 0.5
                                  ? AppColors.success : AppColors.danger,
                              fontSize: 9)),
                      const SizedBox(width: 8),
                      Icon(Icons.remove_red_eye,
                          size: 10,
                          color: focusProvider.attentionMonitor.eyeOpenness > 0.5
                              ? AppColors.success : AppColors.warning),
                      const SizedBox(width: 3),
                      Text('眼: ${(focusProvider.attentionMonitor.eyeOpenness * 100).toInt()}%',
                          style: TextStyle(color: AppColors.textHint, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 白噪音状态
          if (focusProvider.enableWhiteNoise) ...[
            _buildMonitorSection(
              icon: Icons.graphic_eq,
              title: '白噪音',
              color: AppColors.primary,
              child: Row(
                children: [
                  Icon(AudioService().soundOptions.firstWhere(
                      (s) => s['id'] == focusProvider.whiteNoiseType,
                      orElse: () => {'icon': Icons.music_note})['icon'] as IconData,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(AudioService().soundOptions.firstWhere(
                      (s) => s['id'] == focusProvider.whiteNoiseType,
                      orElse: () => {'name': '未知'})['name'] as String,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  const Spacer(),
                  Icon(AudioService().isPlaying ? Icons.volume_up : Icons.volume_off,
                      color: AppColors.primary, size: 14),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonitorSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildVolumeControl(FocusProvider focusProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_down, color: AppColors.textHint, size: 18),
          Expanded(
            child: Slider(
              value: _noiseVolume,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.surfaceLight,
              onChanged: (v) {
                setState(() => _noiseVolume = v);
                focusProvider.audio.setVolume(v);
              },
            ),
          ),
          Icon(Icons.volume_up, color: AppColors.textHint, size: 18),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(FocusProvider focusProvider, SpacetimeProvider spacetimeProvider) {
    return FutureBuilder<List<FocusSession>>(
      future: focusProvider.getFocusHistory(spacetimeProvider.activeSpacetime!.id),
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
            ...sessions.map((s) => Container(
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
                        color: s.wasFlowState ? AppColors.flowSlow : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.modeName,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            ),
                            Text(
                              '${s.actualDuration.inMinutes}分钟 | v+${s.vValueEarned.toStringAsFixed(1)}h',
                              style: TextStyle(color: AppColors.textHint, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (s.wasDistractionFree)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '零分心',
                            style: TextStyle(color: AppColors.success, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildWhiteNoiseSelector() {
    final audioService = AudioService();
    final settings = context.watch<SettingsProvider>().settings;

    if (!settings.enableWhiteNoise) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('白噪音', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.2,
          children: audioService.soundOptions.map((sound) {
            final isSelected = context.read<FocusProvider>().whiteNoiseType == sound['id'];
            final color = sound['color'] as Color;
            return GestureDetector(
              onTap: () {
                context.read<FocusProvider>().configure(noiseType: sound['id'] as String);
                setState(() {});
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? Border.all(color: color) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(sound['icon'] as IconData, color: color, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      sound['name'] as String,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.textHint,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
              leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
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

  void _startFocus(FocusProvider focusProvider, SpacetimeProvider spacetimeProvider) {
    final settings = context.read<SettingsProvider>().settings;
    focusProvider.configure(
      soundEffects: settings.enableSoundEffects,
      whiteNoise: settings.enableWhiteNoise,
      screenMonitoring: settings.enableScreenMonitoring,
      attentionMonitoring: settings.enableCameraMonitoring,
    );
    final flowRate = spacetimeProvider.activeSpacetime?.currentFlowRate ?? 1.0;
    focusProvider.startFocus(spacetimeProvider.activeSpacetime!.id, flowRate: flowRate);
  }

  Future<void> _endFocus(FocusProvider focusProvider, SpacetimeProvider spacetimeProvider) async {
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
                Icon(session.wasFlowState ? Icons.bolt : Icons.check_circle,
                    color: session.wasFlowState ? AppColors.flowSlow : AppColors.success),
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
                        Text('进入心流状态！', style: TextStyle(color: AppColors.flowSlow)),
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
