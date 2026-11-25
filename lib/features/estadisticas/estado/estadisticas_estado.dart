// Estado de la pantalla de estadísticas.
// Responsable: Cody

import 'package:flutter/foundation.dart';

import '../servicios/estadisticas_calculo.dart';

class EstadisticasEstado extends ChangeNotifier {
  EstadisticasEstado(this._calculo);

  // ignore: unused_field
  final EstadisticasCalculo _calculo;

  bool cargando = false;
  String? mensajeError;

  // TODO(Cody): cargar() y filtro por capturado_por.
}
