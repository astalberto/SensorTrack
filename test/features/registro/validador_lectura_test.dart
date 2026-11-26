import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/features/registro/servicios/validador_lectura.dart';
import 'package:sensor_track/shared/modelos/sensor_reading.dart';

import '../../helpers/repositorio_en_memoria.dart';

void main() {
  const validador = ValidadorLectura();

  Matcher rechazaCon(String fragmento) => throwsA(
    isA<AppException>()
        .having((e) => e.categoria, 'categoria', CategoriaError.validacion)
        .having((e) => e.mensaje, 'mensaje', contains(fragmento)),
  );

  SensorReading lectura({
    required TipoSensor tipo,
    double? x,
    double? y,
    double? z,
    double? lat,
    double? lon,
    double? precision,
    String capturadoPor = 'josue',
  }) => SensorReading(
    tipo: tipo,
    x: x,
    y: y,
    z: z,
    latitude: lat,
    longitude: lon,
    accuracy: precision,
    recordedAt: DateTime.utc(2026, 11, 25),
    capturadoPor: capturadoPor,
  );

  test('acepta lecturas válidas de los tres tipos', () {
    expect(() => validador.validar(acelerometro()), returnsNormally);
    expect(() => validador.validar(giroscopio()), returnsNormally);
    expect(() => validador.validar(gps()), returnsNormally);
    expect(
      () => validador.validar(gps(latitude: 90, longitude: -180, accuracy: 0)),
      returnsNormally,
    );
  });

  group('capturado_por', () {
    test('vacío pide configurar CAPTURADO_POR', () {
      expect(
        () => validador.validar(acelerometro(capturadoPor: '')),
        rechazaCon('Falta configurar CAPTURADO_POR'),
      );
    });

    for (final invalido in ['Josué', 'Josue', 'jo sue', 'j', '1josue']) {
      test('rechaza "$invalido"', () {
        expect(
          () => validador.validar(acelerometro(capturadoPor: invalido)),
          rechazaCon('minúsculas'),
        );
      });
    }
  });

  group('acelerómetro y giroscopio', () {
    test('requieren X, Y y Z', () {
      expect(
        () => validador.validar(
          lectura(tipo: TipoSensor.accelerometer, x: 1, y: 2),
        ),
        rechazaCon('X, Y y Z'),
      );
    });

    test('rechazan NaN e infinito', () {
      expect(
        () => validador.validar(acelerometro(x: double.nan)),
        rechazaCon('X, Y y Z'),
      );
      expect(
        () => validador.validar(
          lectura(tipo: TipoSensor.gyroscope, x: 1, y: double.infinity, z: 0),
        ),
        rechazaCon('giroscopio'),
      );
    });

    test('no deben traer datos de GPS', () {
      expect(
        () => validador.validar(
          lectura(tipo: TipoSensor.gyroscope, x: 1, y: 2, z: 3, lat: 1),
        ),
        rechazaCon('no debe incluir datos de GPS'),
      );
    });
  });

  group('GPS', () {
    test('requiere latitud, longitud y precisión', () {
      expect(
        () => validador.validar(lectura(tipo: TipoSensor.gps, lat: 1, lon: 2)),
        rechazaCon('latitud, longitud y precisión'),
      );
    });

    test('valida rangos', () {
      expect(
        () => validador.validar(gps(latitude: 90.1)),
        rechazaCon('latitud'),
      );
      expect(
        () => validador.validar(gps(longitude: -180.5)),
        rechazaCon('longitud'),
      );
      expect(
        () => validador.validar(gps(accuracy: -1)),
        rechazaCon('negativa'),
      );
    });

    test('no debe traer X, Y, Z', () {
      expect(
        () => validador.validar(
          lectura(tipo: TipoSensor.gps, lat: 1, lon: 2, precision: 3, z: 0),
        ),
        rechazaCon('X, Y, Z'),
      );
    });
  });
}
