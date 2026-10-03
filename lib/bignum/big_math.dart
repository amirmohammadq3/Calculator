/// موتور محاسبات با دقت دلخواه (تا ۱۰۰۰ رقم اعشار)، فقط با BigInt دارت.
/// هیچ پکیج ریاضی بیرونی استفاده نشده تا دقت کاملاً قابل کنترل و قابل اعتماد باشد.
library big_math;

import 'dart:math' as math;

/// یک عدد اعشاری با دقت دلخواه: مقدار = unscaled / 10^scale
class BigDec {
  final BigInt unscaled;
  final int scale; // همیشه >= 0

  const BigDec(this.unscaled, this.scale);

  static final BigDec zero = BigDec(BigInt.zero, 0);
  static final BigDec one = BigDec(BigInt.one, 0);
  static final BigDec two = BigDec(BigInt.two, 0);
  static final BigDec ten = BigDec(BigInt.from(10), 0);

  static final Map<int, BigInt> _p10cache = {};
  static BigInt p10(int n) {
    if (n <= 0) return BigInt.one;
    return _p10cache.putIfAbsent(n, () => BigInt.from(10).pow(n));
  }

  static BigDec fromInt(int v) => BigDec(BigInt.from(v), 0);
  static BigDec fromBigInt(BigInt v) => BigDec(v, 0);

  /// پارس کردن رشته‌ی اعشاری عادی (و در صورت نیاز با e/E نماد علمی)
  static BigDec parse(String input) {
    String s = input.trim();
    if (s.isEmpty) throw const FormatException('عدد خالی است');
    bool neg = false;
    if (s.startsWith('-')) {
      neg = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    int exp = 0;
    final eMatch = RegExp(r'[eE]([+-]?\d+)$').firstMatch(s);
    if (eMatch != null) {
      exp = int.parse(eMatch.group(1)!);
      s = s.substring(0, eMatch.start);
    }
    final dotIdx = s.indexOf('.');
    String digits;
    int scale;
    if (dotIdx < 0) {
      digits = s;
      scale = 0;
    } else {
      digits = s.substring(0, dotIdx) + s.substring(dotIdx + 1);
      scale = s.length - dotIdx - 1;
    }
    if (digits.isEmpty) digits = '0';
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      throw FormatException('عدد نامعتبر: $input');
    }
    BigInt unscaled = BigInt.parse(digits);
    if (neg) unscaled = -unscaled;
    scale -= exp;
    if (scale < 0) {
      unscaled = unscaled * p10(-scale);
      scale = 0;
    }
    return BigDec(unscaled, scale);
  }

  BigDec rescaleTo(int newScale) {
    if (newScale == scale) return this;
    if (newScale > scale) {
      return BigDec(unscaled * p10(newScale - scale), newScale);
    }
    final diff = scale - newScale;
    final divisor = p10(diff);
    BigInt q = unscaled ~/ divisor;
    final r = unscaled.remainder(divisor);
    if (r != BigInt.zero && (r.abs() * BigInt.two) >= divisor) {
      q += unscaled.isNegative ? -BigInt.one : BigInt.one;
    }
    return BigDec(q, newScale);
  }

  static List<BigInt> _alignedUnscaled(BigDec a, BigDec b) {
    final s = a.scale > b.scale ? a.scale : b.scale;
    final au = a.scale == s ? a.unscaled : a.unscaled * p10(s - a.scale);
    final bu = b.scale == s ? b.unscaled : b.unscaled * p10(s - b.scale);
    return [au, bu, BigInt.from(s)];
  }

  BigDec operator +(BigDec other) {
    final s = scale > other.scale ? scale : other.scale;
    final au = scale == s ? unscaled : unscaled * p10(s - scale);
    final bu = other.scale == s ? other.unscaled : other.unscaled * p10(s - other.scale);
    return BigDec(au + bu, s);
  }

  BigDec operator -(BigDec other) {
    final s = scale > other.scale ? scale : other.scale;
    final au = scale == s ? unscaled : unscaled * p10(s - scale);
    final bu = other.scale == s ? other.unscaled : other.unscaled * p10(s - other.scale);
    return BigDec(au - bu, s);
  }

  BigDec operator -() => BigDec(-unscaled, scale);

  BigDec operator *(BigDec other) => BigDec(unscaled * other.unscaled, scale + other.scale);

