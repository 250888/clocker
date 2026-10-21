@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/core/constants/app_colors.dart';
import 'package:clocker/core/constants/app_theme.dart';
import 'package:clocker/models/spacetime.dart';
import 'package:clocker/widgets/dawn_backdrop.dart';
import 'package:clocker/widgets/dawn_dashboard_hero.dart';

void main() {
  testWidgets('dawn dashboard hero renders', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const goldenKey = Key('dawn-dashboard-golden');

    final spacetime = Spacetime(
      name: '考研冲刺',
      deadline: DateTime(2026, 11, 9),
      createdAt: DateTime(2026, 10, 1),
      totalFocusHours: 42,
      totalTaskValue: 18,
      totalScreenPenalty: 6,
      emoji: '🎯',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: RepaintBoundary(
            key: goldenKey,
            child: Stack(
              children: [
                const Positioned.fill(child: DawnBackdrop(showTrails: false)),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 96, 20, 24),
                  child: DawnDashboardHero(spacetime: spacetime),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/dawn_dashboard.png'),
    );
  });
}
