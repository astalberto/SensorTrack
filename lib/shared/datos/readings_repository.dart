// Interfaz del repositorio de lecturas. Las features dependen de esta
// interfaz, no de Supabase directamente.
// Responsable: Josué

import '../../core/constantes/tipos_sensor.dart';
import '../modelos/sensor_reading.dart';

abstract class ReadingsRepository {
  /// Inserta una lectura. Lanza AppException(conexion | validacion).
  Future<void> guardar(SensorReading lectura);

  /// Lista lecturas ordenadas por `recorded_at` descendente.
  /// Lanza AppException(conexion).
  Future<List<SensorReading>> listar({
    TipoSensor? tipo,
    String? capturadoPor,
    int limite = 50,
    int desplazamiento = 0,
  });

  /// Devuelve una lectura o null si no existe. Lanza AppException(conexion).
  Future<SensorReading?> obtenerPorId(int id);

  /// Cantidad de lecturas por tipo. Lanza AppException(conexion).
  Future<Map<TipoSensor, int>> contarPorTipo({String? capturadoPor});
}
