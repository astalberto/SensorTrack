// Consultas del historial: filtros por tipo y por integrante, y paginación.
// Responsable: Josué

import '../../../core/constantes/tipos_sensor.dart';
import '../../../shared/datos/readings_repository.dart';
import '../../../shared/modelos/sensor_reading.dart';

class HistorialConsulta {
  HistorialConsulta(this._repositorio);

  final ReadingsRepository _repositorio;
  static const tamanoPagina = 20;

  /// Página [numero] (desde 0), más recientes primero.
  /// Lanza AppException(conexion | permiso).
  Future<List<SensorReading>> pagina(
    int numero, {
    TipoSensor? tipo,
    String? capturadoPor,
  }) => _repositorio.listar(
    tipo: tipo,
    capturadoPor: capturadoPor,
    limite: tamanoPagina,
    desplazamiento: numero * tamanoPagina,
  );

  /// Registro completo o null si no existe.
  /// Lanza AppException(conexion | permiso).
  Future<SensorReading?> detalle(int id) => _repositorio.obtenerPorId(id);
}
