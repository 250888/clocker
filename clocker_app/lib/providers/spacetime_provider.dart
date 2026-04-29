import 'package:flutter/material.dart';
import '../models/spacetime.dart';
import '../core/engine/lorentz_engine.dart';
import '../core/utils/database_factory.dart';

class SpacetimeProvider extends ChangeNotifier {
  List<Spacetime> _spacetimes = [];
  Spacetime? _activeSpacetime;
  final DatabaseHelperInterface _db = DatabaseFactory.create();

  List<Spacetime> get spacetimes => _spacetimes;
  Spacetime? get activeSpacetime => _activeSpacetime;

  Future<void> loadSpacetimes() async {
    _spacetimes = await _db.getAllSpacetimes();
    _activeSpacetime = _spacetimes.where((s) => s.isActive).isNotEmpty
        ? _spacetimes.firstWhere((s) => s.isActive)
        : null;
    notifyListeners();
  }

  Future<Spacetime> createSpacetime({
    required String name,
    required DateTime deadline,
    double v0 = 2.0,
    double c = 8.0,
    FlowMode flowMode = FlowMode.relativistic,
    int advanceDays = 14,
    String? emoji,
  }) async {
    final spacetime = Spacetime(
      name: name,
      deadline: deadline,
      v0: v0,
      c: c,
      flowMode: flowMode,
      advanceDays: advanceDays,
      emoji: emoji,
    );
    await _db.insertSpacetime(spacetime);
    _spacetimes.insert(0, spacetime);
    _activeSpacetime ??= spacetime;
    notifyListeners();
    return spacetime;
  }

  Future<void> updateSpacetime(Spacetime spacetime) async {
    await _db.updateSpacetime(spacetime);
    final idx = _spacetimes.indexWhere((s) => s.id == spacetime.id);
    if (idx >= 0) _spacetimes[idx] = spacetime;
    if (_activeSpacetime?.id == spacetime.id) {
      _activeSpacetime = spacetime;
    }
    notifyListeners();
  }

  Future<void> deleteSpacetime(String id) async {
    await _db.deleteSpacetime(id);
    _spacetimes.removeWhere((s) => s.id == id);
    if (_activeSpacetime?.id == id) {
      _activeSpacetime = _spacetimes.isNotEmpty ? _spacetimes.first : null;
    }
    notifyListeners();
  }

  void setActiveSpacetime(Spacetime spacetime) {
    for (var s in _spacetimes) {
      s = s.copyWith(isActive: s.id == spacetime.id);
      _db.updateSpacetime(s);
    }
    _activeSpacetime = spacetime;
    notifyListeners();
  }

  Future<void> addFocusHours(double hours) async {
    if (_activeSpacetime == null) return;
    final updated = _activeSpacetime!.copyWith(
      totalFocusHours: _activeSpacetime!.totalFocusHours + hours,
    );
    await updateSpacetime(updated);
  }

  Future<void> addTaskValue(double value) async {
    if (_activeSpacetime == null) return;
    final updated = _activeSpacetime!.copyWith(
      totalTaskValue: _activeSpacetime!.totalTaskValue + value,
    );
    await updateSpacetime(updated);
  }

  Future<void> addScreenPenalty(double penalty) async {
    if (_activeSpacetime == null) return;
    final updated = _activeSpacetime!.copyWith(
      totalScreenPenalty: _activeSpacetime!.totalScreenPenalty + penalty,
    );
    await updateSpacetime(updated);
  }

  Future<void> useTimeFreeze() async {
    if (_activeSpacetime == null || !_activeSpacetime!.canFreeze) return;
    final updated = _activeSpacetime!.copyWith(
      timeFreezesUsed: _activeSpacetime!.timeFreezesUsed + 1,
      lastFreezeTime: DateTime.now(),
    );
    await updateSpacetime(updated);
  }

  Future<void> useTimeRewind() async {
    if (_activeSpacetime == null) return;
    final updated = _activeSpacetime!.copyWith(
      timeRewindsUsed: _activeSpacetime!.timeRewindsUsed + 1,
    );
    await updateSpacetime(updated);
  }

  LorentzEngine? getEngine() {
    if (_activeSpacetime == null) return null;
    return LorentzEngine(
      v0: _activeSpacetime!.v0,
      c: _activeSpacetime!.c,
      flowMode: _activeSpacetime!.flowMode,
    );
  }
}
