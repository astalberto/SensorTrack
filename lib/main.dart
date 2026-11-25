// Arranque de la app e inicialización de Supabase.
// Responsable: Alberto

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'shared/datos/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  runApp(const SensorTrackApp());
}
