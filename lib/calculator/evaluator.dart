import '../bignum/big_math.dart';
import 'ast.dart';

class MathEvalException implements Exception {
  final String message;
  const MathEvalException(this.message);
  @override
  String toString() => message;
}

BigDec _applyFunc(String name, BigDec v, int precision, bool deg) {
  switch (name) {
    case 'sin':
      return sinValue(v, precision, deg);
    case 'cos':
      return cosValue(v, precision, deg);
    case 'tan':
      return tanValue(v, precision, deg);
    case 'asin':
      return asinDeg(v, precision, deg);
    case 'acos':
      return acosDeg(v, precision, deg);
    case 'atan':
      return atanDeg(v, precision, deg);
    case 'log':
      return log10Value(v, precision);
    case 'ln':
      return lnValue(v, precision);
    case 'sqrt':
      return v.sqrt(precision);
    default:
      throw MathEvalException('تابع ناشناخته: $name');
  }
}

BigDec _applyBin(String op, BigDec l, BigDec r, int precision) {
  switch (op) {
    case '+':
      return (l + r).rescaleTo(precision);
    case '-':
      return (l - r).rescaleTo(precision);
    case '*':
      return (l * r).rescaleTo(precision);
    case '/':
      return l.divide(r, precision);
    default:
      throw MathEvalException('عملگر ناشناخته: $op');
  }
}

BigDec _constValue(String name, int precision) {
  return name == 'pi' ? piValue(precision) : eValue(precision);
}

/// ارزیابی ساده (بدون ثبت مراحل)؛ برای جاهایی که فقط نتیجه لازم است.
BigDec evaluateNode(Node n, {BigDec? xValue, required int precision, required bool deg}) {
  final workPrec = precision + 10;
  if (n is NumNode) return n.value.rescaleTo(precision);
  if (n is ConstNode) return _constValue(n.name, precision);
  if (n is VarNode) {
    if (xValue == null) throw const MathEvalException('مقدار x مشخص نشده است');
    return xValue.rescaleTo(precision);
  }
  if (n is UnaryNeg) return -evaluateNode(n.n, xValue: xValue, precision: precision, deg: deg);
  if (n is PercentNode) {
    final v = evaluateNode(n.n, xValue: xValue, precision: workPrec, deg: deg);
    return v.divide(BigDec.fromInt(100), precision);
  }
  if (n is FuncCall) {
    final a = evaluateNode(n.arg, xValue: xValue, precision: workPrec, deg: deg);
    return _applyFunc(n.name, a, precision, deg);
  }
  if (n is PowNode) {
    final b = evaluateNode(n.base, xValue: xValue, precision: workPrec, deg: deg);
    final e = evaluateNode(n.exp, xValue: xValue, precision: workPrec, deg: deg);
    return powValue(b, e, precision);
  }
  if (n is BinOp) {
    final l = evaluateNode(n.l, xValue: xValue, precision: workPrec, deg: deg);
    final r = evaluateNode(n.r, xValue: xValue, precision: workPrec, deg: deg);
    return _applyBin(n.op, l, r, precision);
  }
  throw const MathEvalException('عبارت پشتیبانی نمی‌شود');
}

String _funcLabelFa(String name) {
  const map = {
    'sin': 'sin',
    'cos': 'cos',
    'tan': 'tan',
    'asin': 'sin⁻¹',
    'acos': 'cos⁻¹',
    'atan': 'tan⁻¹',
    'log': 'log',
    'ln': 'ln',
    'sqrt': '√',
  };
  return map[name] ?? name;
}

int _prec(String op) {
  switch (op) {
    case '+':
    case '-':
      return 1;
    case '*':
    case '/':
      return 2;
    default:
      return 0;
  }
}

/// -------------------- نمایش‌گر (Renderer) --------------------
class Renderer {
  final int displayDecimals;
  Renderer(this.displayDecimals);

  String render(Node n) => _r(n, 0, false);

  String _num(BigDec v) => v.toDisplayString(displayDecimals > 50 ? 50 : displayDecimals);

