// Lista de registros guardados por los tres integrantes.
// Responsable: Josué

import 'package:flutter/material.dart';

class HistorialPage extends StatelessWidget {
  const HistorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      // TODO(Josué): lista con filtros usando HistorialEstado.
      body: const Center(child: Text('Historial de registros')),
    );
  }
}
