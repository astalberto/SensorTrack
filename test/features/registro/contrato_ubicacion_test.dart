// Contrato entre `ubicacion` (Cody) y `registro` (Josué): la lectura GPS que
// arma UbicacionEstado.lecturaActual debe pasar la validación de registro y
// guardarse. Si alguno cambia su lado, esta prueba falla antes de la demo.

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/features/registro/estado/registro_estado.dart';
import 'package:sensor_track/features/registro/servicios/validador_lectura.dart';
import 'package:sensor_track/features/ubicacion/estado/ubicacion_estado.dart';
import 'package:sensor_track/features/ubicacion/servicios/location_service.dart';

import '../../helpers/repositorio_en_memoria.dart';

/// GPS que siempre entrega la misma posición.
class _GpsFijo extends LocationService {
  _GpsFijo({this.precision = 6.5});

  final double precision;

  @override
  Future<Position> ubicacionActual() async => Position(
    latitude: -2.170998,
    longitude: -79.922359,
    accuracy: precision,
    timestamp: DateTime.utc(2026, 11, 25, 15, 30),
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  setUp(UbicacionEstado.reiniciarPolitica);

  Future<UbicacionEstado> capturar(
    String capturadoPor, {
    double precision = 6.5,
  }) async {
    final ubicacion = UbicacionEstado(
      _GpsFijo(precision: precision),
      capturadoPor: capturadoPor,
    )..aceptarPolitica();
    await ubicacion.capturar();
    return ubicacion;
  }

  test('la lectura de GPS se valida y se guarda', () async {
    final ubicacion = await capturar('cody');
    final lectura = ubicacion.lecturaActual();

    expect(lectura, isNotNull);
    expect(() => const ValidadorLectura().validar(lectura!), returnsNormally);

    final repo = RepositorioEnMemoria();
    final registro = RegistroEstado(repo);
    expect(await registro.guardar(lectura), isTrue);

    final guardada = repo.lecturas.single;
    expect(guardada.tipo, TipoSensor.gps);
    expect(guardada.latitude, -2.170998);
    expect(guardada.accuracy, 6.5);
    expect(guardada.x, isNull);
    expect(guardada.capturadoPor, 'cody');

    // Lo que viaja a Supabase: solo columnas de GPS y hora en UTC.
    final fila = guardada.toMap();
    expect(fila['x'], isNull);
    expect(fila['recorded_at'], '2026-11-25T15:30:00.000Z');

    registro.dispose();
    ubicacion.dispose();
  });

  test('precisión negativa (inválida en iOS) no se guarda', () async {
    final ubicacion = await capturar('cody', precision: -1);
    final registro = RegistroEstado(RepositorioEnMemoria());

    expect(await registro.guardar(ubicacion.lecturaActual()), isFalse);
    expect(registro.mensaje, contains('precisión'));

    registro.dispose();
    ubicacion.dispose();
  });

  test('con CAPTURADO_POR en otro formato, registro lo explica', () async {
    final ubicacion = await capturar('Cody');
    final registro = RegistroEstado(RepositorioEnMemoria());

    expect(await registro.guardar(ubicacion.lecturaActual()), isFalse);
    expect(registro.mensaje, contains('minúsculas'));

    registro.dispose();
    ubicacion.dispose();
  });
}
