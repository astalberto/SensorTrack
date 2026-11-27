// Pruebas de SupabaseReadingsRepository contra un servidor simulado:
// verifican las peticiones a PostgREST y la traducción de errores, sin tocar
// la base compartida.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/shared/datos/supabase_readings_repository.dart';
import 'package:sensor_track/shared/datos/supabase_service.dart';
import 'package:sensor_track/shared/modelos/sensor_reading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/repositorio_en_memoria.dart';

typedef Responder = FutureOr<http.Response> Function(http.Request peticion);

http.Response json(
  http.Request peticion,
  Object? cuerpo, {
  int estado = 200,
  Map<String, String> cabeceras = const {},
}) => http.Response(
  cuerpo == null ? '' : jsonEncode(cuerpo),
  estado,
  request: peticion,
  headers: {'content-type': 'application/json; charset=utf-8', ...cabeceras},
);

Map<String, Object?> filaAcelerometro(int id) => {
  'id': id,
  'sensor_type': 'accelerometer',
  'x': 0.5,
  'y': 9.81,
  'z': -1,
  'latitude': null,
  'longitude': null,
  'accuracy': null,
  'recorded_at': '2026-11-25T17:30:00.123+00:00',
  'capturado_por': 'alberto',
};

void main() {
  final peticiones = <http.Request>[];
  SupabaseClient? cliente;

  SupabaseClient crearCliente(Responder responder) {
    peticiones.clear();
    return cliente = SupabaseClient(
      'https://demo.supabase.co',
      'clave-de-prueba',
      httpClient: MockClient((peticion) async {
        peticiones.add(peticion);
        return responder(peticion);
      }),
    );
  }

  SupabaseReadingsRepository repositorio(
    Responder responder, {
    Duration tiempoMaximo = const Duration(seconds: 5),
  }) => SupabaseReadingsRepository(
    cliente: crearCliente(responder),
    tiempoMaximo: tiempoMaximo,
  );

  tearDown(() async {
    await cliente?.dispose();
    cliente = null;
  });

  group('guardar', () {
    test('envía un POST con los campos de la lectura y sin id', () async {
      final repo = repositorio((p) => json(p, null, estado: 201));

      await repo.guardar(acelerometro(id: 99, capturadoPor: 'josue'));

      final p = peticiones.single;
      expect(p.method, 'POST');
      expect(p.url.path, '/rest/v1/sensor_readings');
      final cuerpo = jsonDecode(p.body) as Map<String, dynamic>;
      expect(cuerpo.containsKey('id'), isFalse);
      expect(cuerpo['sensor_type'], 'accelerometer');
      expect(cuerpo['capturado_por'], 'josue');
      expect(cuerpo['recorded_at'], '2026-11-25T12:00:00.000Z');
      expect(cuerpo['latitude'], isNull);
    });

    test('valores NaN se reportan como error de validación', () async {
      final repo = repositorio((p) => json(p, null, estado: 201));

      await expectLater(
        repo.guardar(acelerometro(x: double.nan)),
        throwsA(
          isA<AppException>().having(
            (e) => e.categoria,
            'categoria',
            CategoriaError.validacion,
          ),
        ),
      );
      expect(peticiones, isEmpty);
    });
  });

  group('listar', () {
    test('aplica filtros, orden descendente y paginación', () async {
      final repo = repositorio((p) => json(p, [filaAcelerometro(7)]));

      final lista = await repo.listar(
        tipo: TipoSensor.accelerometer,
        capturadoPor: 'alberto',
        limite: 20,
        desplazamiento: 40,
      );

      final q = peticiones.single.url.queryParameters;
      expect(peticiones.single.method, 'GET');
      expect(q['sensor_type'], 'eq.accelerometer');
      expect(q['capturado_por'], 'eq.alberto');
      expect(q['order'], 'recorded_at.desc.nullslast,id.desc.nullslast');
      expect(q['offset'], '40');
      expect(q['limit'], '20');

      final r = lista.single;
      expect(r.id, 7);
      expect(r.tipo, TipoSensor.accelerometer);
      expect(r.z, -1.0);
      expect(r.recordedAt, DateTime.utc(2026, 11, 25, 17, 30, 0, 123));
      expect(r.capturadoPor, 'alberto');
    });

    test('sin filtros no envía sensor_type ni capturado_por', () async {
      final repo = repositorio((p) => json(p, []));

      expect(await repo.listar(), isEmpty);

      final q = peticiones.single.url.queryParameters;
      expect(q.containsKey('sensor_type'), isFalse);
      expect(q.containsKey('capturado_por'), isFalse);
      expect(q['limit'], '50');
    });

    test('límite 0 no hace ninguna petición', () async {
      final repo = repositorio((p) => json(p, []));
      expect(await repo.listar(limite: 0), isEmpty);
      expect(peticiones, isEmpty);
    });
  });

  group('obtenerPorId', () {
    test('devuelve la lectura', () async {
      final repo = repositorio((p) => json(p, [filaAcelerometro(5)]));

      final r = await repo.obtenerPorId(5);

      expect(peticiones.single.url.queryParameters['id'], 'eq.5');
      expect(r?.id, 5);
    });

    test('devuelve null si no existe', () async {
      final repo = repositorio((p) => json(p, []));
      expect(await repo.obtenerPorId(404), isNull);
    });
  });

  test('contarPorTipo hace un HEAD por tipo y lee content-range', () async {
    const conteos = {'accelerometer': 12, 'gyroscope': 3, 'gps': 0};
    final repo = repositorio((p) {
      final tipo = p.url.queryParameters['sensor_type']!.substring(3);
      return json(p, null, cabeceras: {'content-range': '*/${conteos[tipo]}'});
    });

    final resultado = await repo.contarPorTipo(capturadoPor: 'cody');

    expect(resultado, {
      TipoSensor.accelerometer: 12,
      TipoSensor.gyroscope: 3,
      TipoSensor.gps: 0,
    });
    expect(peticiones, hasLength(3));
    for (final p in peticiones) {
      expect(p.method, 'HEAD');
      expect(p.url.queryParameters['capturado_por'], 'eq.cody');
    }
  });

  group('traducción de errores', () {
    Future<AppException> errorDe(Responder responder) async {
      try {
        await repositorio(responder).listar();
      } on AppException catch (e) {
        return e;
      }
      fail('Se esperaba AppException');
    }

    Map<String, Object?> pgError(String codigo) => {
      'code': codigo,
      'message': 'mensaje del servidor',
      'details': null,
      'hint': null,
    };

    test('42501 (RLS / sin GRANT) es permiso', () async {
      final e = await errorDe((p) => json(p, pgError('42501'), estado: 401));
      expect(e.categoria, CategoriaError.permiso);
      expect(e.mensaje, contains('migración'));
    });

    test('23514 (CHECK) es validación', () async {
      final e = await errorDe((p) => json(p, pgError('23514'), estado: 400));
      expect(e.categoria, CategoriaError.validacion);
    });

    test('PGRST205 (tabla inexistente) pide aplicar la migración', () async {
      final e = await errorDe((p) => json(p, pgError('PGRST205'), estado: 404));
      expect(e.categoria, CategoriaError.conexion);
      expect(e.mensaje, contains('sensor_readings no existe'));
    });

    // Se prueba con guardar (POST): supabase 2.16.5 ignora retryEnabled en
    // from() y los GET reintentarían 3 veces con esperas de 1, 2 y 4 s.
    test('sin internet es conexión', () async {
      final repo = repositorio(
        (p) => throw http.ClientException('Failed host lookup', p.url),
      );
      await expectLater(
        repo.guardar(acelerometro()),
        throwsA(
          isA<AppException>()
              .having((e) => e.categoria, 'categoria', CategoriaError.conexion)
              .having(
                (e) => e.mensaje,
                'mensaje',
                contains('No se pudo conectar'),
              )
              .having((e) => e.causa, 'causa', isA<http.ClientException>()),
        ),
      );
    });

    test('tiempo agotado es conexión', () async {
      final nuncaResponde = Completer<http.Response>();
      final repo = repositorio(
        (_) => nuncaResponde.future,
        tiempoMaximo: const Duration(milliseconds: 50),
      );
      await expectLater(
        repo.listar(),
        throwsA(
          isA<AppException>()
              .having((e) => e.categoria, 'categoria', CategoriaError.conexion)
              .having((e) => e.mensaje, 'mensaje', contains('tardó')),
        ),
      );
    });
  });

  test('sin --dart-define avisa que Supabase no está configurado', () async {
    expect(SupabaseService.estaInicializado, isFalse);
    await expectLater(
      SupabaseReadingsRepository().listar(),
      throwsA(
        isA<AppException>()
            .having((e) => e.categoria, 'categoria', CategoriaError.conexion)
            .having((e) => e.mensaje, 'mensaje', contains('env/dev.json')),
      ),
    );
  });

  group('SupabaseService.hayConexion', () {
    test('true si la tabla responde', () async {
      final c = crearCliente((p) => json(p, []));
      expect(await SupabaseService.hayConexion(cliente: c), isTrue);
      expect(peticiones.single.url.queryParameters['limit'], '1');
    });

    test('false si la base rechaza la consulta', () async {
      final c = crearCliente(
        (p) => json(p, {'code': '42501', 'message': 'denied'}, estado: 401),
      );
      expect(await SupabaseService.hayConexion(cliente: c), isFalse);
    });

    test('false sin configuración', () async {
      expect(await SupabaseService.hayConexion(), isFalse);
    });
  });

  test('toMap y fromMap son inversos para GPS', () {
    final original = gps(id: 3);
    final copia = SensorReading.fromMap({'id': 3, ...original.toMap()});
    expect(copia.tipo, TipoSensor.gps);
    expect(copia.latitude, original.latitude);
    expect(copia.accuracy, original.accuracy);
    expect(copia.recordedAt, original.recordedAt);
    expect(copia.x, isNull);
  });
}
