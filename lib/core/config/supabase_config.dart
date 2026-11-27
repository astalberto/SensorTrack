// Configuración de Supabase leída desde --dart-define.
// Responsable: Josué
//
// Ejecutar con el archivo local de credenciales (ignorado por Git):
//   flutter run --dart-define-from-file=env/dev.json
//
// Ver README y docs/supabase_configuracion.md.

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String clavePublica = String.fromEnvironment('SUPABASE_KEY');

  /// Integrante que hace la captura (campo `capturado_por`).
  /// Valores acordados: `alberto`, `josue`, `cody` (minúsculas, sin tildes).
  static const String capturadoPor = String.fromEnvironment('CAPTURADO_POR');

  static bool get estaConfigurado => url.isNotEmpty && clavePublica.isNotEmpty;
}
