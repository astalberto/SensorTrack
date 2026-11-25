// Botón "Guardar medición". Se incrusta en otras features (sensores,
// ubicacion) y recibe la lectura por callback, así `registro` no depende
// de ellas.
// Responsable: Josué

import 'package:flutter/material.dart';

import '../../../shared/modelos/sensor_reading.dart';

class GuardarMedicionButton extends StatelessWidget {
  const GuardarMedicionButton({super.key, required this.obtenerLectura});

  /// Devuelve la lectura actual o null si todavía no hay datos.
  final SensorReading? Function() obtenerLectura;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.save),
      label: const Text('Guardar medición'),
      // TODO(Josué): validar con ValidadorLectura y guardar con RegistroEstado.
      onPressed: () {},
    );
  }
}
