// Lecturas en tiempo real de acelerómetro y giroscopio, con botón Guardar.
// Responsable: Alberto

import 'package:flutter/material.dart';

import '../../registro/registro.dart';

class SensoresPage extends StatelessWidget {
  const SensoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensores')),
      // TODO(Alberto): tarjetas por eje, iniciar/detener, usar SensoresEstado.
      body: const Center(child: Text('Acelerómetro y giroscopio')),
      floatingActionButton: GuardarMedicionButton(
        // TODO(Alberto): devolver la lectura actual desde SensoresEstado.
        obtenerLectura: () => null,
      ),
    );
  }
}
