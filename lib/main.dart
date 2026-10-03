import 'package:flutter/material.dart';
import 'calculator/calculator_screen.dart';
import 'common/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MohandesCalcApp());
}

class MohandesCalcApp extends StatefulWidget {
  const MohandesCalcApp({super.key});
  @override
  State<MohandesCalcApp> createState() => _MohandesCalcAppState();
}

class _MohandesCalcAppState extends State<MohandesCalcApp> {
  @override
  void initState() {
    super.initState();
    appState.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ماشین‌حساب مهندسی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D121E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3EA6FF),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: Color(0xFF3EA6FF)),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const CalculatorScreen(),
    );
  }
}
