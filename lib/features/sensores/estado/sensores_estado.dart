// Estado de la pantalla de sensores: suscripción, frecuencia y último valor.
// Responsable: Alberto

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/constantes/tipos_sensor.dart';
import '../../../core/errores/app_exception.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../servicios/sensor_service.dart';

class SensoresEstado extends ChangeNotifier {
  SensoresEstado(this._servicio, {String? capturadoPor})
    : _capturadoPor = capturadoPor ?? SupabaseConfig.capturadoPor;

  /// Sensores que maneja esta feature. El GPS es de `ubicacion`.
  static const sensores = [TipoSensor.accelerometer, TipoSensor.gyroscope];

  final SensorService _servicio;
  final String _capturadoPor;

  StreamSubscription<MuestraSensor>? _suscripcion;
  bool _pausadoPorSegundoPlano = false;
  bool _liberado = false;

  TipoSensor _sensor = TipoSensor.accelerometer;
  FrecuenciaMuestreo _frecuencia = FrecuenciaMuestreo.normal;
  MuestraSensor? _ultimaMuestra;
  String? _mensajeError;

  TipoSensor get sensor => _sensor;
  FrecuenciaMuestreo get frecuencia => _frecuencia;

  /// Última muestra recibida del sensor seleccionado, o null si aún no hay.
  MuestraSensor? get ultimaMuestra => _ultimaMuestra;

  /// Mensaje en español del último error, o null si no hay error.
  String? get mensajeError => _mensajeError;

  /// True mientras hay una suscripción abierta al sensor.
  bool get activo => _suscripcion != null;

  /// Abre la suscripción al sensor seleccionado. No hace nada si ya está activa.
  void iniciar() {
    if (activo) return;
    _mensajeError = null;
    _suscripcion = _servicio
        .stream(_sensor, intervalo: _frecuencia.intervalo)
        .listen(_alRecibir, onError: _alFallar);
    notifyListeners();
  }

  /// Cierra la suscripción. Conserva la última muestra para poder guardarla.
  void detener() {
    _pausadoPorSegundoPlano = false;
    if (!activo) return;
    _cancelar();
    notifyListeners();
  }

  /// Cambia de sensor. Si estaba activo, sigue activo con el nuevo sensor.
  void seleccionarSensor(TipoSensor tipo) {
    if (!sensores.contains(tipo)) {
      throw ArgumentError.value(
        tipo,
        'tipo',
        'No es un sensor de esta feature',
      );
    }
    if (tipo == _sensor) return;
    _sensor = tipo;
    _ultimaMuestra = null;
    _reiniciar();
  }

  /// Cambia la frecuencia de muestreo. Si estaba activo, se vuelve a suscribir
  /// porque el sistema operativo solo aplica la frecuencia al suscribirse.
  void cambiarFrecuencia(FrecuenciaMuestreo nueva) {
    if (nueva == _frecuencia) return;
    _frecuencia = nueva;
    _reiniciar();
  }

  /// Pausa la lectura mientras la app no está visible, para no gastar batería.
  void pausarPorSegundoPlano() {
    if (!activo) return;
    _cancelar();
    _pausadoPorSegundoPlano = true;
    notifyListeners();
  }

  /// Reanuda la lectura si se pausó al pasar a segundo plano.
  void reanudarDesdeSegundoPlano() {
    if (!_pausadoPorSegundoPlano) return;
    _pausadoPorSegundoPlano = false;
    iniciar();
  }

  /// Lectura para `GuardarMedicionButton`: una foto de la última muestra.
  ///
  /// Devuelve null si todavía no hay datos. Solo se guarda lo que el usuario
  /// pide con el botón, nunca cada evento del sensor (decisión "Frecuencia de
  /// guardado").
  SensorReading? lecturaActual() {
    final muestra = _ultimaMuestra;
    if (muestra == null) return null;
    return SensorReading(
      tipo: _sensor,
      x: muestra.x,
      y: muestra.y,
      z: muestra.z,
      recordedAt: muestra.momento,
      capturadoPor: _capturadoPor,
    );
  }

  void _alRecibir(MuestraSensor muestra) {
    _ultimaMuestra = muestra;
    notifyListeners();
  }

  void _alFallar(Object error) {
    _mensajeError = error is AppException
        ? error.mensaje
        : 'No se pudo leer el ${_sensor.etiqueta.toLowerCase()}.';
    _cancelar();
    notifyListeners();
  }

  void _reiniciar() {
    final estabaActivo = activo;
    _cancelar();
    _mensajeError = null;
    if (estabaActivo) {
      iniciar();
    } else {
      notifyListeners();
    }
  }

  void _cancelar() {
    _suscripcion?.cancel();
    _suscripcion = null;
  }

  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  /// La suscripción se cancela al salir de la pantalla (regla 2.1.5).
  @override
  void dispose() {
    _liberado = true;
    _cancelar();
    super.dispose();
  }
}
