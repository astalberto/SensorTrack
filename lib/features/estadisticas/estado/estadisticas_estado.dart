// Estado de la pantalla de estadísticas.
// Responsable: Cody

import 'package:flutter/foundation.dart';

import '../../../core/constantes/tipos_sensor.dart';
import '../../../core/errores/app_exception.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../servicios/estadisticas_calculo.dart';

class EstadisticasEstado extends ChangeNotifier {
  EstadisticasEstado(this._calculo);

  final EstadisticasCalculo _calculo;

  /// Sensores que se pueden ver en el gráfico de evolución.
  static const tiposGrafico = [TipoSensor.accelerometer, TipoSensor.gyroscope];

  bool cargando = false;
  bool cargandoGrafico = false;
  ResumenEstadisticas? resumen;
  List<SensorReading> serie = const [];
  TipoSensor tipoGrafico = TipoSensor.accelerometer;
  String? mensajeError;
  bool _liberado = false;

  /// Carga el resumen y la serie del gráfico.
  /// No lanza: los errores quedan en [mensajeError].
  Future<void> cargar() async {
    cargando = true;
    mensajeError = null;
    notifyListeners();

    try {
      final resultados = await Future.wait<Object>([
        _calculo.resumen(),
        _calculo.evolucion(tipoGrafico),
      ]);
      resumen = resultados[0] as ResumenEstadisticas;
      serie = resultados[1] as List<SensorReading>;
    } catch (e) {
      mensajeError = _mensaje(e);
    }
    cargando = false;
    notifyListeners();
  }

  /// Cambia el sensor del gráfico y recarga solo su serie. No lanza.
  Future<void> cambiarTipoGrafico(TipoSensor tipo) async {
    if (tipo == tipoGrafico) return;
    tipoGrafico = tipo;
    cargandoGrafico = true;
    notifyListeners();

    try {
      serie = await _calculo.evolucion(tipo);
    } catch (e) {
      serie = const [];
      mensajeError = _mensaje(e);
    }
    cargandoGrafico = false;
    notifyListeners();
  }

  String _mensaje(Object e) => e is AppException
      ? e.mensaje
      : 'No se pudieron cargar las estadísticas. Revisa tu conexión.';

  /// No notifica si la pantalla se cerró mientras se esperaba la base.
  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }
}
