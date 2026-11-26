// Repositorio en memoria que imita el contrato de ReadingsRepository, para
// probar estadísticas sin Supabase.
// Responsable: Cody

import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/shared/datos/readings_repository.dart';
import 'package:sensor_track/shared/modelos/sensor_reading.dart';

class RepositorioFalso implements ReadingsRepository {
  RepositorioFalso(this.lecturas, {this.fallar = false});

  final List<SensorReading> lecturas;

  /// Si es true, las consultas lanzan AppException(conexion).
  final bool fallar;

  void _comprobar() {
    if (fallar) {
      throw const AppException(CategoriaError.conexion, 'Sin conexión.');
    }
  }

  @override
  Future<void> guardar(SensorReading lectura) async {
    _comprobar();
    lecturas.add(lectura);
  }

  @override
  Future<List<SensorReading>> listar({
    TipoSensor? tipo,
    String? capturadoPor,
    int limite = 50,
    int desplazamiento = 0,
  }) async {
    _comprobar();
    final filtradas =
        lecturas.where((l) => tipo == null || l.tipo == tipo).toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return filtradas.skip(desplazamiento).take(limite).toList();
  }

  @override
  Future<SensorReading?> obtenerPorId(int id) async {
    _comprobar();
    return lecturas.where((l) => l.id == id).firstOrNull;
  }

  @override
  Future<Map<TipoSensor, int>> contarPorTipo({String? capturadoPor}) async {
    _comprobar();
    final conteo = <TipoSensor, int>{};
    for (final l in lecturas) {
      conteo[l.tipo] = (conteo[l.tipo] ?? 0) + 1;
    }
    return conteo;
  }
}
