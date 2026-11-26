import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/features/sensores/servicios/sensor_service.dart';

import 'fuente_falsa.dart';

void main() {
  late FuenteFalsa acelerometro;
  late FuenteFalsa giroscopio;
  late SensorService servicio;

  setUp(() {
    acelerometro = FuenteFalsa();
    giroscopio = FuenteFalsa();
    servicio = SensorService(
      acelerometro: acelerometro.call,
      giroscopio: giroscopio.call,
    );
  });

  group('stream', () {
    test('usa la fuente del tipo pedido y su intervalo', () async {
      final recibidas = <MuestraSensor>[];
      final sub = servicio
          .stream(
            TipoSensor.gyroscope,
            intervalo: FrecuenciaMuestreo.alta.intervalo,
          )
          .listen(recibidas.add);

      giroscopio.emitir(1, 2, 3);
      await vaciarCola();

      expect(recibidas.single.z, 3);
      expect(giroscopio.intervalos, [FrecuenciaMuestreo.alta.intervalo]);
      expect(acelerometro.controladores, isEmpty);
      await sub.cancel();
    });

    test('traduce un error de la plataforma a AppException(sensor)', () async {
      final errores = <Object>[];
      final sub = servicio
          .stream(TipoSensor.accelerometer)
          .listen((_) {}, onError: errores.add);

      acelerometro.ultimo.addError(Exception('NO_SENSOR'));
      await vaciarCola();

      final error = errores.single as AppException;
      expect(error.categoria, CategoriaError.sensor);
      expect(
        error.mensaje,
        'El acelerómetro no está disponible en este dispositivo.',
      );
      await sub.cancel();
    });

    test('deja pasar una AppException sin cambiarla', () async {
      const original = AppException(CategoriaError.sensor, 'Mensaje propio');
      final errores = <Object>[];
      final sub = servicio
          .stream(TipoSensor.accelerometer)
          .listen((_) {}, onError: errores.add);

      acelerometro.ultimo.addError(original);
      await vaciarCola();

      expect(errores.single, same(original));
      await sub.cancel();
    });

    test('rechaza el GPS, que pertenece a la feature ubicacion', () {
      expect(() => servicio.stream(TipoSensor.gps), throwsArgumentError);
    });
  });

  group('estaDisponible', () {
    test(
      'devuelve true con la primera muestra y cancela la suscripción',
      () async {
        final futuro = servicio.estaDisponible(TipoSensor.accelerometer);
        acelerometro.emitir(0, 0, 9.8);

        expect(await futuro, isTrue);
        expect(acelerometro.hayOyentes, isFalse);
      },
    );

    test('devuelve false si el sensor responde con error', () async {
      final futuro = servicio.estaDisponible(TipoSensor.gyroscope);
      giroscopio.ultimo.addError(Exception('NO_SENSOR'));

      expect(await futuro, isFalse);
      expect(giroscopio.hayOyentes, isFalse);
    });

    test('devuelve false si no llegan datos a tiempo y cancela', () async {
      final disponible = await servicio.estaDisponible(
        TipoSensor.gyroscope,
        espera: const Duration(milliseconds: 10),
      );

      expect(disponible, isFalse);
      expect(giroscopio.hayOyentes, isFalse);
    });

    test('devuelve false para el GPS en vez de lanzar', () async {
      expect(await servicio.estaDisponible(TipoSensor.gps), isFalse);
    });
  });
}
