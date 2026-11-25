// Implementación de ReadingsRepository sobre la tabla `sensor_readings`.
// Responsable: Josué

import '../../core/constantes/tipos_sensor.dart';
import '../modelos/sensor_reading.dart';
import 'readings_repository.dart';

class SupabaseReadingsRepository implements ReadingsRepository {
  static const tabla = 'sensor_readings';

  @override
  Future<void> guardar(SensorReading lectura) {
    // TODO(Josué): insertar en Supabase y traducir errores a AppException.
    throw UnimplementedError();
  }

  @override
  Future<List<SensorReading>> listar({
    TipoSensor? tipo,
    String? capturadoPor,
    int limite = 50,
    int desplazamiento = 0,
  }) {
    // TODO(Josué)
    throw UnimplementedError();
  }

  @override
  Future<SensorReading?> obtenerPorId(int id) {
    // TODO(Josué)
    throw UnimplementedError();
  }

  @override
  Future<Map<TipoSensor, int>> contarPorTipo({String? capturadoPor}) {
    // TODO(Josué)
    throw UnimplementedError();
  }
}
