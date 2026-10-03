import 'package:flutter/material.dart';
import '../bignum/big_math.dart';
import '../common/app_state.dart';
import 'units_data.dart';

const _accent = Color(0xFF3EA6FF);
const _bg = Color(0xFF0D121E);
const _card = Color(0xFF17213A);

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});
  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  UnitCategory? _selected;
  late UnitDef _from;
  late UnitDef _to;
  final TextEditingController _inputCtrl = TextEditingController(text: '1');
  String _output = '';

  void _openCategory(UnitCategory cat, {String? fromSymbol, String? toSymbol}) {
    setState(() {
      _selected = cat;
      _from = cat.units.firstWhere((u) => u.symbol == fromSymbol, orElse: () => cat.units[0]);
      _to = cat.units.firstWhere((u) => u.symbol == toSymbol, orElse: () => cat.units.length > 1 ? cat.units[1] : cat.units[0]);
      _inputCtrl.text = '1';
    });
    _recalc();
  }

  void _recalc() {
    if (_selected == null) return;
    try {
      final v = _inputCtrl.text.trim().isEmpty ? BigDec.zero : BigDec.parse(_inputCtrl.text.trim());
      final r = convertUnit(v, _selected!, _from, _to, 12);
      setState(() => _output = r.toDisplayString(12));
    } catch (_) {
      setState(() => _output = '—');
    }
  }

  void _swap() {
    appState.vibrate();
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
    });
    _recalc();
  }

  void _showSiReference() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(18),
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                const Text('واحدهای پایه‌ی SI', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...kSiBaseUnits.map((u) => _siRow(u[0], u[1])),
                const SizedBox(height: 18),
                const Text('واحدهای مشتق رایج', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text(
                  'این واحدها کمیت‌های متفاوتی هستند و تبدیل مستقیم بین آن‌ها معنا ندارد؛ فقط برای مرور آورده شده‌اند.',
                  style: TextStyle(color: Colors.white38, fontSize: 11.5, height: 1.7),
                ),
                const SizedBox(height: 8),
                ...kSiDerivedUnits.map((u) => _siRow(u[0], u[1])),
              ],
            );
          },
        );
      },
    );
  }

  Widget _siRow(String symbol, String desc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 54,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131A2B),
        elevation: 0,
        leading: _selected == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => setState(() => _selected = null),
              ),
        title: Text(_selected?.title ?? 'تبدیل واحد'),
        actions: [
          IconButton(
            tooltip: 'واحدهای SI',
            onPressed: _showSiReference,
            icon: const Icon(Icons.science_outlined),
          ),
        ],
      ),
      body: _selected == null ? _buildHub() : _buildConverter(),
    );
  }

  Widget _buildHub() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('تبدیل‌های سریع روزمره', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...kQuickConversions.map((q) {
          final cat = kUnitCategories.firstWhere((c) => c.title == q.categoryTitle);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                appState.vibrate();
                _openCategory(cat, fromSymbol: q.fromSymbol, toSymbol: q.toSymbol);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: _accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(q.title, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    const Icon(Icons.chevron_left, color: Colors.white38),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 22),
        const Text('همه‌ی دسته‌ها', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kUnitCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, i) {
            final cat = kUnitCategories[i];
            return GestureDetector(
              onTap: () {
                appState.vibrate();
                _openCategory(cat);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.icon, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 8),
                    Text(cat.title, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _unitPicker({required bool isFrom}) {
    final cat = _selected!;
    final value = isFrom ? _from : _to;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UnitDef>(
          value: value,
          isExpanded: true,
          dropdownColor: _card,
          iconEnabledColor: Colors.white54,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          items: cat.units
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Directionality(textDirection: TextDirection.ltr, child: Text(u.label, overflow: TextOverflow.ellipsis)),
                  ))
              .toList(),
          onChanged: (u) {
            if (u == null) return;
            setState(() {
              if (isFrom) {
                _from = u;
              } else {
                _to = u;
              }
            });
            _recalc();
          },
        ),
      ),
    );
  }

  Widget _buildConverter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('مقدار', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: TextField(
              controller: _inputCtrl,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16)),
              onChanged: (_) => _recalc(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _unitPicker(isFrom: true)),
              IconButton(
                onPressed: _swap,
                icon: const Icon(Icons.swap_horiz, color: _accent),
              ),
              Expanded(child: _unitPicker(isFrom: false)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1C2A4A), Color(0xFF17213A)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _accent.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                _output,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
