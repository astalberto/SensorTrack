// Interfaz del repositorio de lecturas. Las features dependen de esta
// interfaz, no de Supabase directamente.
// Responsable: Josué
//
// Todos los métodos lanzan solo AppException, con mensaje en español:
//   - conexion:   sin internet, tiempo agotado, clave inválida, tabla ausente.
//   - permiso:    la base rechazó la operación (RLS o permisos).
//   - validacion: la base rechazó los datos de la lectura (solo `guardar`).

import '../../core/constantes/tipos_sensor.dart';
import '../modelos/sensor_reading.dart';

abstract class ReadingsRepository {
  /// Inserta una lectura. La base genera el `id`.
  /// Lanza AppException(conexion | permiso | validacion).
  Future<void> guardar(SensorReading lectura);

  /// Lista lecturas ordenadas por `recorded_at` descendente (las más recientes
  /// primero). Los filtros nulos no se aplican.
  /// Lanza AppException(conexion | permiso).
  Future<List<SensorReading>> listar({
    TipoSensor? tipo,
    String? capturadoPor,
    int limite = 50,
    int desplazamiento = 0,
  });

  /// Devuelve una lectura o null si no existe.
  /// Lanza AppException(conexion | permiso).
  Future<SensorReading?> obtenerPorId(int id);

  /// Cantidad de lecturas por tipo; incluye todos los tipos, con 0 si no hay.
  /// Lanza AppException(conexion | permiso).
  Future<Map<TipoSensor, int>> contarPorTipo({String? capturadoPor});
}
