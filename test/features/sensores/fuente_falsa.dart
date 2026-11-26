// Fuente de muestras controlada por la prueba, en lugar de sensors_plus.

import 'dart:async';

import 'package:sensor_track/features/sensores/servicios/sensor_service.dart';

class FuenteFalsa {
  final controladores = <StreamController<MuestraSensor>>[];
  final intervalos = <Duration>[];

  /// Firma de `FuenteSensor`: cada suscripción recibe su propio controlador.
  Stream<MuestraSensor> call(Duration intervalo) {
    intervalos.add(intervalo);
    final controlador = StreamController<MuestraSensor>();
    controladores.add(controlador);
    return controlador.stream;
  }

  StreamController<MuestraSensor> get ultimo => controladores.last;

  /// True si alguien sigue suscrito a alguna muestra de esta fuente.
  bool get hayOyentes => controladores.any((c) => c.hasListener);

  void emitir(double x, double y, double z, [DateTime? momento]) =>
      ultimo.add(MuestraSensor(x, y, z, momento ?? DateTime(2026, 11, 25)));
}

/// Deja que se entreguen los eventos pendientes de los streams.
Future<void> vaciarCola() => Future<void>.delayed(Duration.zero);
