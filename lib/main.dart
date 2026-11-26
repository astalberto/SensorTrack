// Arranque de la app e inicialización de Supabase.
// Responsable: Alberto

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'shared/datos/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Si Supabase no se puede inicializar, la app arranca igual: Home muestra
  // "sin conexión" y el resto de pantallas informan el error al usarlas.
  try {
    await SupabaseService.inicializar();
  } catch (error) {
    debugPrint('No se pudo inicializar Supabase: $error');
  }
  runApp(const SensorTrackApp());
}
