// Error común de la app con mensaje en español para mostrar al usuario.
// Responsable: Alberto

enum CategoriaError { conexion, permiso, sensor, validacion }

class AppException implements Exception {
  const AppException(this.categoria, this.mensaje, {this.causa});

  final CategoriaError categoria;

  /// Mensaje en español listo para mostrar en pantalla.
  final String mensaje;

  /// Error original, para depuración.
  final Object? causa;

  @override
  String toString() => 'AppException(${categoria.name}): $mensaje';
}
