// Implementación de ReadingsRepository sobre la tabla `sensor_readings`.
// Responsable: Josué
//
// Todos los errores de red y de Supabase se traducen a AppException con un
// mensaje en español; las pantallas nunca ven PostgrestException.

import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constantes/tipos_sensor.dart';
import '../../core/errores/app_exception.dart';
import '../modelos/sensor_reading.dart';
import 'readings_repository.dart';
import 'supabase_service.dart';

class SupabaseReadingsRepository implements ReadingsRepository {
  /// [cliente] solo se pasa en pruebas; por defecto usa el cliente global
  /// de [SupabaseService].
  SupabaseReadingsRepository({
    SupabaseClient? cliente,
    this.tiempoMaximo = const Duration(seconds: 15),
  }) : _clienteInyectado = cliente;

  static const tabla = SupabaseService.tablaLecturas;

  final SupabaseClient? _clienteInyectado;

  /// Tiempo máximo de espera por operación, incluidos los reintentos
  /// automáticos de la librería.
  final Duration tiempoMaximo;

  SupabaseClient get _cliente => _clienteInyectado ?? SupabaseService.cliente;

  @override
  Future<void> guardar(SensorReading lectura) => _ejecutar(() async {
    await _cliente.from(tabla).insert(lectura.toMap());
  });

  @override
  Future<List<SensorReading>> listar({
    TipoSensor? tipo,
    String? capturadoPor,
    int limite = 50,
    int desplazamiento = 0,
  }) async {
    if (limite <= 0) return const [];
    final filas = await _ejecutar(() {
      var consulta = _cliente.from(tabla).select();
      if (tipo != null) consulta = consulta.eq('sensor_type', tipo.valorBd);
      if (capturadoPor != null) {
        consulta = consulta.eq('capturado_por', capturadoPor);
      }
      return consulta
          .order('recorded_at', ascending: false)
          // Desempate estable para que la paginación no repita ni salte filas.
          .order('id', ascending: false)
          .range(desplazamiento, desplazamiento + limite - 1);
    });
    return filas.map(SensorReading.fromMap).toList();
  }

  @override
  Future<SensorReading?> obtenerPorId(int id) async {
    final fila = await _ejecutar(
      () => _cliente.from(tabla).select().eq('id', id).maybeSingle(),
    );
    return fila == null ? null : SensorReading.fromMap(fila);
  }

  @override
  Future<Map<TipoSensor, int>> contarPorTipo({String? capturadoPor}) async {
    const tipos = TipoSensor.values;
    final conteos = await _ejecutar(
      () => Future.wait([for (final t in tipos) _contar(t, capturadoPor)]),
    );
    return {for (var i = 0; i < tipos.length; i++) tipos[i]: conteos[i]};
  }

  /// Conteo exacto sin descargar filas (petición HEAD).
  Future<int> _contar(TipoSensor tipo, String? capturadoPor) {
    var consulta = _cliente
        .from(tabla)
        .count(CountOption.exact)
        .eq('sensor_type', tipo.valorBd);
    if (capturadoPor != null) {
      consulta = consulta.eq('capturado_por', capturadoPor);
    }
    return consulta;
  }

  Future<T> _ejecutar<T>(Future<T> Function() operacion) async {
    try {
      return await operacion().timeout(tiempoMaximo);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw _traducir(e);
    } on TimeoutException catch (e) {
      throw AppException(
        CategoriaError.conexion,
        'La base de datos tardó demasiado en responder. '
        'Revisa tu conexión a internet.',
        causa: e,
      );
    } on JsonUnsupportedObjectError catch (e) {
      // NaN o infinito no se pueden enviar como JSON.
      throw AppException(
        CategoriaError.validacion,
        'La lectura tiene valores numéricos no válidos.',
        causa: e,
      );
    } on Exception catch (e) {
      // Sin internet, DNS, TLS, etc. (ClientException, SocketException...).
      throw AppException(
        CategoriaError.conexion,
        'No se pudo conectar con la base de datos. '
        'Revisa tu conexión a internet.',
        causa: e,
      );
    }
  }

  /// Códigos de PostgreSQL y PostgREST que la app sabe explicar.
  static AppException _traducir(PostgrestException e) {
    final (categoria, mensaje) = switch (e.code) {
      // check_violation, not_null_violation, tipo de dato inválido.
      '23514' || '23502' || '22P02' => (
        CategoriaError.validacion,
        'La base de datos rechazó la lectura: los campos no corresponden '
            'al tipo de sensor o CAPTURADO_POR no es válido.',
      ),
      // insufficient_privilege: RLS o falta de GRANT.
      '42501' => (
        CategoriaError.permiso,
        'La base de datos no permite esta operación. '
            'Revisa que la migración esté aplicada.',
      ),
      // Tabla inexistente (PostgreSQL / caché de esquema de PostgREST).
      '42P01' || 'PGRST205' => (
        CategoriaError.conexion,
        'La tabla sensor_readings no existe. Aplica la migración inicial.',
      ),
      // Clave pública inválida o vencida.
      '401' || 'PGRST301' => (
        CategoriaError.conexion,
        'La clave de Supabase no es válida. Revisa SUPABASE_KEY.',
      ),
      _ => (CategoriaError.conexion, 'Error de la base de datos: ${e.message}'),
    };
    return AppException(categoria, mensaje, causa: e);
  }
}
