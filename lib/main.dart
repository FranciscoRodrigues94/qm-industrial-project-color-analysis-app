import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';

void main() {
  runApp(const QSApp());
}

class QSApp extends StatelessWidget {
  const QSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QS Farbanalyse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF8FAFC),
      ),
      home: const DashboardPage(),
    );
  }
}