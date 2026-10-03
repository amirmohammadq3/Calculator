import '../bignum/big_math.dart';

/// واحد با ضریب تبدیل به واحد پایه‌ی دسته (value_in_base = value * factor)
class UnitDef {
  final String symbol;
  final String nameFa;
  final BigDec factor; // نسبت به واحد پایه
  const UnitDef(this.symbol, this.nameFa, this.factor);
  String get label => '$symbol ($nameFa)';
}

class UnitCategory {
  final String title;
  final String icon; // اموجی ساده برای نمایش سریع
  final List<UnitDef> units;
  final bool isTemperature;
  const UnitCategory(this.title, this.icon, this.units, {this.isTemperature = false});
}

BigDec _d(String s) => BigDec.parse(s);

final List<UnitCategory> kUnitCategories = [
  UnitCategory('طول', '📏', [
    UnitDef('mm', 'میلی‌متر', _d('0.001')),
    UnitDef('cm', 'سانتی‌متر', _d('0.01')),
    UnitDef('m', 'متر', _d('1')),
    UnitDef('km', 'کیلومتر', _d('1000')),
    UnitDef('in', 'اینچ', _d('0.0254')),
    UnitDef('ft', 'فوت', _d('0.3048')),
    UnitDef('yd', 'یارد', _d('0.9144')),
    UnitDef('mi', 'مایل', _d('1609.344')),
  ]),
  UnitCategory('مساحت', '◻️', [
    UnitDef('mm²', 'میلی‌متر مربع', _d('0.000001')),
    UnitDef('cm²', 'سانتی‌متر مربع', _d('0.0001')),
    UnitDef('m²', 'متر مربع', _d('1')),
    UnitDef('km²', 'کیلومتر مربع', _d('1000000')),
    UnitDef('ha', 'هکتار', _d('10000')),
    UnitDef('in²', 'اینچ مربع', _d('0.00064516')),
    UnitDef('ft²', 'فوت مربع', _d('0.09290304')),
    UnitDef('yd²', 'یارد مربع', _d('0.83612736')),
    UnitDef('mi²', 'مایل مربع', _d('2589988.110336')),
  ]),
  UnitCategory('حجم', '🧪', [
    UnitDef('mL', 'میلی‌لیتر', _d('0.001')),
    UnitDef('L', 'لیتر', _d('1')),
    UnitDef('cm³', 'سانتی‌متر مکعب', _d('0.001')),
    UnitDef('m³', 'متر مکعب', _d('1000')),
    UnitDef('gal', 'گالن (آمریکایی)', _d('3.785411784')),
    UnitDef('qt', 'کوارت', _d('0.946352946')),
    UnitDef('pt', 'پینت', _d('0.473176473')),
    UnitDef('cup', 'فنجان', _d('0.2365882365')),
    UnitDef('tbsp', 'قاشق غذاخوری', _d('0.0147867648')),
    UnitDef('tsp', 'قاشق چای‌خوری', _d('0.0049289216')),
  ]),
  UnitCategory('جرم / وزن', '⚖️', [
    UnitDef('mg', 'میلی‌گرم', _d('0.001')),
    UnitDef('g', 'گرم', _d('1')),
    UnitDef('kg', 'کیلوگرم', _d('1000')),
    UnitDef('t', 'تن', _d('1000000')),
    UnitDef('oz', 'اونس', _d('28.349523125')),
    UnitDef('lb', 'پوند', _d('453.59237')),
  ]),
  UnitCategory('زمان', '⏱️', [
    UnitDef('ms', 'میلی‌ثانیه', _d('0.001')),
    UnitDef('s', 'ثانیه', _d('1')),
    UnitDef('min', 'دقیقه', _d('60')),
    UnitDef('h', 'ساعت', _d('3600')),
    UnitDef('day', 'روز', _d('86400')),
    UnitDef('week', 'هفته', _d('604800')),
    UnitDef('month', 'ماه (میانگین)', _d('2629800')),
    UnitDef('year', 'سال', _d('31557600')),
  ]),
  UnitCategory('سرعت', '🚀', [
    UnitDef('m/s', 'متر بر ثانیه', _d('1')),
    UnitDef('km/h', 'کیلومتر بر ساعت', _d('0.277777777777778')),
    UnitDef('mph', 'مایل بر ساعت', _d('0.44704')),
    UnitDef('kn', 'گره دریایی', _d('0.514444444444444')),
  ]),
  UnitCategory('دما', '🌡️', [
    UnitDef('°C', 'سلسیوس', BigDec.one),
    UnitDef('°F', 'فارنهایت', BigDec.one),
    UnitDef('K', 'کلوین', BigDec.one),
  ], isTemperature: true),
  UnitCategory('فشار', '🧭', [
    UnitDef('Pa', 'پاسکال', _d('1')),
    UnitDef('kPa', 'کیلوپاسکال', _d('1000')),
    UnitDef('MPa', 'مگاپاسکال', _d('1000000')),
    UnitDef('bar', 'بار', _d('100000')),
    UnitDef('atm', 'اتمسفر', _d('101325')),
    UnitDef('mmHg', 'میلی‌متر جیوه', _d('133.322387415')),
    UnitDef('psi', 'پوند بر اینچ مربع', _d('6894.757293168')),
  ]),
  UnitCategory('انرژی', '🔋', [
    UnitDef('J', 'ژول', _d('1')),
    UnitDef('kJ', 'کیلوژول', _d('1000')),
    UnitDef('Wh', 'وات‌ساعت', _d('3600')),
    UnitDef('kWh', 'کیلووات‌ساعت', _d('3600000')),
    UnitDef('cal', 'کالری', _d('4.184')),
    UnitDef('kcal', 'کیلوکالری', _d('4184')),
  ]),
  UnitCategory('توان', '⚡', [
    UnitDef('W', 'وات', _d('1')),
    UnitDef('kW', 'کیلووات', _d('1000')),
    UnitDef('MW', 'مگاوات', _d('1000000')),
    UnitDef('hp', 'اسب‌بخار', _d('745.699871582')),
  ]),
  UnitCategory('نیرو', '🧲', [
    UnitDef('N', 'نیوتن', _d('1')),
    UnitDef('kN', 'کیلونیوتن', _d('1000')),
    UnitDef('lbf', 'پوند-نیرو', _d('4.4482216153')),
  ]),
  UnitCategory('فرکانس', '📶', [
    UnitDef('Hz', 'هرتز', _d('1')),
    UnitDef('kHz', 'کیلوهرتز', _d('1000')),
    UnitDef('MHz', 'مگاهرتز', _d('1000000')),
    UnitDef('GHz', 'گیگاهرتز', _d('1000000000')),
  ]),
  UnitCategory('داده / حافظه', '💾', [
    UnitDef('bit', 'بیت', _d('0.125')),
    UnitDef('byte', 'بایت', _d('1')),
    UnitDef('KB', 'کیلوبایت', _d('1024')),
    UnitDef('MB', 'مگابایت', _d('1048576')),
    UnitDef('GB', 'گیگابایت', _d('1073741824')),
    UnitDef('TB', 'ترابایت', _d('1099511627776')),
  ]),
  UnitCategory('زاویه', '📐', [
    UnitDef('deg', 'درجه', _d('1')),
    UnitDef('rad', 'رادیان', _d('57.2957795130823')),
  ]),
  UnitCategory('چگالی', '🧱', [
    UnitDef('kg/m³', 'کیلوگرم بر متر مکعب', _d('1')),
    UnitDef('g/cm³', 'گرم بر سانتی‌متر مکعب', _d('1000')),
  ]),
];

