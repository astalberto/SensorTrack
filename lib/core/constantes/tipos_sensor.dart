// Tipos de sensor admitidos en la columna `sensor_type`.
// Responsable: Alberto

enum TipoSensor {
  accelerometer('Acelerómetro', unidad: 'm/s²'),
  gyroscope('Giroscopio', unidad: 'rad/s'),
  gps('GPS');

  const TipoSensor(this.etiqueta, {this.unidad});

  /// Nombre en español para mostrar en pantalla.
  final String etiqueta;

  /// Unidad de los ejes X, Y, Z. Null para el GPS, que no tiene ejes.
  final String? unidad;

  /// Valor guardado en la base de datos.
  String get valorBd => name;

  static TipoSensor desdeBd(String valor) =>
      TipoSensor.values.firstWhere((t) => t.name == valor);
}
