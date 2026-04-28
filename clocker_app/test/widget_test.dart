import 'package:flutter_test/flutter_test.dart';
import 'package:clocker/core/engine/lorentz_engine.dart';
import 'package:clocker/core/engine/v_calculator.dart';

void main() {
  group('LorentzEngine', () {
    test('lorentzFactor returns 1 when v=0', () {
      final engine = LorentzEngine(v0: 2.0, c: 8.0);
      expect(engine.lorentzFactor(0), 1.0);
    });

    test('calculateFlowRate returns V0 when v=0', () {
      final engine = LorentzEngine(v0: 2.0, c: 8.0);
      expect(engine.calculateFlowRate(0), 2.0);
    });

    test('calculateFlowRate decreases as v increases', () {
      final engine = LorentzEngine(v0: 2.0, c: 8.0);
      final flowAt0 = engine.calculateFlowRate(0);
      final flowAt4 = engine.calculateFlowRate(4);
      final flowAt7 = engine.calculateFlowRate(7);
      expect(flowAt4, lessThan(flowAt0));
      expect(flowAt7, lessThan(flowAt4));
    });

    test('disciplinePercentage calculates correctly', () {
      final engine = LorentzEngine(v0: 2.0, c: 8.0);
      expect(engine.getDisciplinePercentage(4), 0.5);
      expect(engine.getDisciplinePercentage(0), 0.0);
    });

    test('isInFlowState returns true when discipline >= 0.6', () {
      final engine = LorentzEngine(v0: 2.0, c: 8.0);
      expect(engine.isInFlowState(5), true);
      expect(engine.isInFlowState(3), false);
    });

    test('linear mode calculates correctly', () {
      final engine = LorentzEngine(v0: 2.0, c: 8.0, flowMode: FlowMode.linear);
      final flowAt0 = engine.calculateFlowRate(0);
      final flowAt8 = engine.calculateFlowRate(8 * 0.9999);
      expect(flowAt0, 2.0);
      expect(flowAt8, lessThan(flowAt0));
    });

    test('exponential mode calculates correctly', () {
      final engine = LorentzEngine(v0: 2.0, c: 8.0, flowMode: FlowMode.exponential);
      final flowAt0 = engine.calculateFlowRate(0);
      expect(flowAt0, 2.0);
    });
  });

  group('VCalculator', () {
    test('calculateV clamps to c', () {
      final calc = VCalculator(c: 8.0);
      expect(calc.calculateV(focusHours: 10, taskValue: 0, screenPenalty: 0), 8.0);
    });

    test('calculateV clamps to 0', () {
      final calc = VCalculator(c: 8.0);
      expect(calc.calculateV(focusHours: 0, taskValue: 0, screenPenalty: 5), 0.0);
    });

    test('calculateVFromFocusOnly works', () {
      final calc = VCalculator(c: 8.0);
      expect(calc.calculateVFromFocusOnly(4), 4.0);
    });

    test('needsForcedBreak returns true after 4 hours', () {
      final calc = VCalculator(c: 8.0);
      expect(calc.needsForcedBreak(const Duration(hours: 4)), true);
      expect(calc.needsForcedBreak(const Duration(hours: 3)), false);
    });
  });
}
