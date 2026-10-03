import 'package:flutter/material.dart';
import '../common/app_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with AppStateListenerMixin {
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _fmtTime(DateTime t) =>
      '${t.year}/${_twoDigits(t.month)}/${_twoDigits(t.day)}  ${_twoDigits(t.hour)}:${_twoDigits(t.minute)}';

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('پاک کردن تاریخچه'),
        content: const Text('همه‌ی محاسبات ذخیره‌شده حذف شوند؟'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('پاک کن'),
          ),
        ],
      ),
    );
    if (ok == true) {
      appState.vibrate();
      await appState.clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = appState.history;
    return Scaffold(
      backgroundColor: const Color(0xFF0D121E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131A2B),
        elevation: 0,
        title: const Text('تاریخچه'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'پاک کردن همه',
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('هنوز محاسبه‌ای ثبت نشده است', style: TextStyle(color: Colors.white38)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = items[i];
                return Dismissible(
                  key: ValueKey('${e.time.microsecondsSinceEpoch}_$i'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) => appState.removeHistoryAt(i),
                  child: GestureDetector(
                    onTap: () {
                      appState.vibrate();
                      Navigator.pop(context, e.expression);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17213A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              e.expression,
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '= ${e.result}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_fmtTime(e.time), style: const TextStyle(color: Colors.white24, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
