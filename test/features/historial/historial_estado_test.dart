import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/features/historial/estado/historial_estado.dart';
import 'package:sensor_track/features/historial/servicios/historial_consulta.dart';
import 'package:sensor_track/shared/modelos/sensor_reading.dart';

import '../../helpers/repositorio_en_memoria.dart';

/// [n] lecturas de acelerómetro, una por minuto; la última es la más reciente.
List<SensorReading> lecturas(int n, {String capturadoPor = 'josue'}) => [
  for (var i = 0; i < n; i++)
    acelerometro(
      fecha: DateTime.utc(2026, 11, 25).add(Duration(minutes: i)),
      capturadoPor: capturadoPor,
    ),
];

void main() {
  late RepositorioEnMemoria repo;
  late HistorialEstado estado;

  HistorialEstado crear({String capturadoPorPropio = 'josue'}) =>
      HistorialEstado(
        HistorialConsulta(repo),
        capturadoPorPropio: capturadoPorPropio,
      );

  tearDown(() => estado.dispose());

  test('pagina de 20 en 20, más recientes primero', () async {
    repo = RepositorioEnMemoria(lecturas(45));
    estado = crear();

    await estado.cargar();
    expect(estado.registros, hasLength(20));
    expect(estado.hayMas, isTrue);
    expect(
      estado.registros.first.recordedAt.isAfter(
        estado.registros.last.recordedAt,
      ),
      isTrue,
    );

    await estado.cargarMas();
    expect(estado.registros, hasLength(40));

    await estado.cargarMas();
    expect(estado.registros, hasLength(45));
    expect(estado.hayMas, isFalse);

    final llamadas = repo.llamadasListar;
    await estado.cargarMas();
    expect(repo.llamadasListar, llamadas, reason: 'no hay más páginas');
  });

  test('filtra por tipo', () async {
    repo = RepositorioEnMemoria([...lecturas(3), gps(), giroscopio()]);
    estado = crear();
    await estado.cargar();
    expect(estado.registros, hasLength(5));

    await estado.filtrarPorTipo(TipoSensor.gps);
    expect(estado.registros.map((r) => r.tipo), [TipoSensor.gps]);
    expect(estado.hayFiltros, isTrue);

    await estado.filtrarPorTipo(null);
    expect(estado.registros, hasLength(5));
  });

  test('"Solo míos" usa CAPTURADO_POR', () async {
    repo = RepositorioEnMemoria([
      ...lecturas(2, capturadoPor: 'josue'),
      ...lecturas(3, capturadoPor: 'cody'),
    ]);
    estado = crear(capturadoPorPropio: 'josue');
    await estado.cargar();

    await estado.cambiarSoloMios(true);
    expect(estado.registros.map((r) => r.capturadoPor).toSet(), {'josue'});
    expect(estado.registros, hasLength(2));
  });

  test('sin CAPTURADO_POR no ofrece "Solo míos"', () async {
    repo = RepositorioEnMemoria(lecturas(2));
    estado = crear(capturadoPorPropio: '');
    expect(estado.puedeFiltrarMios, isFalse);

    await estado.cambiarSoloMios(true);
    expect(estado.soloMios, isFalse);
  });

  test('error al cargar muestra mensaje y permite reintentar', () async {
    repo = RepositorioEnMemoria(lecturas(3))
      ..error = const AppException(CategoriaError.conexion, 'Sin conexión.');
    estado = crear();

    await estado.cargar();
    expect(estado.mensajeError, 'Sin conexión.');
    expect(estado.registros, isEmpty);
    expect(estado.cargando, isFalse);

    repo.error = null;
    await estado.cargar();
    expect(estado.mensajeError, isNull);
    expect(estado.registros, hasLength(3));
  });

  test('error al cargar más conserva la lista', () async {
    repo = RepositorioEnMemoria(lecturas(30));
    estado = crear();
    await estado.cargar();

    repo.error = const AppException(CategoriaError.conexion, 'Sin conexión.');
    await estado.cargarMas();
    expect(estado.errorAlCargarMas, 'Sin conexión.');
    expect(estado.registros, hasLength(20));

    // El scroll no reintenta solo; hace falta el botón.
    repo.error = null;
    await estado.cargarMas();
    expect(estado.registros, hasLength(20));

    await estado.reintentarCargarMas();
    expect(estado.errorAlCargarMas, isNull);
    expect(estado.registros, hasLength(30));
  });

  test('descarta la respuesta de un filtro anterior', () async {
    repo = RepositorioEnMemoria([...lecturas(3), gps()]);
    estado = crear();

    repo.pausa = Completer<void>();
    final todos = estado.cargar();
    final soloGps = estado.filtrarPorTipo(TipoSensor.gps);
    repo.pausa!.complete();
    await Future.wait([todos, soloGps]);

    expect(estado.registros.map((r) => r.tipo), [TipoSensor.gps]);
    expect(estado.cargando, isFalse);
  });

  test('no repite registros si llegan filas nuevas entre páginas', () async {
    repo = RepositorioEnMemoria(lecturas(25));
    estado = crear();
    await estado.cargar();

    // Otro integrante guarda una lectura más reciente: el desplazamiento se
    // corre una posición.
    await repo.guardar(acelerometro(fecha: DateTime.utc(2026, 12)));
    await estado.cargarMas();

    final ids = estado.registros.map((r) => r.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, hasLength(25));
  });
}
