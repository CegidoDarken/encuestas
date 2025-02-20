import 'package:encuestas/screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encuesta por Secciones',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      );
  }
}
