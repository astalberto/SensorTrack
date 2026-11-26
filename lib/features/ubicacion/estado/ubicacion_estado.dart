// Estado de la pantalla de ubicación: consentimiento, permiso y captura.
// Responsable: Cody

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/constantes/tipos_sensor.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../servicios/location_service.dart';

enum EstadoUbicacion { inicial, capturando, listo, error }

class UbicacionEstado extends ChangeNotifier {
  UbicacionEstado(this._servicio, {String? capturadoPor})
    : _capturadoPor = capturadoPor ?? SupabaseConfig.capturadoPor;

  final LocationService _servicio;
  final String _capturadoPor;

  /// Aceptación de la política de ubicación. Dura lo que dura la sesión de
  /// la app, así el aviso se vuelve a mostrar cada vez que se abre.
  static bool _politicaAceptada = false;

  EstadoUbicacion estado = EstadoUbicacion.inicial;
  Position? ultimaPosicion;
  UbicacionException? error;
  bool _liberado = false;

  bool get politicaAceptada => _politicaAceptada;

  void aceptarPolitica() {
    _politicaAceptada = true;
    notifyListeners();
  }

  /// Captura una sola posición. Solo se llama cuando el usuario pulsa el
  /// botón y ya aceptó la política; nunca en segundo plano.
  /// No lanza: los errores quedan en [error] con el mensaje en español.
  Future<void> capturar() async {
    if (!_politicaAceptada || estado == EstadoUbicacion.capturando) return;

    estado = EstadoUbicacion.capturando;
    error = null;
    notifyListeners();

    try {
      ultimaPosicion = await _servicio.ubicacionActual();
      estado = EstadoUbicacion.listo;
    } on UbicacionException catch (e) {
      error = e;
      estado = EstadoUbicacion.error;
    }
    notifyListeners();
  }

  /// Abre los ajustes que resuelven el error actual, si hay alguno.
  /// No lanza.
  Future<void> abrirAjustes() async {
    switch (error?.problema) {
      case ProblemaUbicacion.permisoDenegadoSiempre:
        await _servicio.abrirAjustesApp();
      case ProblemaUbicacion.gpsDesactivado:
        await _servicio.abrirAjustesGps();
      default:
        break;
    }
  }

  bool get puedeAbrirAjustes =>
      error?.problema == ProblemaUbicacion.permisoDenegadoSiempre ||
      error?.problema == ProblemaUbicacion.gpsDesactivado;

  /// Lectura lista para GuardarMedicionButton, o null si no hay posición.
  SensorReading? lecturaActual() {
    final p = ultimaPosicion;
    if (p == null) return null;
    return SensorReading(
      tipo: TipoSensor.gps,
      latitude: p.latitude,
      longitude: p.longitude,
      accuracy: p.accuracy,
      recordedAt: p.timestamp,
      capturadoPor: _capturadoPor,
    );
  }

  /// No notifica si la pantalla se cerró mientras se esperaba el GPS.
  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }

  @visibleForTesting
  static void reiniciarPolitica() => _politicaAceptada = false;
}
