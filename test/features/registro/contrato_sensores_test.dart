// Contrato entre `sensores` (Alberto) y `registro` (Josué): la lectura que
// arma SensoresEstado.lecturaActual debe pasar la validación de registro y
// guardarse. Si alguno cambia su lado, esta prueba falla antes de la demo.

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/core/constantes/tipos_sensor.dart';
import 'package:sensor_track/features/registro/estado/registro_estado.dart';
import 'package:sensor_track/features/registro/servicios/validador_lectura.dart';
import 'package:sensor_track/features/sensores/estado/sensores_estado.dart';
import 'package:sensor_track/features/sensores/servicios/sensor_service.dart';

import '../../helpers/repositorio_en_memoria.dart';
import '../sensores/fuente_falsa.dart';

void main() {
  late FuenteFalsa acelerometro;
  late FuenteFalsa giroscopio;
  late SensoresEstado sensores;

  SensoresEstado crearSensores(String capturadoPor) => SensoresEstado(
    SensorService(acelerometro: acelerometro.call, giroscopio: giroscopio.call),
    capturadoPor: capturadoPor,
  );

  setUp(() {
    acelerometro = FuenteFalsa();
    giroscopio = FuenteFalsa();
  });

  tearDown(() => sensores.dispose());

  for (final tipo in [TipoSensor.accelerometer, TipoSensor.gyroscope]) {
    test('la lectura de ${tipo.etiqueta} se valida y se guarda', () async {
      sensores = crearSensores('alberto')..seleccionarSensor(tipo);
      sensores.iniciar();
      final fuente = tipo == TipoSensor.gyroscope ? giroscopio : acelerometro;
      fuente.emitir(0.12, -9.81, 0.5);
      await vaciarCola();

      final lectura = sensores.lecturaActual();
      expect(lectura, isNotNull);
      expect(() => const ValidadorLectura().validar(lectura!), returnsNormally);

      final repo = RepositorioEnMemoria();
      final registro = RegistroEstado(repo);
      expect(await registro.guardar(lectura), isTrue);
      expect(repo.lecturas.single.tipo, tipo);
      expect(repo.lecturas.single.capturadoPor, 'alberto');
      registro.dispose();
    });
  }

  test('con CAPTURADO_POR en otro formato, registro lo explica', () async {
    sensores = crearSensores('Alberto')..iniciar();
    acelerometro.emitir(1, 2, 3);
    await vaciarCola();

    final registro = RegistroEstado(RepositorioEnMemoria());
    expect(await registro.guardar(sensores.lecturaActual()), isFalse);
    expect(registro.mensaje, contains('minúsculas'));
    registro.dispose();
  });
}
