import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/core/constants/app_theme.dart';
import 'package:clocker/models/achievement.dart';
import 'package:clocker/widgets/achievement_badge.dart';

/// 成就徽章：未解锁显示「获得条件」，已解锁显示奖励。
void main() {
  testWidgets('未解锁徽章显示获得条件而不是奖励', (tester) async {
    final locked = Achievement(
      name: '初入时空',
      description: '完成第一次专注',
      tier: AchievementTier.restFrame,
      category: AchievementCategory.focus,
      reward: '解锁基础主题',
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 90, height: 110, child: AchievementBadge(achievement: locked)),
        ),
      ),
    ));

    expect(find.text('初入时空'), findsOneWidget);
    expect(find.text('完成第一次专注'), findsOneWidget, reason: '锁定态应显示获得条件');
    expect(find.text('解锁基础主题'), findsNothing, reason: '锁定态不应显示奖励');
  });

  testWidgets('已解锁徽章显示奖励与线性图标', (tester) async {
    final unlocked = Achievement(
      name: '初入时空',
      description: '完成第一次专注',
      tier: AchievementTier.restFrame,
      category: AchievementCategory.focus,
      reward: '解锁基础主题',
      isUnlocked: true,
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 90, height: 110, child: AchievementBadge(achievement: unlocked)),
        ),
      ),
    ));

    expect(find.text('解锁基础主题'), findsOneWidget, reason: '解锁态应显示奖励');
    expect(find.text('完成第一次专注'), findsNothing);
    expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);
  });
}
