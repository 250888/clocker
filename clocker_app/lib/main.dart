import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/constants/app_theme.dart';
import 'core/services/loading_screen_bridge.dart';
import 'models/focus_session.dart';
import 'models/task.dart';
import 'providers/spacetime_provider.dart';
import 'providers/task_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/app_shell.dart';
import 'screens/create_spacetime_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ClockerApp());
}

class ClockerApp extends StatelessWidget {
  const ClockerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpacetimeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Clocker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const _AppEntry(),
          '/create': (_) => const CreateSpacetimeScreen(),
        },
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final spacetimeProvider = context.read<SpacetimeProvider>();
      final taskProvider = context.read<TaskProvider>();
      final focusProvider = context.read<FocusProvider>();
      final achievementProvider = context.read<AchievementProvider>();

      await Future.wait([
        settingsProvider.loadSettings(),
        spacetimeProvider.loadSpacetimes(),
        achievementProvider.loadAchievements(),
      ]);

      if (spacetimeProvider.activeSpacetime != null) {
        await taskProvider.loadTasks(spacetimeProvider.activeSpacetime!.id);
      }

      // 演示/截图模式：--dart-define=DEMO_SEED=true 时写入一份可展示的数据。
      // 仅用于评审截图与录屏，不影响正常首次启动（默认 false）。
      if (const bool.fromEnvironment('DEMO_SEED')) {
        // 演示模式每次都重建数据，保证截图/录屏内容稳定可复现
        for (final existing in [...spacetimeProvider.spacetimes]) {
          await spacetimeProvider.deleteSpacetime(existing.id);
        }
        await _seedDemoData(spacetimeProvider, taskProvider, focusProvider);
      }

      focusProvider.configure(
        pomodoroMinutes: settingsProvider.settings.pomodoroDuration,
        enableWhiteNoise: settingsProvider.settings.enableWhiteNoise,
        enableScreenMonitoring:
            settingsProvider.settings.enableScreenMonitoring,
        enableCamera: settingsProvider.settings.enableCameraMonitoring,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        dismissHtmlLoadingScreen();
        setState(() => _initialized = true);
        if (const bool.fromEnvironment('OPEN_CREATE')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamed(context, '/create');
          });
        }
      }
    } catch (e) {
      dismissHtmlLoadingScreen();
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  /// 写入一份用于评审展示的演示数据（时空 + 任务 + 专注记录）。
  Future<void> _seedDemoData(
    SpacetimeProvider spacetime,
    TaskProvider tasks,
    FocusProvider focus,
  ) async {
    final st = await spacetime.createSpacetime(
      name: '考研冲刺',
      deadline: DateTime.now().add(const Duration(days: 18)),
      emoji: '🎓',
      advanceDays: 14,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    );
    // v ≈ 7.6 / c 8.0 → γ ≈ 3.2，流速 ≈ 0.62×（真正的「钟慢」演示态）
    await spacetime.addFocusHours(5.0);
    await spacetime.addTaskValue(2.8);
    await spacetime.addScreenPenalty(0.2);

    await tasks.loadTasks(st.id);
    await tasks.createTask(
      spacetimeId: st.id,
      title: '高数 · 第三章习题',
      vValueWeight: 2.0,
      priority: TaskPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );
    await tasks.createTask(
      spacetimeId: st.id,
      title: '英语单词 List 12',
      vValueWeight: 1.0,
      priority: TaskPriority.medium,
    );
    final report = await tasks.createTask(
      spacetimeId: st.id,
      title: '物理实验报告',
      vValueWeight: 1.5,
      priority: TaskPriority.urgent,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    );
    await tasks.completeTask(report);
    await tasks.createTask(
      spacetimeId: st.id,
      title: '论文文献精读',
      vValueWeight: 1.2,
      priority: TaskPriority.low,
      dueDate: DateTime.now().add(const Duration(days: 5)),
    );

    focus.setTargetDuration(const Duration(minutes: 25));
    focus.setMode(FocusMode.deepFocus);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_initialized) {
      return const SplashScreen();
    }
    return const AppShell();
  }
}
