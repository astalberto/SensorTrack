// Estado del guardado: inactivo / guardando / éxito / error.
// Responsable: Josué
//
// Frecuencia máxima: una medición guardada cada [RegistroEstado.intervaloMinimo].
// Evita registros duplicados por toques repetidos (prueba "Guardar varias
// veces seguidas" del plan de pruebas). Un guardado fallido no cuenta, para
// que se pueda reintentar enseguida.

import 'package:flutter/foundation.dart';

import '../../../core/errores/app_exception.dart';
import '../../../shared/datos/readings_repository.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../servicios/validador_lectura.dart';

enum EstadoGuardado { inactivo, guardando, exito, error }

class RegistroEstado extends ChangeNotifier {
  RegistroEstado(
    this._repositorio, {
    this.validador = const ValidadorLectura(),
    this.intervaloMinimo = intervaloPorDefecto,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  static const intervaloPorDefecto = Duration(seconds: 2);

  final ReadingsRepository _repositorio;
  final ValidadorLectura validador;
  final Duration intervaloMinimo;
  final DateTime Function() _reloj;

  EstadoGuardado estado = EstadoGuardado.inactivo;

  /// Resultado del último intento (éxito o error), listo para mostrar.
  String? mensaje;

  DateTime? _ultimoGuardado;
  bool _descartado = false;

  bool get guardando => estado == EstadoGuardado.guardando;

  /// Valida y guarda [lectura]. Devuelve `true` si quedó guardada.
  ///
  /// Nunca lanza: el resultado queda en [estado] y [mensaje]. Mientras hay un
  /// guardado en curso, las llamadas nuevas se ignoran y devuelven `false`.
  Future<bool> guardar(SensorReading? lectura) async {
    if (guardando) return false;
    if (lectura == null) {
      return _fallar('Todavía no hay datos del sensor para guardar.');
    }

    final inicio = _reloj();
    final ultimo = _ultimoGuardado;
    if (ultimo != null) {
      final espera = intervaloMinimo - inicio.difference(ultimo);
      if (espera > Duration.zero) {
        final segundos = (espera.inMilliseconds / 1000).ceil();
        return _fallar('Espera $segundos s antes de guardar otra medición.');
      }
    }

    try {
      validador.validar(lectura);
    } on AppException catch (e) {
      return _fallar(e.mensaje);
    }

    estado = EstadoGuardado.guardando;
    mensaje = null;
    _notificar();

    try {
      await _repositorio.guardar(lectura);
    } on AppException catch (e) {
      return _fallar(e.mensaje);
    } catch (e) {
      debugPrint('RegistroEstado: error inesperado al guardar: $e');
      return _fallar('Ocurrió un error inesperado al guardar la medición.');
    }

    _ultimoGuardado = inicio;
    estado = EstadoGuardado.exito;
    mensaje = 'Medición guardada.';
    _notificar();
    return true;
  }

  bool _fallar(String texto) {
    estado = EstadoGuardado.error;
    mensaje = texto;
    _notificar();
    return false;
  }

  // El guardado puede terminar después de salir de la pantalla.
  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
