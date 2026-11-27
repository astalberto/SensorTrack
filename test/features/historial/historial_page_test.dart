import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/features/historial/estado/detalle_registro_estado.dart';
import 'package:sensor_track/features/historial/estado/historial_estado.dart';
import 'package:sensor_track/features/historial/historial.dart';
import 'package:sensor_track/features/historial/servicios/historial_consulta.dart';
import 'package:sensor_track/features/historial/widgets/registro_tile.dart';

import '../../helpers/repositorio_en_memoria.dart';

void main() {
  Future<void> montar(WidgetTester tester, RepositorioEnMemoria repo) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HistorialPage(
          crearEstado: () => HistorialEstado(HistorialConsulta(repo)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra registros de los tres integrantes', (tester) async {
    final repo = RepositorioEnMemoria([
      acelerometro(capturadoPor: 'josue'),
      giroscopio(capturadoPor: 'alberto'),
      gps(capturadoPor: 'cody'),
    ]);
    await montar(tester, repo);

    expect(find.byType(RegistroTile), findsNWidgets(3));
    for (final nombre in ['josue', 'alberto', 'cody']) {
      expect(find.textContaining('· $nombre'), findsOneWidget);
    }
    expect(find.text('No hay más registros'), findsOneWidget);
  });

  testWidgets('el filtro GPS deja solo lecturas de GPS', (tester) async {
    final repo = RepositorioEnMemoria([acelerometro(), giroscopio(), gps()]);
    await montar(tester, repo);

    await tester.tap(find.widgetWithText(ChoiceChip, 'GPS'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistroTile), findsOneWidget);
    expect(find.textContaining('Lat -0.18065'), findsOneWidget);
  });

  testWidgets('lista vacía', (tester) async {
    await montar(tester, RepositorioEnMemoria());
    expect(find.text('Todavía no hay registros guardados.'), findsOneWidget);
  });

  testWidgets('error de conexión con botón Reintentar', (tester) async {
    final repo = RepositorioEnMemoria([gps()])
      ..error = const AppException(
        CategoriaError.conexion,
        'No se pudo conectar con la base de datos.',
      );
    await montar(tester, repo);

    expect(
      find.text('No se pudo conectar con la base de datos.'),
      findsOneWidget,
    );

    repo.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistroTile), findsOneWidget);
  });

  testWidgets('al tocar un registro abre su detalle completo', (tester) async {
    final repo = RepositorioEnMemoria([
      gps(id: 42, latitude: -0.180653, longitude: -78.467834, accuracy: 8.5),
    ]);
    await montar(tester, repo);

    await tester.tap(find.byType(RegistroTile));
    await tester.pumpAndSettle();

    expect(find.text('Registro #42'), findsOneWidget);
    expect(find.text('-0.180653°'), findsOneWidget);
    expect(find.text('-78.467834°'), findsOneWidget);
    expect(find.text('± 8.5 m'), findsOneWidget);
    expect(find.text('cody'), findsOneWidget);
    expect(find.text('gps'), findsOneWidget);
    expect(find.text('2026-11-25T12:00:00.000Z'), findsOneWidget);
  });

  testWidgets('detalle de acelerómetro muestra ejes con unidad', (
    tester,
  ) async {
    final repo = RepositorioEnMemoria([acelerometro(id: 7, x: 1.5)]);
    await tester.pumpWidget(
      MaterialApp(
        home: DetalleRegistroPage(
          id: 7,
          crearEstado: () => DetalleRegistroEstado(HistorialConsulta(repo), 7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.5000 m/s²'), findsOneWidget);
    expect(find.text('Eje Z'), findsOneWidget);
  });

  testWidgets('detalle de un id inexistente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetalleRegistroPage(
          id: 999,
          crearEstado: () => DetalleRegistroEstado(
            HistorialConsulta(RepositorioEnMemoria()),
            999,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No existe el registro #999'), findsOneWidget);
  });
}
