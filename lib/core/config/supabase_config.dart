// Configuración de Supabase leída desde --dart-define.
// Responsable: Josué
//
// Ejecutar con:
//   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=... --dart-define=CAPTURADO_POR=<nombre>

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String clavePublica = String.fromEnvironment('SUPABASE_KEY');

  /// Integrante que hace la captura (campo `capturado_por`).
  static const String capturadoPor = String.fromEnvironment('CAPTURADO_POR');

  static bool get estaConfigurado => url.isNotEmpty && clavePublica.isNotEmpty;
}
