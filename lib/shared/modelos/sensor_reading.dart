// Contrato compartido: una fila de `sensor_readings`.
// Responsables: los tres. Cualquier cambio requiere revisión de todos.

import '../../core/constantes/tipos_sensor.dart';

class SensorReading {
  const SensorReading({
    this.id,
    required this.tipo,
    this.x,
    this.y,
    this.z,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.recordedAt,
    required this.capturadoPor,
  });

  final int? id;
  final TipoSensor tipo;
  final double? x;
  final double? y;
  final double? z;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime recordedAt;
  final String capturadoPor;

  factory SensorReading.fromMap(Map<String, dynamic> map) => SensorReading(
        id: map['id'] as int?,
        tipo: TipoSensor.desdeBd(map['sensor_type'] as String),
        x: (map['x'] as num?)?.toDouble(),
        y: (map['y'] as num?)?.toDouble(),
        z: (map['z'] as num?)?.toDouble(),
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble(),
        recordedAt: DateTime.parse(map['recorded_at'] as String),
        capturadoPor: map['capturado_por'] as String? ?? '',
      );

  /// Mapa para INSERT. No incluye `id` (lo genera la base).
  Map<String, dynamic> toMap() => {
        'sensor_type': tipo.valorBd,
        'x': x,
        'y': y,
        'z': z,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        'capturado_por': capturadoPor,
      };
}
