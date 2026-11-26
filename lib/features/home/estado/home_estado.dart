// Estado de Home: conexión con Supabase y lista de sensores disponibles.
// Responsable: Alberto

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/datos/supabase_service.dart';
import '../servicios/detector_sensores.dart';

enum EstadoConexion { sinConfigurar, comprobando, conectado, sinConexion }

class HomeEstado extends ChangeNotifier {
  /// Los parámetros se reemplazan en pruebas. Por defecto usan Supabase, la
  /// configuración de `--dart-define` y los sensores reales.
  HomeEstado({
    Future<bool> Function()? comprobarConexion,
    Future<List<DisponibilidadSensor>> Function()? detectarSensores,
    bool? configurado,
    String? capturadoPor,
    this.tiempoLimite = const Duration(seconds: 5),
  }) : _comprobarConexion = comprobarConexion ?? SupabaseService.hayConexion,
       _detectarSensores = detectarSensores ?? DetectorSensores().detectar,
       _configurado = configurado ?? SupabaseConfig.estaConfigurado,
       capturadoPor = capturadoPor ?? SupabaseConfig.capturadoPor;

  final Future<bool> Function() _comprobarConexion;
  final Future<List<DisponibilidadSensor>> Function() _detectarSensores;
  final bool _configurado;

  /// Si la conexión no responde en este tiempo, se considera sin conexión.
  final Duration tiempoLimite;

  /// Integrante que firma las capturas (`capturado_por`).
  final String capturadoPor;

  EstadoConexion conexion = EstadoConexion.comprobando;
  List<DisponibilidadSensor> sensores = const [];
  bool detectandoSensores = false;

  bool _liberado = false;

  bool get faltaCapturadoPor => capturadoPor.trim().isEmpty;

  /// Comprueba la conexión y detecta los sensores en paralelo. No lanza.
  Future<void> cargar() =>
      Future.wait([comprobarConexion(), detectarSensores()]);

  /// Actualiza [conexion]. Un error o una demora mayor a [tiempoLimite]
  /// cuentan como sin conexión. No lanza.
  Future<void> comprobarConexion() async {
    if (!_configurado) {
      conexion = EstadoConexion.sinConfigurar;
      notifyListeners();
      return;
    }
    conexion = EstadoConexion.comprobando;
    notifyListeners();

    bool conectado;
    try {
      conectado = await _comprobarConexion().timeout(tiempoLimite);
    } catch (_) {
      conectado = false;
    }
    conexion = conectado
        ? EstadoConexion.conectado
        : EstadoConexion.sinConexion;
    notifyListeners();
  }

  /// Actualiza [sensores]. No lanza.
  Future<void> detectarSensores() async {
    detectandoSensores = true;
    notifyListeners();
    try {
      sensores = await _detectarSensores();
    } catch (_) {
      sensores = const [];
    }
    detectandoSensores = false;
    notifyListeners();
  }

  // Las comprobaciones son asíncronas: si el usuario sale de Home antes de que
  // terminen, el resultado se descarta en vez de notificar a un estado liberado.
  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }
}
