// Detecta qué sensores tiene disponibles el dispositivo.
// Responsable: Alberto

import 'package:geolocator/geolocator.dart';

import '../../../core/constantes/tipos_sensor.dart';
import '../../sensores/sensores.dart';

class DisponibilidadSensor {
  const DisponibilidadSensor(
    this.tipo, {
    required this.disponible,
    required this.detalle,
  });

  final TipoSensor tipo;
  final bool disponible;

  /// Texto en español para mostrar debajo del nombre del sensor.
  final String detalle;
}

class DetectorSensores {
  DetectorSensores({
    SensorService? sensores,
    Future<bool> Function()? gpsActivo,
  }) : _sensores = sensores ?? SensorService(),
       _gpsActivo = gpsActivo ?? _gpsActivoReal;

  final SensorService _sensores;
  final Future<bool> Function() _gpsActivo;

  /// Estado de acelerómetro, giroscopio y GPS, en ese orden. No lanza
  /// excepciones: si un sensor falla, se informa como no disponible.
  Future<List<DisponibilidadSensor>> detectar() async {
    final [acelerometro, giroscopio, gps] = await Future.wait([
      _sensores.estaDisponible(TipoSensor.accelerometer),
      _sensores.estaDisponible(TipoSensor.gyroscope),
      _gpsSeguro(),
    ]);
    return [
      _inercial(TipoSensor.accelerometer, acelerometro),
      _inercial(TipoSensor.gyroscope, giroscopio),
      DisponibilidadSensor(
        TipoSensor.gps,
        disponible: gps,
        detalle: gps
            ? 'Servicio de ubicación activado'
            : 'Servicio de ubicación desactivado',
      ),
    ];
  }

  Future<bool> _gpsSeguro() async {
    try {
      return await _gpsActivo();
    } catch (_) {
      return false;
    }
  }

  static DisponibilidadSensor _inercial(TipoSensor tipo, bool disponible) =>
      DisponibilidadSensor(
        tipo,
        disponible: disponible,
        detalle: disponible
            ? 'Disponible'
            : 'No disponible en este dispositivo',
      );

  // Solo consulta si el servicio está activado. No pide permiso: eso lo hace
  // la pantalla de Ubicación cuando el usuario captura.
  static Future<bool> _gpsActivoReal() => Geolocator.isLocationServiceEnabled();
}
