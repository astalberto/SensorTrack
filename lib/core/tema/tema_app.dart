// Tema visual de la app.
// Responsable: Alberto

import 'package:flutter/material.dart';

class TemaApp {
  TemaApp._();

  static ThemeData get claro => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      );
}