  String _r(Node n, int parentPrec, bool isRightOfNonAssoc) {
    if (n is NumNode) {
      final s = _num(n.value);
      if (n.value.sign < 0 && parentPrec > 0) return '($s)';
      return s;
    }
    if (n is VarNode) return 'x';
    if (n is ConstNode) return n.name == 'pi' ? 'π' : 'e';
    if (n is UnaryNeg) {
      final inner = _r(n.n, 3, false);
      final s = '-$inner';
      return parentPrec > 2 ? '($s)' : s;
    }
    if (n is PercentNode) {
      return '${_r(n.n, 5, false)}%';
    }
    if (n is FuncCall) {
      return '${_funcLabelFa(n.name)}(${_r(n.arg, 0, false)})';
    }
    if (n is PowNode) {
      final b = _r(n.base, 5, false);
      final e = _r(n.exp, 5, false);
      final s = '$b^$e';
      return parentPrec > 4 ? '($s)' : s;
    }
    if (n is BinOp) {
      final p = _prec(n.op);
      final ls = _r(n.l, p, false);
      final rs = _r(n.r, p, true);
      final sym = n.op == '*' ? '×' : (n.op == '/' ? '÷' : n.op);
      final s = '$ls $sym $rs';
      final needParens = p < parentPrec || (p == parentPrec && isRightOfNonAssoc && (n.op == '-' || n.op == '/'));
      return needParens ? '($s)' : s;
    }
    return '?';
  }
}

/// -------------------- گام‌به‌گام برای عبارت‌های عددی ساده --------------------
class StepEvaluation {
  final List<String> steps;
  final BigDec result;
  StepEvaluation(this.steps, this.result);
}

class _StepRunner {
  final int precision;
  final bool deg;
  final BigDec? xValue;
  late Node _root;
  final List<String> steps = [];
  late Renderer _renderer;

  _StepRunner({required this.precision, required this.deg, this.xValue}) {
    _renderer = Renderer(precision);
  }

  Node _replace(Node node, Node target, Node repl) {
    if (identical(node, target)) return repl;
    if (node is BinOp) return BinOp(node.op, _replace(node.l, target, repl), _replace(node.r, target, repl));
    if (node is UnaryNeg) return UnaryNeg(_replace(node.n, target, repl));
    if (node is PercentNode) return PercentNode(_replace(node.n, target, repl));
    if (node is FuncCall) return FuncCall(node.name, _replace(node.arg, target, repl));
    if (node is PowNode) return PowNode(_replace(node.base, target, repl), _replace(node.exp, target, repl));
    return node;
  }

  void _record(Node before, Node after) {
    _root = _replace(_root, before, after);
    final s = _renderer.render(_root);
    if (steps.isEmpty || steps.last != s) steps.add(s);
  }

  Node _reduce(Node n) {
    final workPrec = precision + 10;
    if (n is NumNode) return n;
    if (n is VarNode) {
      if (xValue == null) throw const MathEvalException('مقدار x مشخص نشده است');
      final v = NumNode(xValue!.rescaleTo(precision));
      return v;
    }
    if (n is ConstNode) {
      final v = NumNode(_constValue(n.name, workPrec));
      _record(n, v);
      return v;
    }
    if (n is UnaryNeg) {
      final inner = _reduce(n.n);
      if (inner is NumNode) {
        final v = NumNode(-inner.value);
        _record(UnaryNeg(inner), v);
        return v;
      }
      return UnaryNeg(inner);
    }
    if (n is PercentNode) {
      final inner = _reduce(n.n);
      if (inner is NumNode) {
        final v = NumNode(inner.value.divide(BigDec.fromInt(100), workPrec));
        _record(PercentNode(inner), v);
        return v;
      }
      return PercentNode(inner);
    }
    if (n is FuncCall) {
      final a = _reduce(n.arg);
      if (a is NumNode) {
        final v = NumNode(_applyFunc(n.name, a.value, workPrec, deg));
        _record(FuncCall(n.name, a), v);
        return v;
      }
      return FuncCall(n.name, a);
    }
    if (n is PowNode) {
      final b = _reduce(n.base);
      final e = _reduce(n.exp);
      if (b is NumNode && e is NumNode) {
        final v = NumNode(powValue(b.value, e.value, workPrec));
        _record(PowNode(b, e), v);
        return v;
      }
      return PowNode(b, e);
    }
    if (n is BinOp) {
      final l = _reduce(n.l);
      final r = _reduce(n.r);
      if (l is NumNode && r is NumNode) {
        final v = NumNode(_applyBin(n.op, l.value, r.value, workPrec));
        _record(BinOp(n.op, l, r), v);
        return v;
      }
      return BinOp(n.op, l, r);
    }
    throw const MathEvalException('عبارت پشتیبانی نمی‌شود');
  }

