// Permisos y lectura del GPS (geolocator).
// Responsable: Cody
//
// Todos los errores de geolocator se traducen a UbicacionException, que es
// un AppException con el problema concreto para que la pantalla ofrezca la
// acción adecuada (reintentar, abrir ajustes de la app o del GPS).

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../core/errores/app_exception.dart';

enum ProblemaUbicacion {
  gpsDesactivado,
  permisoDenegado,
  permisoDenegadoSiempre,
  sinSenal,
  desconocido,
}

class UbicacionException extends AppException {
  const UbicacionException(
    this.problema,
    super.categoria,
    super.mensaje, {
    super.causa,
  });

  final ProblemaUbicacion problema;
}

class LocationService {
  /// Tiempo máximo de espera de una posición. En interiores el GPS puede
  /// tardar mucho o no responder.
  static const tiempoMaximo = Duration(seconds: 20);

  /// Comprueba que el GPS esté activo y que haya permiso; lo pide si hace
  /// falta. Lanza UbicacionException.
  Future<void> asegurarPermiso() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const UbicacionException(
        ProblemaUbicacion.gpsDesactivado,
        CategoriaError.sensor,
        'El GPS está desactivado. Actívalo para obtener la ubicación.',
      );
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.deniedForever) {
      throw const UbicacionException(
        ProblemaUbicacion.permisoDenegadoSiempre,
        CategoriaError.permiso,
        'El permiso de ubicación está bloqueado. Habilítalo desde los '
        'ajustes de la aplicación.',
      );
    }
    if (permiso == LocationPermission.denied) {
      throw const UbicacionException(
        ProblemaUbicacion.permisoDenegado,
        CategoriaError.permiso,
        'Se necesita permiso de ubicación para mostrar las coordenadas.',
      );
    }
  }

  /// Una sola lectura de la ubicación actual, en primer plano.
  /// Lanza UbicacionException.
  Future<Position> ubicacionActual() async {
    await asegurarPermiso();
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: tiempoMaximo,
        ),
      );
    } on TimeoutException catch (e) {
      throw UbicacionException(
        ProblemaUbicacion.sinSenal,
        CategoriaError.sensor,
        'No se recibió señal GPS. Prueba al aire libre y reintenta.',
        causa: e,
      );
    } on LocationServiceDisabledException catch (e) {
      throw UbicacionException(
        ProblemaUbicacion.gpsDesactivado,
        CategoriaError.sensor,
        'El GPS se desactivó durante la captura.',
        causa: e,
      );
    } on PermissionDeniedException catch (e) {
      throw UbicacionException(
        ProblemaUbicacion.permisoDenegado,
        CategoriaError.permiso,
        'Permiso de ubicación denegado.',
        causa: e,
      );
    } catch (e) {
      throw UbicacionException(
        ProblemaUbicacion.desconocido,
        CategoriaError.sensor,
        'No se pudo obtener la ubicación.',
        causa: e,
      );
    }
  }

  /// Abre los ajustes de la app (permiso bloqueado).
  Future<bool> abrirAjustesApp() => Geolocator.openAppSettings();

  /// Abre los ajustes de ubicación del sistema (GPS desactivado).
  Future<bool> abrirAjustesGps() => Geolocator.openLocationSettings();
}
