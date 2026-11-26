// Streams de acelerómetro y giroscopio (sensors_plus).
// Responsable: Alberto

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/constantes/tipos_sensor.dart';
import '../../../core/errores/app_exception.dart';

/// Una muestra de un sensor de tres ejes.
class MuestraSensor {
  const MuestraSensor(this.x, this.y, this.z, this.momento);

  final double x;
  final double y;
  final double z;

  /// Hora del dispositivo en que llegó la muestra. Es la que se guarda como
  /// `recorded_at`.
  final DateTime momento;
}

/// Frecuencias de muestreo que ofrece la pantalla de sensores.
enum FrecuenciaMuestreo {
  normal('5 Hz', SensorInterval.normalInterval),
  media('15 Hz', SensorInterval.uiInterval),
  alta('50 Hz', SensorInterval.gameInterval);

  const FrecuenciaMuestreo(this.etiqueta, this.intervalo);

  /// Frecuencia para mostrar en pantalla. Es aproximada: Android no garantiza
  /// la frecuencia pedida, depende del hardware y del fabricante.
  final String etiqueta;
  final Duration intervalo;
}

/// Fuente de muestras crudas de un sensor para un intervalo dado.
typedef FuenteSensor = Stream<MuestraSensor> Function(Duration intervalo);

class SensorService {
  /// Las fuentes se pueden reemplazar en pruebas. Por defecto usan sensors_plus.
  SensorService({FuenteSensor? acelerometro, FuenteSensor? giroscopio})
    : _acelerometro = acelerometro ?? _acelerometroReal,
      _giroscopio = giroscopio ?? _giroscopioReal;

  final FuenteSensor _acelerometro;
  final FuenteSensor _giroscopio;

  /// Muestras del sensor [tipo] en tiempo real.
  ///
  /// Si el dispositivo no tiene el sensor, el stream emite un
  /// `AppException(sensor)`. Quien se suscribe debe cancelar la suscripción
  /// al salir de la pantalla.
  ///
  /// Lanza [ArgumentError] si [tipo] es [TipoSensor.gps]: el GPS es de la
  /// feature `ubicacion`.
  Stream<MuestraSensor> stream(
    TipoSensor tipo, {
    Duration intervalo = SensorInterval.normalInterval,
  }) {
    final fuente = switch (tipo) {
      TipoSensor.accelerometer => _acelerometro,
      TipoSensor.gyroscope => _giroscopio,
      TipoSensor.gps => throw ArgumentError.value(
        tipo,
        'tipo',
        'El GPS se lee desde la feature ubicacion',
      ),
    };
    return fuente(intervalo).transform(
      StreamTransformer.fromHandlers(
        handleError: (error, traza, sink) => sink.addError(
          error is AppException ? error : _noDisponible(tipo, error),
          traza,
        ),
      ),
    );
  }

  /// Indica si el sensor [tipo] entrega datos.
  ///
  /// Se suscribe al stream y espera la primera muestra. Devuelve false si llega
  /// un error o si pasa [espera] sin datos. Siempre cancela la suscripción.
  /// No lanza excepciones.
  Future<bool> estaDisponible(
    TipoSensor tipo, {
    Duration espera = const Duration(seconds: 2),
  }) async {
    final resultado = Completer<bool>();
    void responder(bool valor) {
      if (!resultado.isCompleted) resultado.complete(valor);
    }

    final StreamSubscription<MuestraSensor> suscripcion;
    try {
      suscripcion = stream(tipo).listen(
        (_) => responder(true),
        onError: (Object _) => responder(false),
        cancelOnError: true,
      );
    } catch (_) {
      return false;
    }
    try {
      return await resultado.future.timeout(espera, onTimeout: () => false);
    } finally {
      await suscripcion.cancel();
    }
  }

  static AppException _noDisponible(TipoSensor tipo, Object causa) =>
      AppException(
        CategoriaError.sensor,
        'El ${tipo.etiqueta.toLowerCase()} no está disponible en este '
        'dispositivo.',
        causa: causa,
      );

  // sensors_plus solo funciona en Android, iOS y web. En escritorio el stream
  // nunca emite, así que se informa el error de inmediato.
  static bool get _plataformaSoportada =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static const _sinSoporte = AppException(
    CategoriaError.sensor,
    'Los sensores solo funcionan en un teléfono (Android o iOS).',
  );

  // Se usa la hora de llegada y no el `timestamp` del evento: es la hora real
  // del dispositivo en todas las plataformas.
  static Stream<MuestraSensor> _acelerometroReal(Duration intervalo) =>
      _plataformaSoportada
      ? accelerometerEventStream(samplingPeriod: intervalo)
            .map((e) => MuestraSensor(e.x, e.y, e.z, DateTime.now()))
      : Stream.error(_sinSoporte);

  static Stream<MuestraSensor> _giroscopioReal(Duration intervalo) =>
      _plataformaSoportada
      ? gyroscopeEventStream(samplingPeriod: intervalo)
            .map((e) => MuestraSensor(e.x, e.y, e.z, DateTime.now()))
      : Stream.error(_sinSoporte);
}
