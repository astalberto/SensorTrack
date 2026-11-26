// Valida que una lectura tenga los campos correctos según su tipo (tabla 4.4).
// Responsable: Josué
//
// Son las mismas reglas que los CHECK de la migración 001: la app avisa antes
// de enviar, con un mensaje claro, en lugar de esperar el rechazo de la base.

import '../../../core/constantes/tipos_sensor.dart';
import '../../../core/errores/app_exception.dart';
import '../../../shared/modelos/sensor_reading.dart';

class ValidadorLectura {
  const ValidadorLectura();

  /// Igual que el CHECK `sensor_readings_capturado_por_valido`.
  static final formatoCapturadoPor = RegExp(r'^[a-z][a-z0-9_]{1,29}$');

  /// Lanza AppException(validacion) si la lectura no es válida.
  void validar(SensorReading lectura) {
    _validarCapturadoPor(lectura.capturadoPor);
    switch (lectura.tipo) {
      case TipoSensor.accelerometer || TipoSensor.gyroscope:
        _validarEjes(lectura);
      case TipoSensor.gps:
        _validarGps(lectura);
    }
  }

  void _validarCapturadoPor(String valor) {
    if (valor.isEmpty) {
      _fallar(
        'Falta configurar CAPTURADO_POR en env/dev.json '
        '(alberto, josue o cody).',
      );
    }
    if (!formatoCapturadoPor.hasMatch(valor)) {
      _fallar(
        'CAPTURADO_POR debe ir en minúsculas, sin tildes ni espacios '
        '(alberto, josue o cody). Valor actual: "$valor".',
      );
    }
  }

  void _validarEjes(SensorReading l) {
    final nombre = l.tipo == TipoSensor.accelerometer
        ? 'acelerómetro'
        : 'giroscopio';
    if (!_esFinito(l.x) || !_esFinito(l.y) || !_esFinito(l.z)) {
      _fallar('La lectura del $nombre debe tener valores X, Y y Z.');
    }
    if (l.latitude != null || l.longitude != null || l.accuracy != null) {
      _fallar('La lectura del $nombre no debe incluir datos de GPS.');
    }
  }

  void _validarGps(SensorReading l) {
    final lat = l.latitude, lon = l.longitude, precision = l.accuracy;
    if (!_esFinito(lat) || !_esFinito(lon) || !_esFinito(precision)) {
      _fallar('La lectura del GPS debe tener latitud, longitud y precisión.');
    }
    if (lat! < -90 || lat > 90) {
      _fallar('La latitud debe estar entre -90 y 90 grados.');
    }
    if (lon! < -180 || lon > 180) {
      _fallar('La longitud debe estar entre -180 y 180 grados.');
    }
    if (precision! < 0) {
      _fallar('La precisión del GPS no puede ser negativa.');
    }
    if (l.x != null || l.y != null || l.z != null) {
      _fallar('La lectura del GPS no debe incluir valores X, Y, Z.');
    }
  }

  static bool _esFinito(double? v) => v != null && v.isFinite;

  static Never _fallar(String mensaje) =>
      throw AppException(CategoriaError.validacion, mensaje);
}
