import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/features/estadisticas/estadisticas.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/shared/modelos/sensor_reading.dart';

import 'repositorio_falso.dart';

final _t0 = DateTime.utc(2026, 11, 25, 10);

SensorReading acel(int seg, double x, double y, double z) => SensorReading(
  tipo: TipoSensor.accelerometer,
  x: x,
  y: y,
  z: z,
  recordedAt: _t0.add(Duration(seconds: seg)),
  capturadoPor: 'Cody',
);

SensorReading gps(int seg, double lat, double lon) => SensorReading(
  tipo: TipoSensor.gps,
  latitude: lat,
  longitude: lon,
  accuracy: 5,
  recordedAt: _t0.add(Duration(seconds: seg)),
  capturadoPor: 'Cody',
);

void main() {
  group('calcularExtremos', () {
    test('devuelve mínimo y máximo por eje', () {
      final e = EstadisticasCalculo.calcularExtremos([
        acel(0, 1, -2, 9.8),
        acel(1, -3, 4, 9.5),
        acel(2, 2, 0, 10.1),
      ])!;
      expect(e.x.minimo, -3);
      expect(e.x.maximo, 2);
      expect(e.y.minimo, -2);
      expect(e.y.maximo, 4);
      expect(e.z.minimo, 9.5);
      expect(e.z.maximo, 10.1);
      expect(e.muestras, 3);
    });

    test('devuelve null sin lecturas', () {
      expect(EstadisticasCalculo.calcularExtremos([]), isNull);
    });
  });

  test('resumen: total, conteo por sensor y última ubicación', () async {
    final repo = RepositorioFalso([
      acel(0, 1, 1, 1),
      acel(1, 2, 2, 2),
      gps(5, -2.1, -79.9),
      gps(9, -2.2, -79.8),
      SensorReading(
        tipo: TipoSensor.gyroscope,
        x: 0,
        y: 0,
        z: 0,
        recordedAt: _t0,
        capturadoPor: 'Alberto',
      ),
    ]);

    final r = await EstadisticasCalculo(repo).resumen();

    expect(r.total, 5);
    expect(r.conteo(TipoSensor.accelerometer), 2);
    expect(r.conteo(TipoSensor.gyroscope), 1);
    expect(r.conteo(TipoSensor.gps), 2);
    expect(r.ultimaUbicacion!.latitude, -2.2);
    expect(r.acelerometro!.x.maximo, 2);
  });

  test('máximos y mínimos recorren todas las páginas', () async {
    final lecturas = [
      for (var i = 0; i < EstadisticasCalculo.tamanoPagina + 10; i++)
        acel(i, i.toDouble(), 0, 0),
    ];
    final r = await EstadisticasCalculo(RepositorioFalso(lecturas)).resumen();

    expect(r.acelerometro!.muestras, lecturas.length);
    expect(r.acelerometro!.x.maximo, lecturas.length - 1);
  });

  test('evolución viene en orden temporal ascendente', () async {
    final repo = RepositorioFalso([
      acel(3, 0, 0, 0),
      acel(1, 0, 0, 0),
      acel(2, 0, 0, 0),
    ]);
    final serie = await EstadisticasCalculo(repo)
        .evolucion(TipoSensor.accelerometer);

    expect(serie.map((l) => l.recordedAt.second), [1, 2, 3]);
  });

  testWidgets('la pantalla muestra todas las secciones', (tester) async {
    final repo = RepositorioFalso([
      acel(0, 1, -2, 9.8),
      acel(1, -3, 4, 9.5),
      acel(2, 2, 0, 10.1),
      gps(5, -2.123456, -79.9),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: EstadisticasPage(
          crearEstado: () => EstadisticasEstado(EstadisticasCalculo(repo)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget); // total
    expect(find.text('-3.000'), findsOneWidget); // mínimo X
    expect(find.text('Latitud: -2.123456'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(LineChart), 200);
    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('el estado muestra el mensaje de error de conexión', () async {
    final estado = EstadisticasEstado(
      EstadisticasCalculo(RepositorioFalso([], fallar: true)),
    );
    await estado.cargar();

    expect(estado.resumen, isNull);
    expect(estado.mensajeError, 'Sin conexión.');
    expect(estado.cargando, isFalse);
  });
}
