// Tema visual de la app.
// Responsable: Alberto

import 'package:flutter/material.dart';

class TemaApp {
  TemaApp._();

  static const _semilla = Colors.teal;

  static ThemeData get claro => _tema(Brightness.light);

  static ThemeData get oscuro => _tema(Brightness.dark);

  static ThemeData _tema(Brightness brillo) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _semilla, brightness: brillo),
    useMaterial3: true,
  );
}
