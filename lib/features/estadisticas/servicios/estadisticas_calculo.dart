// Cálculos de M5: conteos por tipo, máximos, mínimos y última ubicación.
// Responsable: Cody

import '../../../core/constantes/tipos_sensor.dart';
import '../../../shared/datos/readings_repository.dart';
import '../../../shared/modelos/sensor_reading.dart';

class EstadisticasCalculo {
  EstadisticasCalculo(this._repositorio);

  final ReadingsRepository _repositorio;

  Future<Map<TipoSensor, int>> conteos({String? capturadoPor}) =>
      _repositorio.contarPorTipo(capturadoPor: capturadoPor);

  // TODO(Cody): máximos/mínimos por eje y última ubicación.
  Future<SensorReading?> ultimaUbicacion() async {
    final lista = await _repositorio.listar(tipo: TipoSensor.gps, limite: 1);
    return lista.isEmpty ? null : lista.first;
  }
}
