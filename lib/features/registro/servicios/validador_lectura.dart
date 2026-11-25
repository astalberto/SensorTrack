// Valida que una lectura tenga los campos correctos según su tipo (tabla 4.4).
// Responsable: Josué

import '../../../core/errores/app_exception.dart';
import '../../../shared/modelos/sensor_reading.dart';

class ValidadorLectura {
  /// Lanza AppException(validacion) si la lectura no es válida.
  void validar(SensorReading lectura) {
    // TODO(Josué): reglas por sensor_type.
    if (lectura.capturadoPor.isEmpty) {
      throw const AppException(
        CategoriaError.validacion,
        'Falta configurar CAPTURADO_POR.',
      );
    }
  }
}
