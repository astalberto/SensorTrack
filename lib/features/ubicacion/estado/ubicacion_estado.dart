// Estado de la pantalla de ubicación: permiso y captura.
// Responsable: Cody

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../servicios/location_service.dart';

enum EstadoUbicacion { inicial, pidiendoPermiso, sinPermiso, capturando, listo, error }

class UbicacionEstado extends ChangeNotifier {
  UbicacionEstado(this._servicio);

  // ignore: unused_field
  final LocationService _servicio;

  EstadoUbicacion estado = EstadoUbicacion.inicial;
  Position? ultimaPosicion;
  String? mensajeError;

  // TODO(Cody): capturar() y reintentar().
}
