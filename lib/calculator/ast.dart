import '../bignum/big_math.dart';

/// -------------------- درخت نحوی (AST) --------------------
abstract class Node {
  const Node();
}

class NumNode extends Node {
  final BigDec value;
  const NumNode(this.value);
}

class VarNode extends Node {
  const VarNode();
}

class ConstNode extends Node {
  final String name; // 'pi' | 'e'
  const ConstNode(this.name);
}

class BinOp extends Node {
  final String op; // + - * / %
  final Node l, r;
  const BinOp(this.op, this.l, this.r);
}

class UnaryNeg extends Node {
  final Node n;
  const UnaryNeg(this.n);
}

class PowNode extends Node {
  final Node base, exp;
  const PowNode(this.base, this.exp);
}

class FuncCall extends Node {
  final String name; // sin cos tan asin acos atan log ln sqrt
  final Node arg;
  const FuncCall(this.name, this.arg);
}

/// n% یعنی n/100 (پسوندی، مثل اغلب ماشین‌حساب‌ها)
class PercentNode extends Node {
  final Node n;
  const PercentNode(this.n);
}

const kFuncNames = ['asin', 'acos', 'atan', 'sin', 'cos', 'tan', 'log', 'ln', 'sqrt'];

/// -------------------- توکِن‌ساز --------------------
class Token {
  final String type; // num, ident, func, op, lparen, rparen, eq
  final String text;
  Token(this.type, this.text);
  @override
  String toString() => '$type:$text';
}

class ParseException implements Exception {
  final String message;
  const ParseException(this.message);
  @override
  String toString() => message;
}

List<Token> tokenize(String raw) {
  String s = raw
      .replaceAll('×', '*')
      .replaceAll('٭', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll('–', '-')
      .replaceAll('⁄', '/')
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .replaceAll('٫', '.');
  // ارقام فارسی/عربی به لاتین
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (int i = 0; i < 10; i++) {
    s = s.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
  }
  s = s.replaceAll('π', 'pi');

  final tokens = <Token>[];
  int i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '(') {
      tokens.add(Token('lparen', c));
      i++;
    } else if (c == ')') {
      tokens.add(Token('rparen', c));
      i++;
    } else if ('+-*/%^'.contains(c)) {
      tokens.add(Token('op', c));
      i++;
    } else if (c == '=') {
      tokens.add(Token('eq', c));
      i++;
    } else if (RegExp(r'[0-9.]').hasMatch(c)) {
      int j = i;
      bool dotSeen = false;
      while (j < s.length && (RegExp(r'[0-9]').hasMatch(s[j]) || (s[j] == '.' && !dotSeen))) {
        if (s[j] == '.') dotSeen = true;
        j++;
      }
      tokens.add(Token('num', s.substring(i, j)));
      i = j;
    } else if (RegExp(r'[a-zA-Z]').hasMatch(c)) {
      // تطبیق طولانی‌ترین نام تابع یا ثابت شناخته‌شده
      String? matchedFunc;
      for (final f in kFuncNames) {
        if (s.startsWith(f, i)) {
          if (matchedFunc == null || f.length > matchedFunc.length) matchedFunc = f;
        }
      }
      if (matchedFunc != null) {
        tokens.add(Token('func', matchedFunc));
        i += matchedFunc.length;
      } else if (s.startsWith('pi', i)) {
        tokens.add(Token('const', 'pi'));
        i += 2;
      } else if (c == 'e') {
        tokens.add(Token('const', 'e'));
        i++;
      } else if (c == 'x') {
        tokens.add(Token('var', 'x'));
        i++;
      } else {
        throw ParseException('نماد ناشناخته: «$c»');
      }
    } else {
      throw ParseException('نماد ناشناخته: «$c»');
    }
  }

  // درج ضرب ضمنی: NUM/VAR/CONST/RPAREN دنبال‌شده با VAR/CONST/FUNC/LPAREN/NUM
  final out = <Token>[];
  bool isValueEnd(Token t) => t.type == 'num' || t.type == 'var' || t.type == 'const' || t.type == 'rparen';
  bool isValueStart(Token t) => t.type == 'num' || t.type == 'var' || t.type == 'const' || t.type == 'func' || t.type == 'lparen';
  for (int k = 0; k < tokens.length; k++) {
    out.add(tokens[k]);
    if (k + 1 < tokens.length && isValueEnd(tokens[k]) && isValueStart(tokens[k + 1])) {
      out.add(Token('op', '*'));
    }
  }
  return out;
}

/// -------------------- تجزیه‌گر بازگشتی --------------------
class Parser {
  final List<Token> tokens;
  int pos = 0;
  Parser(this.tokens);

  Token? get _cur => pos < tokens.length ? tokens[pos] : null;