/// تبدیل‌های سریع روزمره؛ هرکدام به یک دسته و یک جفت واحد مشخص اشاره می‌کند
class QuickConversion {
  final String title;
  final String categoryTitle;
  final String fromSymbol;
  final String toSymbol;
  const QuickConversion(this.title, this.categoryTitle, this.fromSymbol, this.toSymbol);
}

const List<QuickConversion> kQuickConversions = [
  QuickConversion('قد و طول: سانتی‌متر ↔ اینچ', 'طول', 'cm', 'in'),
  QuickConversion('وزن: کیلوگرم ↔ پوند', 'جرم / وزن', 'kg', 'lb'),
  QuickConversion('مسافت: کیلومتر ↔ مایل', 'طول', 'km', 'mi'),
  QuickConversion('سرعت: km/h ↔ mph', 'سرعت', 'km/h', 'mph'),
  QuickConversion('دما: سلسیوس ↔ فارنهایت', 'دما', '°C', '°F'),
  QuickConversion('حجم: لیتر ↔ گالن', 'حجم', 'L', 'gal'),
  QuickConversion('مصرف برق: کیلووات ↔ وات', 'توان', 'kW', 'W'),
];

/// واحدهای پایه‌ی SI (برای نمایش مرجع، نه تبدیل مستقیم)
const List<List<String>> kSiBaseUnits = [
  ['m', 'متر — طول'],
  ['kg', 'کیلوگرم — جرم'],
  ['s', 'ثانیه — زمان'],
  ['A', 'آمپر — جریان الکتریکی'],
  ['K', 'کلوین — دما'],
  ['mol', 'مول — مقدار ماده'],
  ['cd', 'کندلا — شدت نور'],
];

