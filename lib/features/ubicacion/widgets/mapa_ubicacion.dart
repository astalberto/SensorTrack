// Mapa opcional con la ubicación capturada (mejora, ver decisión "Mapa").
// Responsable: Cody

import 'package:flutter/material.dart';

class MapaUbicacion extends StatelessWidget {
  const MapaUbicacion({
    super.key,
    required this.latitud,
    required this.longitud,
  });

  final double latitud;
  final double longitud;

  @override
  Widget build(BuildContext context) {
    // TODO(Cody): reemplazar por un mapa real.
    return const SizedBox.shrink();
  }
}
