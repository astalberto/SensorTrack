// Conteos, máximos, mínimos, última ubicación y gráfico de evolución.
// Responsable: Cody

import 'package:flutter/material.dart';

class EstadisticasPage extends StatelessWidget {
  const EstadisticasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      // TODO(Cody): resumen con EstadisticasEstado y GraficoEvolucion.
      body: const Center(child: Text('Estadísticas')),
    );
  }
}
