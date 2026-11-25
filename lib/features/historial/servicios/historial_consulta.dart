// Consultas del historial: filtros por tipo y paginación.
// Responsable: Josué

import '../../../core/constantes/tipos_sensor.dart';
import '../../../shared/datos/readings_repository.dart';
import '../../../shared/modelos/sensor_reading.dart';

class HistorialConsulta {
  HistorialConsulta(this._repositorio);

  final ReadingsRepository _repositorio;
  static const tamanoPagina = 20;

  Future<List<SensorReading>> pagina(int numero, {TipoSensor? tipo}) =>
      _repositorio.listar(
        tipo: tipo,
        limite: tamanoPagina,
        desplazamiento: numero * tamanoPagina,
      );
}