const List<List<String>> kSiDerivedUnits = [
  ['Hz', 'هرتز — فرکانس'],
  ['N', 'نیوتن — نیرو'],
  ['Pa', 'پاسکال — فشار'],
  ['J', 'ژول — انرژی'],
  ['W', 'وات — توان'],
  ['C', 'کولن — بار الکتریکی'],
  ['V', 'ولت — ولتاژ'],
  ['Ω', 'اهم — مقاومت الکتریکی'],
  ['F', 'فاراد — ظرفیت خازنی'],
  ['Wb', 'وبر — شار مغناطیسی'],
  ['T', 'تسلا — چگالی شار مغناطیسی'],
  ['lm', 'لومن — شار نوری'],
  ['lx', 'لوکس — روشنایی'],
];

/// تبدیل دما (رابطه‌ی خطی ولی نه با ضریب ساده‌ی ضربی؛ جداگانه محاسبه می‌شود)
BigDec convertTemperature(BigDec value, String from, String to, int precision) {
  final workPrec = precision + 10;
  // همه را اول به سلسیوس می‌بریم
  BigDec celsius;
  switch (from) {
    case '°C':
      celsius = value;
      break;
    case '°F':
      celsius = (value - BigDec.fromInt(32)) * BigDec.fromInt(5).divide(BigDec.fromInt(9), workPrec);
      break;
    case 'K':
      celsius = value - BigDec.parse('273.15');
      break;
    default:
      throw const FormatException('واحد دما نامعتبر است');
  }
  switch (to) {
    case '°C':
      return celsius.rescaleTo(precision);
    case '°F':
      return (celsius * BigDec.fromInt(9).divide(BigDec.fromInt(5), workPrec) + BigDec.fromInt(32)).rescaleTo(precision);
    case 'K':
      return (celsius + BigDec.parse('273.15')).rescaleTo(precision);
    default:
      throw const FormatException('واحد دما نامعتبر است');
  }
}

BigDec convertUnit(BigDec value, UnitCategory cat, UnitDef from, UnitDef to, int precision) {
  if (cat.isTemperature) {
    return convertTemperature(value, from.symbol, to.symbol, precision);
  }
  final base = value * from.factor;
  return base.divide(to.factor, precision);
}
