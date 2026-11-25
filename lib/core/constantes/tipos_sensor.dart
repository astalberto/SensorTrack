// Tipos de sensor admitidos en la columna `sensor_type`.
// Responsable: Alberto

enum TipoSensor {
  accelerometer,
  gyroscope,
  gps;

  /// Valor guardado en la base de datos.
  String get valorBd => name;

  static TipoSensor desdeBd(String valor) =>
      TipoSensor.values.firstWhere((t) => t.name == valor);
}
