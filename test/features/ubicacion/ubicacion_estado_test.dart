import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/features/ubicacion/estado/ubicacion_estado.dart';
import 'package:sensor_track/features/ubicacion/servicios/location_service.dart';

class ServicioFalso extends LocationService {
  ServicioFalso({this.error});

  final UbicacionException? error;
  int llamadas = 0;

  @override
  Future<Position> ubicacionActual() async {
    llamadas++;
    if (error != null) throw error!;
    return Position(
      latitude: -2.17,
      longitude: -79.92,
      accuracy: 4.5,
      timestamp: DateTime.utc(2026, 11, 25, 12),
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  setUp(UbicacionEstado.reiniciarPolitica);

  test('no captura sin aceptar la política', () async {
    final servicio = ServicioFalso();
    final estado = UbicacionEstado(servicio, capturadoPor: 'Cody');

    await estado.capturar();

    expect(servicio.llamadas, 0);
    expect(estado.lecturaActual(), isNull);
  });

  test('con política aceptada genera una lectura GPS', () async {
    final estado = UbicacionEstado(ServicioFalso(), capturadoPor: 'Cody')
      ..aceptarPolitica();

    await estado.capturar();
    final l = estado.lecturaActual()!;

    expect(estado.estado, EstadoUbicacion.listo);
    expect(l.tipo, TipoSensor.gps);
    expect(l.latitude, -2.17);
    expect(l.longitude, -79.92);
    expect(l.accuracy, 4.5);
    expect(l.x, isNull);
    expect(l.capturadoPor, 'Cody');
  });

  test('permiso bloqueado ofrece abrir ajustes', () async {
    final estado = UbicacionEstado(
      ServicioFalso(
        error: const UbicacionException(
          ProblemaUbicacion.permisoDenegadoSiempre,
          CategoriaError.permiso,
          'Bloqueado',
        ),
      ),
    )..aceptarPolitica();

    await estado.capturar();

    expect(estado.estado, EstadoUbicacion.error);
    expect(estado.error!.mensaje, 'Bloqueado');
    expect(estado.puedeAbrirAjustes, isTrue);
  });

  test('sin señal permite reintentar pero no abre ajustes', () async {
    final estado = UbicacionEstado(
      ServicioFalso(
        error: const UbicacionException(
          ProblemaUbicacion.sinSenal,
          CategoriaError.sensor,
          'Sin señal',
        ),
      ),
    )..aceptarPolitica();

    await estado.capturar();

    expect(estado.estado, EstadoUbicacion.error);
    expect(estado.puedeAbrirAjustes, isFalse);
  });
}
