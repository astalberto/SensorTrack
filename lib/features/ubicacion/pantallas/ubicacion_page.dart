// Latitud, longitud, precisión y hora de la ubicación actual.
// Responsable: Cody

import 'package:flutter/material.dart';

class UbicacionPage extends StatelessWidget {
  const UbicacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación')),
      // TODO(Cody): estados de permiso y captura con UbicacionEstado,
      // aviso de privacidad (7.4) y GuardarMedicionButton.
      body: const Center(child: Text('Coordenadas GPS')),
    );
  }
}
