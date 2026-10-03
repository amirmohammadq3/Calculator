import 'package:flutter/material.dart';
import '../bignum/big_math.dart';
import '../common/app_state.dart';
import '../converter/converter_screen.dart';
import '../export/export_service.dart';
import 'ast.dart';
import 'evaluator.dart';
import 'history_screen.dart';

const _bg = Color(0xFF0D121E);
const _panel = Color(0xFF131A2B);
const _card = Color(0xFF17213A);
const _accent = Color(0xFF3EA6FF);
const _accent2 = Color(0xFF7C4DFF);

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with AppStateListenerMixin {
  String _expr = '';
  String _resultDisplay = '';
  List<String> _lastSteps = [];
  bool _justEvaluated = false;
  bool _secondMode = false;
  String? _errorText;

  void _append(String s) {
    appState.vibrate();
    setState(() {
      if (_justEvaluated) {
        final isOperator = s.length == 1 && '+-×÷^%'.contains(s);
        _expr = isOperator ? _resultDisplay + s : s;
        _resultDisplay = '';
        _lastSteps = [];
        _justEvaluated = false;
      } else {
        _expr += s;
      }
      _errorText = null;
    });
  }

  void _clearAll() {
    appState.vibrate();
    setState(() {
      _expr = '';
      _resultDisplay = '';
      _lastSteps = [];
      _justEvaluated = false;
      _errorText = null;
    });
  }

  void _backspace() {
    appState.vibrate();
    setState(() {
      if (_justEvaluated) {
        _expr = '';
        _resultDisplay = '';
        _lastSteps = [];
        _justEvaluated = false;
        return;
      }
      if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
      _errorText = null;
    });
  }

  String _autoCloseParens(String s) {
    final opens = '('.allMatches(s).length;
    final closes = ')'.allMatches(s).length;
    if (opens > closes) return s + (')' * (opens - closes));
    return s;
  }

  Future<BigDec?> _askXValue() async {
    final ctrl = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('مقدار x را وارد کنید', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('محاسبه')),
        ],
      ),
    );
    if (v == null || v.trim().isEmpty) return null;
    try {
      return BigDec.parse(v.trim());
    } catch (_) {
      return null;
    }
  }

  void _showSteps() {
    if (_lastSteps.isEmpty) return;
    appState.vibrate();
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(18),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            const Text('مراحل محاسبه', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            for (int i = 0; i < _lastSteps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == _lastSteps.length - 1 ? _accent : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          _lastSteps[i],
                          style: TextStyle(
                            color: i == _lastSteps.length - 1 ? Colors.white : Colors.white60,
                            fontSize: i == _lastSteps.length - 1 ? 17 : 14,
                            fontWeight: i == _lastSteps.length - 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _evaluate() async {
    if (_expr.trim().isEmpty) return;
    appState.vibrate();
    final raw = _autoCloseParens(_expr);
    try {
      final parsed = parseInput(raw);
      final precision = appState.decimalPrecision;
      final deg = appState.isDeg;

      if (parsed.isEquation) {
        final sol = solveEquation(parsed.left!, parsed.right!, precision: precision);
        String resultLine;
        if (sol.noRealSolution) {
          resultLine = sol.roots.isEmpty && sol.steps.last.contains('بی‌نهایت') ? 'بی‌نهایت جواب' : 'بدون جواب حقیقی';
        } else if (sol.roots.length == 1) {
          resultLine = 'x = ${sol.roots[0].toDisplayString(precision)}';
        } else {
          resultLine = 'x₁=${sol.roots[0].toDisplayString(precision)} , x₂=${sol.roots[1].toDisplayString(precision)}';
        }
        setState(() {
          _lastSteps = sol.steps;
          _resultDisplay = resultLine;
          _justEvaluated = true;
        });
        await appState.addHistory(raw, resultLine);
        return;
      }

      if (parsed.hasVar) {
        final xVal = await _askXValue();
        if (xVal == null) return;
        final se = evaluateWithSteps(parsed.left!, precision: precision, deg: deg, xValue: xVal);
        final resultLine = se.result.toDisplayString(precision);
        setState(() {
          _lastSteps = se.steps;
          _resultDisplay = resultLine;
          _justEvaluated = true;
        });
        await appState.addHistory('$raw  (x=${xVal.toDisplayString(precision)})', resultLine);
        return;
      }

      final se = evaluateWithSteps(parsed.left!, precision: precision, deg: deg);
      final resultLine = se.result.toDisplayString(precision);
      setState(() {
        _lastSteps = se.steps;
        _resultDisplay = resultLine;
        _justEvaluated = true;
      });
      await appState.addHistory(raw, resultLine);
    } on PolyUnsupported catch (e) {
      setState(() => _errorText = e.message);
    } on ParseException catch (e) {
      setState(() => _errorText = e.message);
    } on MathEvalException catch (e) {
      setState(() => _errorText = e.message);
    } on FormatException catch (e) {
      setState(() => _errorText = e.message);
    } catch (e) {
      setState(() => _errorText = 'خطا در محاسبه');
    }
  }

  Future<void> _showExportSheet() async {
    if (!_justEvaluated || _resultDisplay.isEmpty) return;
    appState.vibrate();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ذخیره‌ی جواب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: _accent),
                title: const Text('فایل متنی (txt)', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, 'txt'),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined, color: Colors.greenAccent),
                title: const Text('فایل اکسل (xlsx)', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, 'xlsx'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    bool ok = false;
    try {
      if (choice == 'txt') {
        ok = await ExportService.exportTxt(_expr, _resultDisplay);
      } else {
        ok = await ExportService.exportXlsx(_expr, _resultDisplay);
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'ذخیره شد' : 'ذخیره انجام نشد')),
    );
  }

  Future<void> _showPrecisionPicker() async {
    appState.vibrate();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              const Text('تعداد اعشار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              ...kPrecisionOptions.map((p) {
                final selected = appState.decimalPrecision == p;
                return InkWell(
                  onTap: () async {
                    appState.vibrate();
                    await appState.setPrecision(p);
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? _accent : Colors.white38, size: 20),
                        const SizedBox(width: 12),
                        Text('$p', style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 15)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openHistory() async {
    appState.vibrate();
    final picked = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
    if (picked != null) {
      setState(() {
        _expr = picked;
        _resultDisplay = '';
        _lastSteps = [];
        _justEvaluated = false;
        _errorText = null;
      });
    }
  }

  void _openConverter() {
    appState.vibrate();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ConverterScreen()));
  }

  // -------------------- ساخت رابط کاربری --------------------

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openHistory,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: _panel, shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
              child: const Icon(Icons.history, color: Colors.white70, size: 20),
            ),
          ),
          const Spacer(),
          const Text('ماشین‌حساب مهندسی', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          GestureDetector(
            onTap: _openConverter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(21), border: Border.all(color: Colors.white10)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: Colors.white70, size: 18),
                  SizedBox(width: 6),
                  Text('تبدیل واحد', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _display() {
    final showExpr = _justEvaluated ? _expr : '';
    final mainText = _justEvaluated ? _resultDisplay : (_expr.isEmpty ? '0' : _expr);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showExpr.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(showExpr, style: const TextStyle(color: Colors.white38, fontSize: 15)),
              ),
            ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                mainText,
                style: TextStyle(
                  color: _errorText != null ? Colors.redAccent : Colors.white,
                  fontSize: _justEvaluated ? 36 : 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _showPrecisionPicker,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _panel,
                    border: Border.all(color: _accent.withOpacity(0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${appState.decimalPrecision}',
                    style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Row(
                children: [
                  if (_lastSteps.length > 1)
                    TextButton.icon(
                      onPressed: _showSteps,
                      icon: const Icon(Icons.list_alt, color: _accent2, size: 18),
                      label: const Text('مراحل', style: TextStyle(color: _accent2, fontSize: 12)),
                    ),
                  GestureDetector(
                    onTap: _showExportSheet,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _panel, border: Border.all(color: Colors.white10)),
                      child: Icon(Icons.ios_share, color: _justEvaluated ? Colors.white70 : Colors.white24, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 46),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active ? _accent : _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? _accent : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _scienceStrip() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _chip('2nd', () {
            appState.vibrate();
            setState(() => _secondMode = !_secondMode);
          }, active: _secondMode),
          _chip(_secondMode ? 'sin⁻¹' : 'sin', () => _append(_secondMode ? 'asin(' : 'sin(')),
          _chip(_secondMode ? 'cos⁻¹' : 'cos', () => _append(_secondMode ? 'acos(' : 'cos(')),
          _chip(_secondMode ? 'tan⁻¹' : 'tan', () => _append(_secondMode ? 'atan(' : 'tan(')),
          _chip('√', () => _append('sqrt(')),
          _chip('x²', () => _append('^2')),
          _chip('xʸ', () => _append('^')),
          _chip('log', () => _append('log(')),
          _chip('ln', () => _append('ln(')),
          _chip('π', () => _append('π')),
          _chip('e', () => _append('e')),
          _chip('(', () => _append('(')),
          _chip(')', () => _append(')')),
          _chip('%', () => _append('%')),
        ],
      ),
    );
  }

  Widget _controlsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Expanded(child: _keyButton('AC', onTap: _clearAll, bg: const Color(0xFF2A1830), fg: Colors.redAccent)),
          const SizedBox(width: 8),
          Expanded(child: _keyButton('⌫', onTap: _backspace, bg: _card, fg: Colors.white70)),
          const SizedBox(width: 8),
          Expanded(
            child: _keyButton(
              appState.isDeg ? 'DEG' : 'RAD',
              onTap: () {
                appState.vibrate();
                appState.setDeg(!appState.isDeg);
              },
              bg: _card,
              fg: _accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _keyButton('x', onTap: () => _append('x'), bg: _card, fg: Colors.white)),
        ],
      ),
    );
  }

  Widget _keyButton(String label, {required VoidCallback onTap, required Color bg, required Color fg, double fontSize = 16}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _digitGrid() {
    final rows = <List<_K>>[
      [_K('7', () => _append('7')), _K('8', () => _append('8')), _K('9', () => _append('9')), _K('÷', () => _append('÷'), op: true)],
      [_K('4', () => _append('4')), _K('5', () => _append('5')), _K('6', () => _append('6')), _K('×', () => _append('×'), op: true)],
      [_K('1', () => _append('1')), _K('2', () => _append('2')), _K('3', () => _append('3')), _K('−', () => _append('-'), op: true)],
      [_K('0', () => _append('0')), _K('.', () => _append('.')), _K('=', _evaluate, eq: true), _K('+', () => _append('+'), op: true)],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: Column(
        children: rows
            .map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: row
                        .map((k) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _keyButton(
                                  k.label,
                                  onTap: k.onTap,
                                  bg: k.eq ? _accent : (k.op ? _accent2.withOpacity(0.18) : _panel),
                                  fg: k.eq ? Colors.white : (k.op ? _accent2 : Colors.white),
                                  fontSize: 20,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _display(),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 8),
            _scienceStrip(),
            const SizedBox(height: 4),
            _controlsRow(),
            const Spacer(),
            _digitGrid(),
          ],
        ),
      ),
    );
  }
}

class _K {
  final String label;
  final VoidCallback onTap;
  final bool op;
  final bool eq;
  _K(this.label, this.onTap, {this.op = false, this.eq = false});
}