  StepEvaluation run(Node root) {
    _root = root;
    steps.add(_renderer.render(root));
    final reduced = _reduce(root);
    if (reduced is! NumNode) throw const MathEvalException('عبارت کامل محاسبه نشد');
    final finalVal = reduced.value.rescaleTo(precision);
    return StepEvaluation(steps, finalVal);
  }
}

StepEvaluation evaluateWithSteps(Node root, {required int precision, required bool deg, BigDec? xValue}) {
  return _StepRunner(precision: precision, deg: deg, xValue: xValue).run(root);
}

/// -------------------- حل معادله‌ی خطی/درجه‌دوم ساده --------------------
class PolyUnsupported implements Exception {
  final String message;
  const PolyUnsupported(this.message);
}

/// {0: a0, 1: a1, 2: a2}  یعنی a2*x^2 + a1*x + a0
Map<int, BigDec> _collectPoly(Node n, int precision) {
  if (n is NumNode) return {0: n.value};
  if (n is ConstNode) return {0: _constValue(n.name, precision)};
  if (n is VarNode) return {1: BigDec.one};
  if (n is UnaryNeg) {
    final m = _collectPoly(n.n, precision);
    return m.map((k, v) => MapEntry(k, -v));
  }
  if (n is PercentNode) {
    final m = _collectPoly(n.n, precision);
    return m.map((k, v) => MapEntry(k, v.divide(BigDec.fromInt(100), precision)));
  }
  if (n is BinOp) {
    if (n.op == '+' || n.op == '-') {
      final l = _collectPoly(n.l, precision);
      final r = _collectPoly(n.r, precision);
      final out = <int, BigDec>{...l};
      r.forEach((k, v) {
        final add = n.op == '-' ? -v : v;
        out[k] = (out[k] ?? BigDec.zero) + add;
      });
      return out;
    }
    if (n.op == '*') {
      final l = _collectPoly(n.l, precision);
      final r = _collectPoly(n.r, precision);
      final lDeg = l.keys.where((k) => l[k] != BigDec.zero).fold<int>(0, (a, b) => a > b ? a : b);
      final rDeg = r.keys.where((k) => r[k] != BigDec.zero).fold<int>(0, (a, b) => a > b ? a : b);
      if (lDeg + rDeg > 2) {
        throw const PolyUnsupported('این معادله از درجه‌ی دوم بالاتر است');
      }
      final out = <int, BigDec>{};
      l.forEach((lk, lv) {
        r.forEach((rk, rv) {
          final k = lk + rk;
          out[k] = (out[k] ?? BigDec.zero) + lv * rv;
        });
      });
      return out;
    }
    if (n.op == '/') {
      final r = _collectPoly(n.r, precision);
      final rDeg = r.keys.where((k) => r[k] != BigDec.zero).fold<int>(0, (a, b) => a > b ? a : b);
      if (rDeg > 0) {
        throw const PolyUnsupported('تقسیم بر عبارتی شامل x پشتیبانی نمی‌شود');
      }
      final divisor = r[0] ?? BigDec.zero;
      final l = _collectPoly(n.l, precision);
      return l.map((k, v) => MapEntry(k, v.divide(divisor, precision)));
    }
  }
  if (n is PowNode) {
    if (n.exp is NumNode && (n.exp as NumNode).value.isInteger()) {
      final e = (n.exp as NumNode).value.rescaleTo(0).unscaled.toInt();
      if (e < 0 || e > 2) throw const PolyUnsupported('توان بالاتر از ۲ پشتیبانی نمی‌شود');
      final baseMap = _collectPoly(n.base, precision);
      Map<int, BigDec> result = {0: BigDec.one};
      for (int i = 0; i < e; i++) {
        final newResult = <int, BigDec>{};
        result.forEach((rk, rv) {
          baseMap.forEach((bk, bv) {
            final k = rk + bk;
            if (k > 2) throw const PolyUnsupported('این معادله از درجه‌ی دوم بالاتر است');
            newResult[k] = (newResult[k] ?? BigDec.zero) + rv * bv;
          });
        });
        result = newResult;
      }
      return result;
    }
    throw const PolyUnsupported('توان غیرصحیح در معادله پشتیبانی نمی‌شود');
  }
  throw const PolyUnsupported('این نوع عبارت در معادله پشتیبانی نمی‌شود (فقط چندجمله‌ای درجه ۱ یا ۲)');
}

