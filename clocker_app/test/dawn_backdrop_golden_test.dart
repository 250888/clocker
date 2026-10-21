@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/core/constants/app_colors.dart';
import 'package:clocker/widgets/dawn_backdrop.dart';

void main() {
  testWidgets('dawn backdrop renders', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const goldenKey = Key('dawn-backdrop-golden');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: RepaintBoundary(
            key: goldenKey,
            child: DawnBackdrop(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/dawn_backdrop.png'),
    );
  });
}
