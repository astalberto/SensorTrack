// Estado del guardado: inactivo / guardando / éxito / error.
// Responsable: Josué

import 'package:flutter/foundation.dart';

import '../../../shared/datos/readings_repository.dart';

enum EstadoGuardado { inactivo, guardando, exito, error }

class RegistroEstado extends ChangeNotifier {
  RegistroEstado(this._repositorio);

  // ignore: unused_field
  final ReadingsRepository _repositorio;

  EstadoGuardado estado = EstadoGuardado.inactivo;
  String? mensajeError;

  // TODO(Josué): guardar(lectura) respetando la frecuencia máxima.
}