  Node parseExpression() {
    final n = _parseAddSub();
    if (pos != tokens.length) {
      throw ParseException('عبارت نامعتبر در موقعیت $pos');
    }
    return n;
  }

  Node _parseAddSub() {
    Node n = _parseMulDiv();
    while (_cur != null && _cur!.type == 'op' && (_cur!.text == '+' || _cur!.text == '-')) {
      final op = tokens[pos++].text;
      final r = _parseMulDiv();
      n = BinOp(op, n, r);
    }
    return n;
  }

  Node _parseMulDiv() {
    Node n = _parseUnary();
    while (_cur != null && _cur!.type == 'op' && (_cur!.text == '*' || _cur!.text == '/')) {
      final op = tokens[pos++].text;
      final r = _parseUnary();
      n = BinOp(op, n, r);
    }
    return n;
  }

  Node _parseUnary() {
    if (_cur != null && _cur!.type == 'op' && _cur!.text == '-') {
      pos++;
      return UnaryNeg(_parseUnary());
    }
    if (_cur != null && _cur!.type == 'op' && _cur!.text == '+') {
      pos++;
      return _parseUnary();
    }
    return _parsePercent();
  }

  /// n% یعنی n/100؛ پسوندی و قابل تکرار (مثلاً n%% نادر ولی بی‌خطر است)
  Node _parsePercent() {
    Node n = _parsePow();
    while (_cur != null && _cur!.type == 'op' && _cur!.text == '%') {
      pos++;
      n = PercentNode(n);
    }
    return n;
  }

  Node _parsePow() {
    final base = _parsePrimary();
    if (_cur != null && _cur!.type == 'op' && _cur!.text == '^') {
      pos++;
      final exp = _parseUnary(); // راست‌انجمنی و اجازه‌ی توان منفی
      return PowNode(base, exp);
    }
    return base;
  }

  Node _parsePrimary() {
    final t = _cur;
    if (t == null) throw const ParseException('عبارت ناقص است');
    if (t.type == 'num') {
      pos++;
      return NumNode(BigDec.parse(t.text));
    }
    if (t.type == 'var') {
      pos++;
      return const VarNode();
    }
    if (t.type == 'const') {
      pos++;
      return ConstNode(t.text);
    }
    if (t.type == 'lparen') {
      pos++;
      final n = _parseAddSub();
      if (_cur == null || _cur!.type != 'rparen') {
        throw const ParseException('پرانتز بسته نشده است');
      }
      pos++;
      return n;
    }
    if (t.type == 'func') {
      pos++;
      if (_cur == null || _cur!.type != 'lparen') {
        throw ParseException('بعد از «${t.text}» باید پرانتز باز شود');
      }
      pos++;
      final arg = _parseAddSub();
      if (_cur == null || _cur!.type != 'rparen') {
        throw const ParseException('پرانتز بسته نشده است');
      }
      pos++;
      return FuncCall(t.text, arg);
    }
    throw ParseException('عبارت نامعتبر نزدیک «${t.text}»');
  }
}

/// می‌تواند شامل یک «=» باشد؛ در آن صورت لیست دو عضوی [چپ، راست] برمی‌گرداند
class ParsedInput {
  final Node? left;
  final Node? right; // فقط وقتی معادله باشد
  final bool isEquation;
  final bool hasVar;
  ParsedInput({required this.left, required this.right, required this.isEquation, required this.hasVar});
}

bool _containsVar(Node n) {
  if (n is VarNode) return true;
  if (n is BinOp) return _containsVar(n.l) || _containsVar(n.r);
  if (n is UnaryNeg) return _containsVar(n.n);
  if (n is PowNode) return _containsVar(n.base) || _containsVar(n.exp);
  if (n is FuncCall) return _containsVar(n.arg);
  if (n is PercentNode) return _containsVar(n.n);
  return false;
}

ParsedInput parseInput(String raw) {
  final eqCount = '='.allMatches(raw).length;
  if (eqCount > 1) {
    throw const ParseException('فقط یک علامت «=» مجاز است');
  }
  if (eqCount == 1) {
    final idx = raw.indexOf('=');
    final leftStr = raw.substring(0, idx);
    final rightStr = raw.substring(idx + 1);
    if (leftStr.trim().isEmpty || rightStr.trim().isEmpty) {
      throw const ParseException('دو طرف معادله باید عبارت داشته باشند');
    }
    final l = Parser(tokenize(leftStr)).parseExpression();
    final r = Parser(tokenize(rightStr)).parseExpression();
    return ParsedInput(left: l, right: r, isEquation: true, hasVar: _containsVar(l) || _containsVar(r));
  }
  final n = Parser(tokenize(raw)).parseExpression();
  return ParsedInput(left: n, right: null, isEquation: false, hasVar: _containsVar(n));
}
