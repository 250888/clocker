import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/providers/focus_provider.dart';
import 'package:clocker/providers/settings_provider.dart';

import 'test_support.dart';

/// 番茄钟时长接线：规则页改时长 → 专注页默认时长同步生效。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestDatabase);
  setUp(() async {
    await initTestDatabase();
    await resetTestDatabase();
  });

  test('规则页设置番茄钟时长后，专注默认时长立即同步', () async {
    final settings = SettingsProvider();
    await settings.loadSettings();
    final focus = FocusProvider();

    // 启动注入（模拟 main.dart）
    focus.configure(pomodoroMinutes: settings.settings.pomodoroDuration);
    expect(focus.targetDuration.inMinutes, settings.settings.pomodoroDuration);

    // 规则页把番茄钟改为 45 分钟 → 专注页同步
    await settings.setPomodoroDuration(45);
    focus.configure(pomodoroMinutes: settings.settings.pomodoroDuration);
    expect(focus.targetDuration.inMinutes, 45);
  });

  test('专注进行中不被规则页改动打断', () async {
    final focus = FocusProvider();
    focus.configure(pomodoroMinutes: 25);
    focus.startFocus('sp-x');
    expect(focus.isRunning, isTrue);

    // 专注中再改规则，不应改变本次目标
    focus.configure(pomodoroMinutes: 60);
    expect(focus.targetDuration.inMinutes, 25,
        reason: '进行中的专注不应被改时长');

    await focus.cancelFocus();
  });

  test('自定义时长接受非预设值（如 37 分钟）', () {
    final focus = FocusProvider();
    focus.setTargetDuration(const Duration(minutes: 37));
    expect(focus.targetDuration.inMinutes, 37);
    expect(focus.targetDuration, isNot(const Duration(minutes: 15)));
    expect(focus.targetDuration, isNot(const Duration(minutes: 25)));
  });
}
