import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/features/home/estado/home_estado.dart';
import 'package:sensor_track/features/home/servicios/detector_sensores.dart';
import 'package:sensor_track/features/sensores/servicios/sensor_service.dart';

void main() {
  HomeEstado crear({
    bool configurado = true,
    Future<bool> Function()? conexion,
    Future<List<DisponibilidadSensor>> Function()? sensores,
    String capturadoPor = 'Alberto',
  }) => HomeEstado(
    configurado: configurado,
    comprobarConexion: conexion ?? () async => true,
    detectarSensores: sensores ?? () async => const [],
    capturadoPor: capturadoPor,
    tiempoLimite: const Duration(milliseconds: 20),
  );

  group('conexión', () {
    test('sin credenciales queda sin configurar y no consulta', () async {
      var consultas = 0;
      final estado = crear(
        configurado: false,
        conexion: () async {
          consultas++;
          return true;
        },
      );

      await estado.comprobarConexion();

      expect(estado.conexion, EstadoConexion.sinConfigurar);
      expect(consultas, 0);
    });

    test('pasa de comprobando a conectado', () async {
      final estado = crear();
      final vistos = <EstadoConexion>[];
      estado.addListener(() => vistos.add(estado.conexion));

      await estado.comprobarConexion();

      expect(vistos, [EstadoConexion.comprobando, EstadoConexion.conectado]);
    });

    test('false del servicio es sin conexión', () async {
      final estado = crear(conexion: () async => false);
      await estado.comprobarConexion();
      expect(estado.conexion, EstadoConexion.sinConexion);
    });

    test('una excepción es sin conexión y no se propaga', () async {
      final estado = crear(conexion: () async => throw Exception('sin red'));
      await estado.comprobarConexion();
      expect(estado.conexion, EstadoConexion.sinConexion);
    });

    test('si no responde a tiempo es sin conexión', () async {
      final estado = crear(conexion: () => Completer<bool>().future);
      await estado.comprobarConexion();
      expect(estado.conexion, EstadoConexion.sinConexion);
    });
  });

  group('sensores', () {
    test('cargar llena la lista de sensores', () async {
      const lista = [
        DisponibilidadSensor(
          TipoSensor.accelerometer,
          disponible: true,
          detalle: 'Disponible',
        ),
      ];
      final estado = crear(sensores: () async => lista);

      await estado.cargar();

      expect(estado.sensores, lista);
      expect(estado.detectandoSensores, isFalse);
      expect(estado.conexion, EstadoConexion.conectado);
    });

    test('un fallo del detector deja la lista vacía', () async {
      final estado = crear(sensores: () async => throw Exception('fallo'));
      await estado.detectarSensores();
      expect(estado.sensores, isEmpty);
      expect(estado.detectandoSensores, isFalse);
    });
  });

  test('avisa si falta CAPTURADO_POR', () {
    expect(crear(capturadoPor: '  ').faltaCapturadoPor, isTrue);
    expect(crear().faltaCapturadoPor, isFalse);
  });

  test('salir de Home antes de que termine la carga no falla', () async {
    final respuesta = Completer<bool>();
    final estado = HomeEstado(
      configurado: true,
      comprobarConexion: () => respuesta.future,
      detectarSensores: () async => const [],
      capturadoPor: 'Alberto',
    );

    final carga = estado.comprobarConexion();
    estado.dispose();
    respuesta.complete(true);

    await expectLater(carga, completes);
  });

  group('DetectorSensores', () {
    MuestraSensor muestra() => MuestraSensor(0, 0, 9.8, DateTime(2026));

    test('informa acelerómetro, giroscopio y GPS en orden', () async {
      final detector = DetectorSensores(
        sensores: SensorService(
          acelerometro: (_) => Stream.value(muestra()),
          giroscopio: (_) => Stream.error(Exception('NO_SENSOR')),
        ),
        gpsActivo: () async => true,
      );

      final lista = await detector.detectar();

      expect(lista.map((s) => s.tipo), [
        TipoSensor.accelerometer,
        TipoSensor.gyroscope,
        TipoSensor.gps,
      ]);
      expect(lista.map((s) => s.disponible), [true, false, true]);
    });

    test('un fallo al consultar el GPS cuenta como desactivado', () async {
      final detector = DetectorSensores(
        sensores: SensorService(
          acelerometro: (_) => Stream.value(muestra()),
          giroscopio: (_) => Stream.value(muestra()),
        ),
        gpsActivo: () async => throw Exception('sin plugin'),
      );

      final gps = (await detector.detectar()).last;

      expect(gps.disponible, isFalse);
      expect(gps.detalle, 'Servicio de ubicación desactivado');
    });
  });
}
