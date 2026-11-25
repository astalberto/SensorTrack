// Permisos y lectura del GPS (geolocator).
// Responsable: Cody

import 'package:geolocator/geolocator.dart';

import '../../../core/errores/app_exception.dart';

class LocationService {
  /// Pide permiso si hace falta. Lanza AppException(permiso | sensor).
  Future<void> asegurarPermiso() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException(
        CategoriaError.sensor,
        'El GPS está desactivado.',
      );
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw const AppException(
        CategoriaError.permiso,
        'Permiso de ubicación denegado.',
      );
    }
  }

  /// Ubicación actual. Lanza AppException(permiso | sensor).
  Future<Position> ubicacionActual() async {
    await asegurarPermiso();
    return Geolocator.getCurrentPosition();
  }

  /// Stream de ubicaciones. Quien se suscribe debe cancelarlo al salir.
  Stream<Position> streamUbicacion() => Geolocator.getPositionStream();
}
