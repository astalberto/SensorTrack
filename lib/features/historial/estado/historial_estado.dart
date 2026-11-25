// Estado del historial: lista, filtro seleccionado y carga de detalle.
// Responsable: Josué

import 'package:flutter/foundation.dart';

import '../../../shared/modelos/sensor_reading.dart';
import '../servicios/historial_consulta.dart';

class HistorialEstado extends ChangeNotifier {
  HistorialEstado(this._consulta);

  // ignore: unused_field
  final HistorialConsulta _consulta;

  bool cargando = false;
  List<SensorReading> registros = [];
  String? mensajeError;

  // TODO(Josué): cargar(), cargarMas(), filtrar(tipo).
}
