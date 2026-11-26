import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/features/registro/estado/registro_estado.dart';
import 'package:sensor_track/features/registro/registro.dart';
import 'package:sensor_track/shared/modelos/sensor_reading.dart';

import '../../helpers/repositorio_en_memoria.dart';

void main() {
  late RepositorioEnMemoria repo;

  setUp(() => repo = RepositorioEnMemoria());

  Future<void> montar(
    WidgetTester tester, {
    SensorReading? Function()? obtenerLectura,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        floatingActionButton: GuardarMedicionButton(
          obtenerLectura: obtenerLectura ?? () => acelerometro(),
          crearEstado: () => RegistroEstado(repo),
        ),
      ),
    ),
  );

  testWidgets('guarda y muestra confirmación', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Guardar medición'));
    await tester.pump();

    expect(find.text('Medición guardada.'), findsOneWidget);
    expect(repo.lecturas, hasLength(1));
  });

  testWidgets('muestra "Guardando…" mientras espera a la base', (tester) async {
    repo.pausa = Completer<void>();
    await montar(tester);

    await tester.tap(find.text('Guardar medición'));
    await tester.pump();
    expect(find.text('Guardando…'), findsOneWidget);

    // Un segundo toque mientras guarda no hace nada.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    repo.pausa!.complete();
    await tester.pump();
    await tester.pump();

    expect(find.text('Guardar medición'), findsOneWidget);
    expect(find.text('Medición guardada.'), findsOneWidget);
    expect(repo.llamadasGuardar, 1);
  });

  testWidgets('sin datos del sensor avisa y no guarda', (tester) async {
    await montar(tester, obtenerLectura: () => null);

    await tester.tap(find.text('Guardar medición'));
    await tester.pump();

    expect(
      find.text('Todavía no hay datos del sensor para guardar.'),
      findsOneWidget,
    );
    expect(repo.llamadasGuardar, 0);
  });

  testWidgets('sin conexión muestra el error y la app sigue', (tester) async {
    repo.error = const AppException(
      CategoriaError.conexion,
      'No se pudo conectar con la base de datos. Revisa tu conexión a internet.',
    );
    await montar(tester);

    await tester.tap(find.text('Guardar medición'));
    await tester.pump();

    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
    expect(find.text('Guardar medición'), findsOneWidget);
  });
}
