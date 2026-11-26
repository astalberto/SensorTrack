import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/features/sensores/estado/sensores_estado.dart';
import 'package:sensor_track/features/sensores/servicios/sensor_service.dart';

import 'fuente_falsa.dart';

void main() {
  late FuenteFalsa acelerometro;
  late FuenteFalsa giroscopio;
  late SensoresEstado estado;

  setUp(() {
    acelerometro = FuenteFalsa();
    giroscopio = FuenteFalsa();
    estado = SensoresEstado(
      SensorService(
        acelerometro: acelerometro.call,
        giroscopio: giroscopio.call,
      ),
      capturadoPor: 'Alberto',
    );
  });

  test('empieza detenido, en el acelerómetro y sin lectura', () {
    expect(estado.activo, isFalse);
    expect(estado.sensor, TipoSensor.accelerometer);
    expect(estado.frecuencia, FrecuenciaMuestreo.normal);
    expect(estado.lecturaActual(), isNull);
    estado.dispose();
  });

  test('iniciar abre la suscripción y guarda la última muestra', () async {
    var avisos = 0;
    estado.addListener(() => avisos++);

    estado.iniciar();
    acelerometro.emitir(0.1, 0.2, 9.8);
    await vaciarCola();

    expect(estado.activo, isTrue);
    expect(acelerometro.hayOyentes, isTrue);
    expect(acelerometro.intervalos, [FrecuenciaMuestreo.normal.intervalo]);
    expect(estado.ultimaMuestra?.z, 9.8);
    expect(avisos, 2); // al iniciar y al recibir la muestra
    estado.dispose();
  });

  test('lecturaActual arma un SensorReading de tres ejes sin GPS', () async {
    final momento = DateTime(2026, 11, 25, 10, 30);
    estado.iniciar();
    acelerometro.emitir(1, 2, 3, momento);
    await vaciarCola();

    final lectura = estado.lecturaActual()!;

    expect(lectura.tipo, TipoSensor.accelerometer);
    expect((lectura.x, lectura.y, lectura.z), (1.0, 2.0, 3.0));
    expect(lectura.latitude, isNull);
    expect(lectura.longitude, isNull);
    expect(lectura.accuracy, isNull);
    expect(lectura.recordedAt, momento);
    expect(lectura.capturadoPor, 'Alberto');
    estado.dispose();
  });

  test('detener cancela la suscripción y conserva la muestra', () async {
    estado.iniciar();
    acelerometro.emitir(1, 1, 1);
    await vaciarCola();

    estado.detener();

    expect(estado.activo, isFalse);
    expect(acelerometro.hayOyentes, isFalse);
    expect(estado.lecturaActual(), isNotNull);
    estado.dispose();
  });

  test('dispose cancela la suscripción (regla 2.1.5)', () {
    estado.iniciar();
    expect(acelerometro.hayOyentes, isTrue);

    estado.dispose();

    expect(acelerometro.hayOyentes, isFalse);
  });

  test('un error del sensor deja el mensaje y detiene la lectura', () async {
    estado.iniciar();
    acelerometro.ultimo.addError(
      const AppException(CategoriaError.sensor, 'Sin acelerómetro.'),
    );
    await vaciarCola();

    expect(estado.mensajeError, 'Sin acelerómetro.');
    expect(estado.activo, isFalse);
    expect(acelerometro.hayOyentes, isFalse);

    estado.iniciar();
    expect(estado.mensajeError, isNull, reason: 'reintentar limpia el error');
    estado.dispose();
  });

  test('cambiar de sensor estando activo pasa al nuevo sensor', () async {
    estado.iniciar();
    acelerometro.emitir(1, 1, 1);
    await vaciarCola();

    estado.seleccionarSensor(TipoSensor.gyroscope);

    expect(estado.sensor, TipoSensor.gyroscope);
    expect(estado.activo, isTrue);
    expect(acelerometro.hayOyentes, isFalse);
    expect(giroscopio.hayOyentes, isTrue);
    expect(
      estado.ultimaMuestra,
      isNull,
      reason: 'no mezcla valores de sensores',
    );
    estado.dispose();
  });

  test('cambiar de sensor estando detenido no abre suscripciones', () {
    estado.seleccionarSensor(TipoSensor.gyroscope);

    expect(estado.activo, isFalse);
    expect(giroscopio.controladores, isEmpty);
    estado.dispose();
  });

  test('no acepta el GPS', () {
    expect(() => estado.seleccionarSensor(TipoSensor.gps), throwsArgumentError);
    estado.dispose();
  });

  test('cambiar la frecuencia estando activo se vuelve a suscribir', () {
    estado.iniciar();

    estado.cambiarFrecuencia(FrecuenciaMuestreo.alta);

    expect(acelerometro.intervalos, [
      FrecuenciaMuestreo.normal.intervalo,
      FrecuenciaMuestreo.alta.intervalo,
    ]);
    expect(
      acelerometro.controladores.where((c) => c.hasListener),
      hasLength(1),
    );
    estado.dispose();
  });

  test('pausa en segundo plano y reanuda al volver', () {
    estado.iniciar();

    estado.pausarPorSegundoPlano();
    expect(estado.activo, isFalse);
    expect(acelerometro.hayOyentes, isFalse);

    estado.reanudarDesdeSegundoPlano();
    expect(estado.activo, isTrue);
    estado.dispose();
  });

  test('no reanuda si estaba detenido antes de pasar a segundo plano', () {
    estado.pausarPorSegundoPlano();
    estado.reanudarDesdeSegundoPlano();

    expect(estado.activo, isFalse);
    expect(acelerometro.controladores, isEmpty);
    estado.dispose();
  });
}
