import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
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

      focusProvider.configure(
        enableWhiteNoise: settingsProvider.settings.enableWhiteNoise,
        enableScreenMonitoring: settingsProvider.settings.enableScreenMonitoring,
        enableCamera: settingsProvider.settings.enableCameraMonitoring,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
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
                Text('Initialization Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
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