  /// تقسیم با دقت مشخص (تعداد رقم اعشار خروجی)
  BigDec divide(BigDec other, int precision) {
    if (other.unscaled == BigInt.zero) {
      throw const FormatException('تقسیم بر صفر امکان‌پذیر نیست');
    }
    final shift = other.scale - scale + precision;
    BigInt numerator = unscaled;
    BigInt denom = other.unscaled;
    if (shift >= 0) {
      numerator = numerator * p10(shift);
    } else {
      denom = denom * p10(-shift);
    }
    BigInt q = numerator ~/ denom;
    BigInt r = numerator.remainder(denom);
    if (r != BigInt.zero) {
      final sameSign = numerator.sign == denom.sign;
      if ((r.abs() * BigInt.two) >= denom.abs()) {
        q += sameSign ? BigInt.one : -BigInt.one;
      }
    }
    return BigDec(q, precision);
  }

  int get sign => unscaled.sign;
  BigDec abs() => unscaled.isNegative ? BigDec(-unscaled, scale) : this;

  int compareTo(BigDec other) {
    final al = _alignedUnscaled(this, other);
    return al[0].compareTo(al[1]);
  }

  bool operator <(BigDec o) => compareTo(o) < 0;
  bool operator >(BigDec o) => compareTo(o) > 0;
  bool operator <=(BigDec o) => compareTo(o) <= 0;
  bool operator >=(BigDec o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object other) => other is BigDec && compareTo(other) == 0;
  @override
  int get hashCode => rescaleTo(30).unscaled.hashCode;

  bool get isZero => unscaled == BigInt.zero;

  bool isInteger() => _fracIsZero();
  bool _fracIsZero() {
    if (scale == 0) return true;
    return unscaled.remainder(p10(scale)) == BigInt.zero;
  }

  /// بزرگی تقریبی (فقط برای حدس اولیه‌ی نیوتن، نه برای دقت نهایی)
  double approxMagnitudeLog10() {
    if (unscaled == BigInt.zero) return double.negativeInfinity;
    final digits = unscaled.abs().toString().length;
    return (digits - scale).toDouble();
  }

  BigDec powInt(int e, int precision) {
    final workPrec = precision + 10;
    if (e == 0) return one.rescaleTo(precision);
    final neg = e < 0;
    int n = e.abs();
    BigDec result = one;
    BigDec base = rescaleTo(workPrec);
    while (n > 0) {
      if (n & 1 == 1) {
        result = (result * base).rescaleTo(workPrec);
      }
      n >>= 1;
      if (n > 0) base = (base * base).rescaleTo(workPrec);
    }
    if (neg) {
      if (result.isZero) throw const FormatException('تقسیم بر صفر امکان‌پذیر نیست');
      result = one.divide(result, workPrec);
    }
    return result.rescaleTo(precision);
  }

  BigDec sqrt(int precision) {
    if (sign < 0) throw const FormatException('رادیکال عدد منفی تعریف نشده است');
    if (sign == 0) return BigDec(BigInt.zero, precision);
    final workPrec = precision + 12;
    final logv = approxMagnitudeLog10();
    int guessExp = (logv / 2).floor();
    BigDec guess = guessExp >= 0 ? BigDec(p10(guessExp), 0) : BigDec(BigInt.one, -guessExp);
    if (guess.isZero) guess = one;
    BigDec xN = guess.rescaleTo(workPrec);
    BigDec? prev;
    for (int i = 0; i < 80; i++) {
      final sx = divide(xN, workPrec);
      final next = (xN + sx).divide(two, workPrec);
      if (prev != null && next.rescaleTo(precision) == prev.rescaleTo(precision)) {
        xN = next;
        break;
      }
      prev = xN;
      xN = next;
    }
    return xN.rescaleTo(precision);
  }

  /// نمایش رشته‌ای با حداکثر [maxDecimals] رقم اعشار، با حذف صفرهای انتهایی
  String toDisplayString(int maxDecimals) {
    final r = rescaleTo(maxDecimals);
    final isNeg = r.unscaled.isNegative;
    String s = r.unscaled.abs().toString().padLeft(maxDecimals + 1, '0');
    String intPart = s.substring(0, s.length - maxDecimals);
    String fracPart = maxDecimals > 0 ? s.substring(s.length - maxDecimals) : '';
    if (maxDecimals > 0) {
      fracPart = fracPart.replaceFirst(RegExp(r'0+$'), '');
    }
    String out = intPart + (fracPart.isNotEmpty ? '.$fracPart' : '');
    final hasNonZero = RegExp(r'[1-9]').hasMatch(out);
    if (isNeg && hasNonZero) out = '-$out';
    return out;
  }

