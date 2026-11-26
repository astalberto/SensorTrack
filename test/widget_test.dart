import 'package:flutter_test/flutter_test.dart';

import 'package:sensor_track/app/app.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/features/home/home.dart';

void main() {
  testWidgets('La app arranca en Home con conexión, sensores y menú', (
    tester,
  ) async {
    await tester.pumpWidget(
      SensorTrackApp(
        crearHomeEstado: () => HomeEstado(
          configurado: true,
          comprobarConexion: () async => true,
          detectarSensores: () async => const [
            DisponibilidadSensor(
              TipoSensor.accelerometer,
              disponible: true,
              detalle: 'Disponible',
            ),
          ],
          capturadoPor: 'Prueba',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SensorTrack'), findsOneWidget);
    expect(find.text('Conectado a Supabase'), findsOneWidget);
    expect(find.text('Capturas a nombre de: Prueba'), findsOneWidget);
    expect(find.text('Acelerómetro'), findsOneWidget);
    expect(find.text('Sensores', skipOffstage: false), findsOneWidget);
    expect(find.text('Historial', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Sin conexión muestra el aviso y el botón Reintentar', (
    tester,
  ) async {
    await tester.pumpWidget(
      SensorTrackApp(
        crearHomeEstado: () => HomeEstado(
          configurado: true,
          comprobarConexion: () async => false,
          detectarSensores: () async => const [],
          capturadoPor: '',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(
      find.text('Falta CAPTURADO_POR: no se podrán guardar mediciones.'),
      findsOneWidget,
    );
  });
}
