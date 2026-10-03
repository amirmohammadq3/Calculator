import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class HistoryEntry {
  final String expression;
  final String result;
  final DateTime time;
  HistoryEntry({required this.expression, required this.result, required this.time});

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'result': result,
        'time': time.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        expression: j['expression'] as String? ?? '',
        result: j['result'] as String? ?? '',
        time: DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
      );
}

const List<int> kPrecisionOptions = [10, 20, 50, 100, 500, 1000];

class AppState extends ChangeNotifier {
  int decimalPrecision = 20;
  bool isDeg = true;
  final List<HistoryEntry> history = [];
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    decimalPrecision = prefs.getInt('decimal_precision') ?? 20;
    if (!kPrecisionOptions.contains(decimalPrecision)) decimalPrecision = 20;
    isDeg = prefs.getBool('is_deg') ?? true;
    final raw = prefs.getStringList('history') ?? [];
    history
      ..clear()
      ..addAll(raw.map((e) => HistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>)));
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPrecision(int p) async {
    decimalPrecision = p;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('decimal_precision', p);
  }

  Future<void> setDeg(bool v) async {
    isDeg = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_deg', v);
  }

  Future<void> addHistory(String expression, String result) async {
    history.insert(0, HistoryEntry(expression: expression, result: result, time: DateTime.now()));
    if (history.length > 300) history.removeRange(300, history.length);
    notifyListeners();
    await _persistHistory();
  }

  Future<void> removeHistoryAt(int index) async {
    if (index < 0 || index >= history.length) return;
    history.removeAt(index);
    notifyListeners();
    await _persistHistory();
  }

  Future<void> clearHistory() async {
    history.clear();
    notifyListeners();
    await _persistHistory();
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', history.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> vibrate() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 12);
      }
    } catch (_) {}
  }
}

final appState = AppState();

/// برای ویجت‌های Stateful که باید با تغییرات appState بازسازی شوند
mixin AppStateListenerMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    appState.removeListener(_onChange);
    super.dispose();
  }
}
