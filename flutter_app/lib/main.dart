import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pages/dashboard_page.dart';

void main() {
  runApp(const ProviderScope(child: EsportsOptimizerApp()));
}

class EsportsOptimizerApp extends StatelessWidget {
  const EsportsOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Esports Performance Optimizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ThemeData.dark().colorScheme.copyWith(primary: Colors.cyanAccent),
      ),
      home: const DashboardPage(),
    );
  }
}
