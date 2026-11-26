import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/features/sensores/estado/sensores_estado.dart';
import 'package:sensor_track/features/sensores/sensores.dart';

import 'fuente_falsa.dart';

void main() {
  late FuenteFalsa acelerometro;
  late FuenteFalsa giroscopio;

  setUp(() {
    acelerometro = FuenteFalsa();
    giroscopio = FuenteFalsa();
  });

  Widget app() => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SensoresPage(
                crearEstado: () => SensoresEstado(
                  SensorService(
                    acelerometro: acelerometro.call,
                    giroscopio: giroscopio.call,
                  ),
                  capturadoPor: 'Prueba',
                ),
              ),
            ),
          ),
          child: const Text('Abrir sensores'),
        ),
      ),
    ),
  );

  Future<void> abrir(WidgetTester tester) async {
    await tester.tap(find.text('Abrir sensores'));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra X, Y, Z en tiempo real al iniciar', (tester) async {
    await tester.pumpWidget(app());
    await abrir(tester);
    expect(find.text('Pulsa Iniciar para leer el sensor.'), findsOneWidget);

    await tester.tap(find.text('Iniciar'));
    await tester.pump();
    acelerometro.emitir(1.5, -0.25, 9.81);
    await tester.pump();

    expect(find.text('1.500'), findsOneWidget);
    expect(find.text('-0.250'), findsOneWidget);
    expect(find.text('9.810'), findsOneWidget);
    expect(find.text('Detener'), findsOneWidget);
  });

  testWidgets('salir y volver no deja suscripciones activas', (tester) async {
    await tester.pumpWidget(app());
    await abrir(tester);
    await tester.tap(find.text('Iniciar'));
    await tester.pump();
    expect(acelerometro.hayOyentes, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(acelerometro.hayOyentes, isFalse);

    await abrir(tester);
    expect(acelerometro.hayOyentes, isFalse, reason: 'no arranca sola');
  });

  testWidgets('el selector cambia al giroscopio con su unidad', (tester) async {
    await tester.pumpWidget(app());
    await abrir(tester);

    await tester.tap(find.text('Giroscopio'));
    await tester.pump();
    await tester.tap(find.text('Iniciar'));
    await tester.pump();
    giroscopio.emitir(0.5, 0, 0);
    await tester.pump();

    expect(giroscopio.hayOyentes, isTrue);
    expect(acelerometro.controladores, isEmpty);
    expect(find.text('rad/s'), findsNWidgets(3));
  });

  testWidgets('muestra el error del sensor y permite reintentar', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await abrir(tester);
    await tester.tap(find.text('Iniciar'));
    await tester.pump();

    acelerometro.ultimo.addError(Exception('NO_SENSOR'));
    await tester.pump();

    expect(
      find.text('El acelerómetro no está disponible en este dispositivo.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
