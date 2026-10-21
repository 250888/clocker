@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/core/constants/app_colors.dart';
import 'package:clocker/core/constants/app_theme.dart';
import 'package:clocker/models/focus_session.dart';
import 'package:clocker/widgets/dawn_backdrop.dart';
import 'package:clocker/widgets/dawn_timer.dart';

void main() {
  testWidgets('dawn focus composition renders', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const goldenKey = Key('dawn-focus-golden');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: RepaintBoundary(
            key: goldenKey,
            child: Stack(
              children: [
                const Positioned.fill(child: DawnBackdrop()),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
                  child: DawnTimer(
                    elapsed: const Duration(minutes: 12, seconds: 24),
                    target: const Duration(minutes: 25),
                    isRunning: false,
                    isPaused: false,
                    mode: FocusMode.deepFocus,
                    onStart: () {},
                    onPause: () {},
                    onResume: () {},
                    onEnd: () {},
                    onModeChange: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/dawn_focus.png'),
    );
  });
}
