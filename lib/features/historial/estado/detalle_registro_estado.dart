// Estado del detalle de un registro: carga por id.
// Responsable: Josué

import 'package:flutter/foundation.dart';

import '../../../core/errores/app_exception.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../servicios/historial_consulta.dart';

class DetalleRegistroEstado extends ChangeNotifier {
  DetalleRegistroEstado(this._consulta, this.id);

  final HistorialConsulta _consulta;
  final int id;

  bool cargando = false;

  /// Null mientras carga, si hubo error o si el registro no existe.
  SensorReading? registro;

  String? mensajeError;

  /// La consulta terminó bien pero no hay registro con ese id.
  bool get noEncontrado =>
      !cargando && mensajeError == null && registro == null;

  bool _descartado = false;

  Future<void> cargar() async {
    cargando = true;
    mensajeError = null;
    _notificar();
    try {
      registro = await _consulta.detalle(id);
    } on AppException catch (e) {
      mensajeError = e.mensaje;
    } catch (e) {
      debugPrint('DetalleRegistroEstado: error inesperado: $e');
      mensajeError = 'Ocurrió un error inesperado al cargar el registro.';
    }
    cargando = false;
    _notificar();
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