  @override
  String toString() => toDisplayString(scale);
}

// ==================== ثابت‌ها (π و e) با دقت دلخواه ====================

final Map<int, BigDec> _piCache = {};
final Map<int, BigDec> _ln2Cache = {};

/// سری آرک‌تانژانت برای |t| کوچک: t - t³/3 + t⁵/5 − ...
BigDec _atanSeriesSmall(BigDec t, int workPrec) {
  final t2 = (t * t).rescaleTo(workPrec);
  BigDec term = t;
  BigDec sum = t;
  int k = 1;
  bool neg = true;
  for (int i = 0; i < 100000; i++) {
    term = (term * t2).rescaleTo(workPrec);
    k += 2;
    final add = term.divide(BigDec.fromInt(k), workPrec);
    if (add.isZero) break;
    sum = neg ? sum - add : sum + add;
    neg = !neg;
  }
  return sum;
}

/// محاسبه‌ی عدد پی با فرمول ماشین: π/4 = 4·atan(1/5) − atan(1/239)
BigDec piValue(int precision) {
  return _piCache.putIfAbsent(precision, () {
    final workPrec = precision + 20;
    final t1 = BigDec.one.divide(BigDec.fromInt(5), workPrec);
    final t2 = BigDec.one.divide(BigDec.fromInt(239), workPrec);
    final a1 = _atanSeriesSmall(t1, workPrec);
    final a2 = _atanSeriesSmall(t2, workPrec);
    final pi4 = (a1 * BigDec.fromInt(4) - a2).rescaleTo(workPrec);
    final pi = (pi4 * BigDec.fromInt(4)).rescaleTo(precision);
    return pi;
  });
}

/// محاسبه‌ی عدد e با سری ۱/n!
BigDec eValue(int precision) {
  final workPrec = precision + 15;
  BigDec sum = BigDec.fromInt(2);
  BigDec term = BigDec.one;
  int n = 1;
  for (int i = 0; i < 100000; i++) {
    n++;
    term = term.divide(BigDec.fromInt(n), workPrec);
    if (term.isZero) break;
    sum = sum + term;
  }
  return sum.rescaleTo(precision);
}

BigDec ln2Value(int precision) {
  return _ln2Cache.putIfAbsent(precision, () {
    final workPrec = precision + 15;
    final t = BigDec.one.divide(BigDec.fromInt(3), workPrec);
    return (_atanhSeries(t, workPrec) * BigDec.two).rescaleTo(precision);
  });
}

BigDec _atanhSeries(BigDec t, int workPrec) {
  final t2 = (t * t).rescaleTo(workPrec);
  BigDec term = t;
  BigDec sum = t;
  int k = 1;
  for (int i = 0; i < 100000; i++) {
    term = (term * t2).rescaleTo(workPrec);
    k += 2;
    final add = term.divide(BigDec.fromInt(k), workPrec);
    if (add.isZero) break;
    sum = sum + add;
  }
  return sum;
}

/// لگاریتم طبیعی با کاهش بازه به نزدیک ۱ (بین ۰.۵ و ۲) و استفاده از ln2
BigDec lnValue(BigDec x, int precision) {
  if (x.sign <= 0) {
    throw const FormatException('لگاریتم عدد صفر یا منفی تعریف نشده است');
  }
  final workPrec = precision + 18;
  BigDec v = x.rescaleTo(workPrec);
  int k = 0;
  final two = BigDec.two;
  final half = BigDec.one.divide(two, workPrec);
  for (int i = 0; i < 100000 && v.compareTo(two) >= 0; i++) {
    v = v.divide(two, workPrec);
    k++;
  }
  for (int i = 0; i < 100000 && v.compareTo(half) < 0; i++) {
    v = (v * two).rescaleTo(workPrec);
    k--;
  }
  final t = (v - BigDec.one).divide(v + BigDec.one, workPrec);
  final lnv = _atanhSeries(t, workPrec);
  final result = lnv + ln2Value(workPrec).rescaleTo(workPrec) * BigDec.fromInt(k);
  return result.rescaleTo(precision);
}

