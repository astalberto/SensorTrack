// Detalle completo de un registro.
// Responsable: Josué

import 'package:flutter/material.dart';

class DetalleRegistroPage extends StatelessWidget {
  const DetalleRegistroPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro #$id')),
      // TODO(Josué): cargar el detalle con HistorialEstado.
      body: const Center(child: Text('Detalle del registro')),
    );
  }
}
