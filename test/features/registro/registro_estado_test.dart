import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/core/errores/app_exception.dart';
import 'package:sensor_track/features/registro/estado/registro_estado.dart';

import '../../helpers/repositorio_en_memoria.dart';

void main() {
  late RepositorioEnMemoria repo;
  late DateTime ahora;
  late RegistroEstado estado;

  setUp(() {
    repo = RepositorioEnMemoria();
    ahora = DateTime(2026, 11, 25, 10);
    estado = RegistroEstado(repo, reloj: () => ahora);
  });

  tearDown(() => estado.dispose());

  test('guarda una lectura válida', () async {
    expect(await estado.guardar(acelerometro()), isTrue);
    expect(estado.estado, EstadoGuardado.exito);
    expect(estado.mensaje, 'Medición guardada.');
    expect(repo.lecturas, hasLength(1));
  });

  test('sin lectura avisa que no hay datos', () async {
    expect(await estado.guardar(null), isFalse);
    expect(estado.estado, EstadoGuardado.error);
    expect(estado.mensaje, contains('no hay datos'));
    expect(repo.llamadasGuardar, 0);
  });

  test('una lectura inválida no llega al repositorio', () async {
    expect(await estado.guardar(acelerometro(capturadoPor: '')), isFalse);
    expect(estado.mensaje, contains('CAPTURADO_POR'));
    expect(repo.llamadasGuardar, 0);
  });

  test('muestra el mensaje de AppException del repositorio', () async {
    repo.error = const AppException(
      CategoriaError.conexion,
      'No se pudo conectar con la base de datos.',
    );
    expect(await estado.guardar(gps()), isFalse);
    expect(estado.estado, EstadoGuardado.error);
    expect(estado.mensaje, 'No se pudo conectar con la base de datos.');
  });

  group('frecuencia máxima', () {
    test('rechaza un segundo guardado antes del intervalo', () async {
      await estado.guardar(acelerometro());

      ahora = ahora.add(const Duration(milliseconds: 800));
      expect(await estado.guardar(acelerometro()), isFalse);
      expect(estado.mensaje, 'Espera 2 s antes de guardar otra medición.');

      ahora = ahora.add(const Duration(milliseconds: 700));
      expect(await estado.guardar(acelerometro()), isFalse);
      expect(estado.mensaje, 'Espera 1 s antes de guardar otra medición.');

      expect(repo.lecturas, hasLength(1));
    });

    test('permite guardar al cumplirse el intervalo', () async {
      await estado.guardar(acelerometro());
      ahora = ahora.add(RegistroEstado.intervaloPorDefecto);
      expect(await estado.guardar(acelerometro()), isTrue);
      expect(repo.lecturas, hasLength(2));
    });

    test('un guardado fallido no bloquea el reintento', () async {
      repo.error = const AppException(CategoriaError.conexion, 'sin red');
      await estado.guardar(acelerometro());

      repo.error = null;
      expect(await estado.guardar(acelerometro()), isTrue);
      expect(repo.lecturas, hasLength(1));
    });

    test('ignora toques mientras hay un guardado en curso', () async {
      repo.pausa = Completer<void>();
      final primero = estado.guardar(acelerometro());
      expect(estado.estado, EstadoGuardado.guardando);

      expect(await estado.guardar(acelerometro()), isFalse);

      repo.pausa!.complete();
      expect(await primero, isTrue);
      expect(repo.llamadasGuardar, 1);
    });
  });

  test('no notifica después de dispose', () async {
    final otro = RegistroEstado(repo);
    repo.pausa = Completer<void>();
    final pendiente = otro.guardar(acelerometro());
    otro.dispose();
    repo.pausa!.complete();
    // No debe lanzar "used after being disposed".
    expect(await pendiente, isTrue);
  });
}