class EquationSolution {
  final List<String> steps;
  final List<BigDec> roots; // یک یا دو ریشه (یا خالی اگر بدون جواب حقیقی)
  final bool noRealSolution;
  EquationSolution(this.steps, this.roots, {this.noRealSolution = false});
}

String _fmt(BigDec v, int precision) => v.toDisplayString(precision);

EquationSolution solveEquation(Node left, Node right, {required int precision}) {
  final workPrec = precision + 10;
  final lMap = _collectPoly(left, workPrec);
  final rMap = _collectPoly(right, workPrec);
  final std = <int, BigDec>{0: BigDec.zero, 1: BigDec.zero, 2: BigDec.zero};
  lMap.forEach((k, v) => std[k] = (std[k] ?? BigDec.zero) + v);
  rMap.forEach((k, v) => std[k] = (std[k] ?? BigDec.zero) - v);

  final a2 = std[2]!;
  final a1 = std[1]!;
  final a0 = std[0]!;

  final steps = <String>[];

  String termsToString(BigDec c2, BigDec c1, BigDec c0, {String rhs = '0'}) {
    final parts = <String>[];
    if (!c2.isZero) parts.add('${_fmt(c2, precision)}x²');
    if (!c1.isZero) {
      final s = _fmt(c1, precision);
      parts.add(parts.isEmpty ? '${s}x' : (c1.sign < 0 ? '- ${_fmt(c1.abs(), precision)}x' : '+ ${s}x'));
    }
    if (!c0.isZero || parts.isEmpty) {
      final s = _fmt(c0, precision);
      parts.add(parts.isEmpty ? s : (c0.sign < 0 ? '- ${_fmt(c0.abs(), precision)}' : '+ $s'));
    }
    return '${parts.join(' ')} = $rhs';
  }

  steps.add(termsToString(a2, a1, a0));

  if (a2.isZero) {
    if (a1.isZero) {
      if (a0.isZero) {
        steps.add('این معادله برای هر x برقرار است (بی‌نهایت جواب)');
        return EquationSolution(steps, [], noRealSolution: true);
      } else {
        steps.add('این معادله جواب ندارد');
        return EquationSolution(steps, [], noRealSolution: true);
      }
    }
    // a1*x + a0 = 0  ->  a1*x = -a0 -> x = -a0/a1
    final negA0 = -a0;
    steps.add(termsToString(BigDec.zero, a1, BigDec.zero, rhs: _fmt(negA0, precision)));
    final x = negA0.divide(a1, precision);
    steps.add('x = ${_fmt(x, precision)}');
    return EquationSolution(steps, [x]);
  }

  // درجه‌ی دوم: a2 x² + a1 x + a0 = 0
  final disc = (a1 * a1 - BigDec.fromInt(4) * a2 * a0).rescaleTo(workPrec);
  steps.add('Δ = ${_fmt(a1, precision)}² - 4×${_fmt(a2, precision)}×${_fmt(a0, precision)} = ${_fmt(disc, precision)}');
  if (disc.sign < 0) {
    steps.add('چون Δ منفی است، این معادله جواب حقیقی ندارد');
    return EquationSolution(steps, [], noRealSolution: true);
  }
  final sqrtDisc = disc.sqrt(workPrec);
  final twoA = BigDec.two * a2;
  if (disc.isZero) {
    final x = (-a1).divide(twoA, precision);
    steps.add('x = -${_fmt(a1, precision)} / (2×${_fmt(a2, precision)}) = ${_fmt(x, precision)}');
    return EquationSolution(steps, [x]);
  }
  final x1 = (-a1 + sqrtDisc).divide(twoA, precision);
  final x2 = (-a1 - sqrtDisc).divide(twoA, precision);
  steps.add('x = (-${_fmt(a1, precision)} ± ${_fmt(sqrtDisc, precision)}) / (2×${_fmt(a2, precision)})');
  steps.add('x₁ = ${_fmt(x1, precision)}   ،   x₂ = ${_fmt(x2, precision)}');
  return EquationSolution(steps, [x1, x2]);
}
