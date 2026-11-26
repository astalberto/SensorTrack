// Fila de la lista del historial.
// Responsable: Josué

import 'package:flutter/material.dart';

import '../../../shared/modelos/sensor_reading.dart';
import 'formato_registro.dart';

class RegistroTile extends StatelessWidget {
  const RegistroTile({super.key, required this.registro, this.onTap});

  final SensorReading registro;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(iconoTipo(registro.tipo))),
      title: Text(registro.tipo.etiqueta),
      subtitle: Text(
        '${resumenValores(registro)}\n'
        '${formatearFecha(registro.recordedAt)} · ${registro.capturadoPor}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
