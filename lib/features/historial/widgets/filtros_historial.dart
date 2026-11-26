// Chips de filtro del historial: tipo de sensor y "Solo míos".
// Responsable: Josué

import 'package:flutter/material.dart';

import '../../../core/constantes/tipos_sensor.dart';

class FiltrosHistorial extends StatelessWidget {
  const FiltrosHistorial({
    super.key,
    required this.tipo,
    required this.alCambiarTipo,
    required this.soloMios,
    this.alCambiarSoloMios,
  });

  /// Tipo seleccionado; null es "Todos".
  final TipoSensor? tipo;
  final ValueChanged<TipoSensor?> alCambiarTipo;

  final bool soloMios;

  /// Si es null no se muestra el chip "Solo míos" (falta CAPTURADO_POR).
  final ValueChanged<bool>? alCambiarSoloMios;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final opcion in <TipoSensor?>[null, ...TipoSensor.values])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(opcion?.etiqueta ?? 'Todos'),
                selected: tipo == opcion,
                onSelected: (_) => alCambiarTipo(opcion),
              ),
            ),
          if (alCambiarSoloMios case final alCambiar?)
            FilterChip(
              label: const Text('Solo míos'),
              selected: soloMios,
              onSelected: alCambiar,
            ),
        ],
      ),
    );
  }
}
