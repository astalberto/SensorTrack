// Cliente de Supabase y comprobación de conexión.
// Responsable: Josué

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/errores/app_exception.dart';

class SupabaseService {
  SupabaseService._();

  /// Tabla compartida del equipo (migración 001).
  static const tablaLecturas = 'sensor_readings';

  static bool _inicializado = false;

  /// `true` si Supabase arrancó con las credenciales de `--dart-define`.
  static bool get estaInicializado => _inicializado;

  /// Inicializa Supabase si hay credenciales. Sin credenciales, o si la
  /// inicialización falla, la app arranca igual y Home muestra "sin conexión".
  /// Nunca lanza.
  static Future<void> inicializar() async {
    if (_inicializado || !SupabaseConfig.estaConfigurado) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.clavePublica,
      );
      _inicializado = true;
    } catch (e) {
      debugPrint('SupabaseService: no se pudo inicializar Supabase: $e');
    }
  }

  /// Cliente ya inicializado.
  ///
  /// Lanza AppException(conexion) si la app se ejecutó sin `SUPABASE_URL` y
  /// `SUPABASE_KEY`.
  static SupabaseClient get cliente {
    if (!_inicializado) {
      throw const AppException(
        CategoriaError.conexion,
        'Supabase no está configurado. Ejecuta la app con '
        '--dart-define-from-file=env/dev.json (ver README).',
      );
    }
    return Supabase.instance.client;
  }

  /// `true` si se puede leer la tabla compartida (hay internet, la clave es
  /// válida y la migración está aplicada). Nunca lanza.
  ///
  /// [cliente] solo se usa en pruebas.
  static Future<bool> hayConexion({
    SupabaseClient? cliente,
    Duration tiempoMaximo = const Duration(seconds: 5),
  }) async {
    if (cliente == null && !_inicializado) return false;
    try {
      await (cliente ?? Supabase.instance.client)
          .from(tablaLecturas)
          .select('id')
          .limit(1)
          .timeout(tiempoMaximo);
      return true;
    } catch (_) {
      return false;
    }
  }
}