/// لگاریتم ۱۰ (log)
BigDec log10Value(BigDec x, int precision) {
  final workPrec = precision + 15;
  final ln10 = lnValue(BigDec.ten, workPrec);
  return lnValue(x, workPrec).divide(ln10, precision);
}

/// نمای نمایی e^x با کاهش بازه (تقسیم بر ۲ به دفعات و بعد به توان رساندن)
BigDec expValue(BigDec x, int precision) {
  final workPrec = precision + 15;
  BigDec v = x.rescaleTo(workPrec);
  int k = 0;
  BigDec av = v.abs();
  for (int i = 0; i < 100000 && av.compareTo(BigDec.one) >= 0; i++) {
    av = av.divide(BigDec.two, workPrec);
    k++;
  }
  BigDec reduced = v;
  for (int i = 0; i < k; i++) {
    reduced = reduced.divide(BigDec.two, workPrec);
  }
  BigDec sum = BigDec.one;
  BigDec term = BigDec.one;
  int n = 0;
  for (int i = 0; i < 100000; i++) {
    n++;
    term = (term * reduced).divide(BigDec.fromInt(n), workPrec);
    if (term.isZero) break;
    sum = sum + term;
  }
  for (int i = 0; i < k; i++) {
    sum = (sum * sum).rescaleTo(workPrec);
  }
  return sum.rescaleTo(precision);
}

/// x به توان y (برای توان صحیح دقیق، برای غیرصحیح از exp(y·ln x) استفاده می‌شود)
BigDec powValue(BigDec base, BigDec exp, int precision) {
  final workPrec = precision + 15;
  if (exp._fracIsZero()) {
    final e = exp.rescaleTo(0).unscaled;
    if (e.bitLength < 31) {
      return base.powInt(e.toInt(), precision);
    }
  }
  if (base.sign < 0) {
    throw const FormatException('توان غیرصحیح برای پایه‌ی منفی پشتیبانی نمی‌شود');
  }
  if (base.isZero) return BigDec.zero.rescaleTo(precision);
  final lnBase = lnValue(base, workPrec);
  final e = (exp * lnBase).rescaleTo(workPrec);
  return expValue(e, precision);
}

/// آرک‌تانژانت عمومی برای هر x (با کاهش بازه‌ی نصف‌کردن زاویه)
BigDec atanValue(BigDec x, int precision) {
  final workPrec = precision + 15;
  if (x.isZero) return BigDec.zero.rescaleTo(precision);
  final neg = x.sign < 0;
  BigDec ax = x.abs().rescaleTo(workPrec);
  BigDec result;
  if (ax.compareTo(BigDec.one) > 0) {
    final inv = BigDec.one.divide(ax, workPrec);
    final halfPi = piValue(workPrec).divide(BigDec.two, workPrec);
    result = halfPi - _atanLE1(inv, workPrec);
  } else {
    result = _atanLE1(ax, workPrec);
  }
  result = result.rescaleTo(precision);
  return neg ? -result : result;
}

BigDec _atanLE1(BigDec v, int workPrec) {
  final threshold = BigDec.parse('0.15').rescaleTo(workPrec);
  int reductions = 0;
  BigDec cur = v;
  for (int i = 0; i < 200 && cur.compareTo(threshold) > 0; i++) {
    final v2 = (cur * cur).rescaleTo(workPrec);
    final s = (BigDec.one + v2).sqrt(workPrec);
    cur = cur.divide(BigDec.one + s, workPrec);
    reductions++;
  }
  BigDec r = _atanSeriesSmall(cur, workPrec);
  for (int i = 0; i < reductions; i++) {
    r = (r * BigDec.two).rescaleTo(workPrec);
  }
  return r;
}

BigDec asinValue(BigDec x, int precision) {
  if (x.abs() > BigDec.one) {
    throw const FormatException('آرک‌سینوس فقط برای بازه‌ی [-1,1] تعریف شده است');
  }
  final workPrec = precision + 15;
  if (x.abs() == BigDec.one) {
    final halfPi = piValue(precision).divide(BigDec.two, precision);
    return x.sign > 0 ? halfPi : -halfPi;
  }
  final x2 = (x * x).rescaleTo(workPrec);
  final denom = (BigDec.one - x2).sqrt(workPrec);
  final ratio = x.divide(denom, workPrec);
  return atanValue(ratio, precision);
}

