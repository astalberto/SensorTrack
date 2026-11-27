// Íconos y formatos para mostrar un registro. Los nombres y unidades de cada
// sensor vienen de TipoSensor (core).
// Responsable: Josué

import 'package:flutter/material.dart';

import '../../../core/constantes/tipos_sensor.dart';
import '../../../shared/modelos/sensor_reading.dart';

/// Mismos íconos que usan Sensores y el menú de Home.
IconData iconoTipo(TipoSensor tipo) => switch (tipo) {
  TipoSensor.accelerometer => Icons.vibration,
  TipoSensor.gyroscope => Icons.threesixty,
  TipoSensor.gps => Icons.location_on,
};

/// Fecha y hora local del dispositivo: `25/11/2026 18:47:05`.
String formatearFecha(DateTime fecha) {
  final f = fecha.toLocal();
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year} '
      '${dos(f.hour)}:${dos(f.minute)}:${dos(f.second)}';
}

String formatearNumero(double? valor, int decimales) =>
    valor == null ? '—' : valor.toStringAsFixed(decimales);

/// Una línea con los valores principales, para la lista.
String resumenValores(SensorReading r) => switch (r.tipo) {
  TipoSensor.gps =>
    'Lat ${formatearNumero(r.latitude, 5)}  '
        'Lon ${formatearNumero(r.longitude, 5)}  '
        '±${formatearNumero(r.accuracy, 0)} m',
  _ =>
    'X ${formatearNumero(r.x, 3)}  '
        'Y ${formatearNumero(r.y, 3)}  '
        'Z ${formatearNumero(r.z, 3)}',
};
