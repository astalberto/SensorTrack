// Cliente de Supabase y comprobación de conexión.
// Responsable: Josué

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

class SupabaseService {
  SupabaseService._();

  /// Inicializa Supabase si hay credenciales. Sin credenciales la app
  /// arranca igual y Home muestra "sin conexión".
  static Future<void> inicializar() async {
    if (!SupabaseConfig.estaConfigurado) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.clavePublica,
    );
  }

  static SupabaseClient get cliente => Supabase.instance.client;

  /// TODO(Josué): consulta ligera para saber si hay conexión con la base.
  static Future<bool> hayConexion() async => SupabaseConfig.estaConfigurado;
}
