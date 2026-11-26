// ReadingsRepository en memoria para pruebas de cualquier feature.
// Responsable: Josué

import 'dart:async';

import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/shared/datos/readings_repository.dart';
import 'package:sensor_track/shared/modelos/sensor_reading.dart';

class RepositorioEnMemoria implements ReadingsRepository {
  RepositorioEnMemoria([Iterable<SensorReading> iniciales = const []]) {
    for (final l in iniciales) {
      _agregar(l);
    }
  }

  final List<SensorReading> lecturas = [];

  /// Si no es null, todas las operaciones lanzan este error.
  AppException? error;

  /// Si no es null, las operaciones esperan a que se complete.
  Completer<void>? pausa;

  int llamadasGuardar = 0;
  int llamadasListar = 0;
  int _siguienteId = 1;

  Future<void> _antes() async {
    if (pausa case final p?) await p.future;
    if (error case final e?) throw e;
  }

  void _agregar(SensorReading l) {
    final id = l.id ?? _siguienteId;
    if (id >= _siguienteId) _siguienteId = id + 1;
    lecturas.add(
      SensorReading(
        id: id,
        tipo: l.tipo,
        x: l.x,
        y: l.y,
        z: l.z,
        latitude: l.latitude,
        longitude: l.longitude,
        accuracy: l.accuracy,
        recordedAt: l.recordedAt,
        capturadoPor: l.capturadoPor,
      ),
    );
  }

  @override
  Future<void> guardar(SensorReading lectura) async {
    llamadasGuardar++;
    await _antes();
    _agregar(lectura);
  }

  @override
  Future<List<SensorReading>> listar({
    TipoSensor? tipo,
    String? capturadoPor,
    int limite = 50,
    int desplazamiento = 0,
  }) async {
    llamadasListar++;
    await _antes();
    final filtradas =
        lecturas
            .where((l) => tipo == null || l.tipo == tipo)
            .where(
              (l) => capturadoPor == null || l.capturadoPor == capturadoPor,
            )
            .toList()
          ..sort((a, b) {
            final porFecha = b.recordedAt.compareTo(a.recordedAt);
            return porFecha != 0 ? porFecha : b.id!.compareTo(a.id!);
          });
    return filtradas.skip(desplazamiento).take(limite).toList();
  }

  @override
  Future<SensorReading?> obtenerPorId(int id) async {
    await _antes();
    for (final l in lecturas) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  Future<Map<TipoSensor, int>> contarPorTipo({String? capturadoPor}) async {
    await _antes();
    return {
      for (final t in TipoSensor.values)
        t: lecturas
            .where((l) => l.tipo == t)
            .where(
              (l) => capturadoPor == null || l.capturadoPor == capturadoPor,
            )
            .length,
    };
  }
}

/// Lectura de acelerómetro válida.
SensorReading acelerometro({
  int? id,
  double x = 0.1,
  double y = 9.8,
  double z = -0.2,
  DateTime? fecha,
  String capturadoPor = 'josue',
}) => SensorReading(
  id: id,
  tipo: TipoSensor.accelerometer,
  x: x,
  y: y,
  z: z,
  recordedAt: fecha ?? DateTime.utc(2026, 11, 25, 12),
  capturadoPor: capturadoPor,
);

/// Lectura de giroscopio válida.
SensorReading giroscopio({
  int? id,
  DateTime? fecha,
  String capturadoPor = 'alberto',
}) => SensorReading(
  id: id,
  tipo: TipoSensor.gyroscope,
  x: 0.01,
  y: -0.02,
  z: 0.5,
  recordedAt: fecha ?? DateTime.utc(2026, 11, 25, 12),
  capturadoPor: capturadoPor,
);

/// Lectura de GPS válida (Quito).
SensorReading gps({
  int? id,
  double latitude = -0.180653,
  double longitude = -78.467834,
  double accuracy = 8.5,
  DateTime? fecha,
  String capturadoPor = 'cody',
}) => SensorReading(
  id: id,
  tipo: TipoSensor.gps,
  latitude: latitude,
  longitude: longitude,
  accuracy: accuracy,
  recordedAt: fecha ?? DateTime.utc(2026, 11, 25, 12),
  capturadoPor: capturadoPor,
);
