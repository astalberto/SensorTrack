// Estado de la pantalla de sensores: suscripciones, frecuencia y último valor.
// Responsable: Alberto

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../servicios/sensor_service.dart';

class SensoresEstado extends ChangeNotifier {
  SensoresEstado(this._servicio);

  // ignore: unused_field
  final SensorService _servicio;
  final List<StreamSubscription<dynamic>> _suscripciones = [];

  // TODO(Alberto): iniciar/detener streams y guardar el último valor.

  /// Las suscripciones se cancelan al salir de la pantalla (regla 2.1.5).
  @override
  void dispose() {
    for (final s in _suscripciones) {
      s.cancel();
    }
    super.dispose();
  }
}
