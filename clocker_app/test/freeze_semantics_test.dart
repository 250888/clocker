import 'package:flutter_test/flutter_test.dart';

import 'package:clocker/models/spacetime.dart';

/// 时空冻结语义：24 小时锁流速、7 天冷却。
void main() {
  Spacetime make({DateTime? lastFreeze, double focus = 5.6}) {
    return Spacetime(
      name: '冻结测试',
      // 固定到中午的日期，避免测试恰好跨天界导致两次求值差 1 天
      deadline: DateTime(2026, 11, 10, 12),
      createdAt: DateTime(2026, 11, 8, 12),
      totalFocusHours: focus,
      totalTaskValue: 2.0,
      totalScreenPenalty: 0.4,
      lastFreezeTime: lastFreeze,
    );
  }

  test('未冻结时按自律速度计算流速', () {
    final st = make();
    expect(st.isFrozen, isFalse);
    expect(st.canFreeze, isTrue);
    expect(st.effectiveFlowRate, isNot(1.0));
  });

  test('冻结后的 24 小时内：流速锁定 1.0×，APP 内天数 = 现实天数', () {
    final st = make(lastFreeze: DateTime.now().subtract(const Duration(hours: 1)));
    expect(st.isFrozen, isTrue);
    expect(st.effectiveFlowRate, 1.0);
    // 冻结时 APP 内剩余 == 现实剩余（两次求值允许 1 天的跨天界误差）
    expect((st.effectiveAppDaysRemaining - st.realDaysRemaining).abs(),
        lessThan(1.5));
    // 冻结剩余约 23 小时（执行耗时会差几毫秒，用分钟区间判断）
    expect(st.freezeRemaining.inMinutes, inInclusiveRange(22 * 60 + 55, 24 * 60));
    // 24 小时内不可再次冻结
    expect(st.canFreeze, isFalse);
  });

  test('超过 24 小时自动解冻，但未满 7 天不能再次冻结', () {
    final st = make(lastFreeze: DateTime.now().subtract(const Duration(hours: 25)));
    expect(st.isFrozen, isFalse);
    expect(st.effectiveFlowRate, isNot(1.0));
    expect(st.canFreeze, isFalse);
  });

  test('满 7 天后可以再次冻结（每周 1 次）', () {
    final st = make(lastFreeze: DateTime.now().subtract(const Duration(days: 8)));
    expect(st.isFrozen, isFalse);
    expect(st.canFreeze, isTrue);
  });

  test('冻结时长与冷却期常量正确', () {
    expect(Spacetime.freezeDuration, const Duration(hours: 24));
    expect(Spacetime.freezeCooldown, const Duration(days: 7));
  });
}
