import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/models/focus_session.dart';
import 'package:clocker/widgets/weekly_focus_chart.dart';

/// 近 7 天专注柱状图的聚合口径：左→右 = 6 天前 → 今天。
void main() {
  FocusSession session({required DateTime at, int minutes = 60}) {
    return FocusSession(
      spacetimeId: 'sp',
      mode: FocusMode.deepFocus,
      status: FocusStatus.completed,
      startTime: at,
      endTime: at.add(Duration(minutes: minutes)),
      actualDuration: Duration(minutes: minutes),
    );
  }

  test('按天聚合：今天在最右、6 天前在最左、更早与未来被忽略', () {
    final now = DateTime(2026, 10, 22, 13, 0);
    final sessions = [
      session(at: DateTime(2026, 10, 22, 9), minutes: 90), // 今天
      session(at: DateTime(2026, 10, 19, 8), minutes: 30), // 3 天前
      session(at: DateTime(2026, 10, 16, 7), minutes: 120), // 6 天前
      session(at: DateTime(2026, 10, 14, 7), minutes: 60), // 8 天前 → 忽略
      session(at: DateTime(2026, 10, 23, 7), minutes: 45), // 未来 → 忽略
    ];

    final buckets = weeklyFocusHours(sessions, now: now);
    expect(buckets.length, 7);
    expect(buckets[0], closeTo(2.0, 1e-9), reason: '最左应为 6 天前');
    expect(buckets[3], closeTo(0.5, 1e-9), reason: '中间应为 3 天前');
    expect(buckets[6], closeTo(1.5, 1e-9), reason: '最右应为今天');
    expect(buckets[1] + buckets[2] + buckets[4] + buckets[5], 0);
  });

  test('同一天多场专注会累加', () {
    final now = DateTime(2026, 10, 22, 20);
    final sessions = [
      session(at: DateTime(2026, 10, 22, 8), minutes: 50),
      session(at: DateTime(2026, 10, 22, 14), minutes: 25),
    ];
    final buckets = weeklyFocusHours(sessions, now: now);
    expect(buckets[6], closeTo(75 / 60, 1e-9));
  });

  test('没有会话时七天全为 0（图表显示为最小占位）', () {
    final buckets = weeklyFocusHours(const [], now: DateTime(2026, 10, 22));
    expect(buckets.every((b) => b == 0), isTrue);
  });
}