BigDec acosValue(BigDec x, int precision) {
  final halfPi = piValue(precision + 5).divide(BigDec.two, precision + 5);
  return (halfPi - asinValue(x, precision + 5)).rescaleTo(precision);
}

/// کاهش زاویه به بازه‌ی تقریبی بین منفی پی تا پی
BigDec _reduceAngle(BigDec xr, int workPrec) {
  final twoPi = (piValue(workPrec) * BigDec.fromInt(2)).rescaleTo(workPrec);
  final kApprox = xr.divide(twoPi, 0).unscaled;
  final reduced = xr - twoPi * BigDec.fromBigInt(kApprox);
  return reduced.rescaleTo(workPrec);
}

BigDec _toRadians(BigDec x, int precision, bool deg) {
  if (!deg) return x;
  final workPrec = precision + 15;
  return (x * piValue(workPrec)).divide(BigDec.fromInt(180), workPrec);
}

BigDec _fromRadians(BigDec rad, int precision, bool deg) {
  if (!deg) return rad;
  final workPrec = precision + 15;
  return (rad * BigDec.fromInt(180)).divide(piValue(workPrec), precision);
}

BigDec _sinSeriesReduced(BigDec x, int workPrec) {
  final x2 = (x * x).rescaleTo(workPrec);
  BigDec term = x;
  BigDec sum = x;
  int k = 1;
  bool neg = true;
  for (int i = 0; i < 100000; i++) {
    term = (term * x2).rescaleTo(workPrec);
    k += 2;
    final add = term.divide(BigDec.fromInt(k * (k - 1)), workPrec);
    if (add.isZero) break;
    sum = neg ? sum - add : sum + add;
    neg = !neg;
  }
  return sum;
}

BigDec _cosSeriesReduced(BigDec x, int workPrec) {
  final x2 = (x * x).rescaleTo(workPrec);
  BigDec term = BigDec.one;
  BigDec sum = BigDec.one;
  int k = 0;
  bool neg = true;
  for (int i = 0; i < 100000; i++) {
    term = (term * x2).rescaleTo(workPrec);
    k += 2;
    final add = term.divide(BigDec.fromInt(k * (k - 1)), workPrec);
    if (add.isZero) break;
    sum = neg ? sum - add : sum + add;
    neg = !neg;
  }
  return sum;
}

BigDec sinValue(BigDec x, int precision, bool deg) {
  final workPrec = precision + 18;
  final rad = _toRadians(x, workPrec, deg);
  final reduced = _reduceAngle(rad, workPrec);
  return _sinSeriesReduced(reduced, workPrec).rescaleTo(precision);
}

BigDec cosValue(BigDec x, int precision, bool deg) {
  final workPrec = precision + 18;
  final rad = _toRadians(x, workPrec, deg);
  final reduced = _reduceAngle(rad, workPrec);
  return _cosSeriesReduced(reduced, workPrec).rescaleTo(precision);
}

BigDec tanValue(BigDec x, int precision, bool deg) {
  final workPrec = precision + 18;
  final rad = _toRadians(x, workPrec, deg);
  final reduced = _reduceAngle(rad, workPrec);
  final s = _sinSeriesReduced(reduced, workPrec);
  final c = _cosSeriesReduced(reduced, workPrec);
  if (c.isZero) throw const FormatException('در این زاویه، تانژانت تعریف نشده است');
  return s.divide(c, precision);
}

BigDec asinDeg(BigDec x, int precision, bool deg) => _fromRadians(asinValue(x, precision + 10), precision, deg);
BigDec acosDeg(BigDec x, int precision, bool deg) => _fromRadians(acosValue(x, precision + 10), precision, deg);
BigDec atanDeg(BigDec x, int precision, bool deg) => _fromRadians(atanValue(x, precision + 10), precision, deg);

/// برای حدس سریع و نمایش دکمه‌های کمکی (نه برای محاسبه‌ی نهایی)
double quickDouble(BigDec v) {
  try {
    return double.parse(v.toDisplayString(math.min(v.scale, 15)));
  } catch (_) {
    return 0;
  }
}
