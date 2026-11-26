// Lista de sensores del dispositivo y si están disponibles.
// Responsable: Alberto

import 'package:flutter/material.dart';

import '../servicios/detector_sensores.dart';

class TarjetaSensores extends StatelessWidget {
  const TarjetaSensores({
    super.key,
    required this.sensores,
    required this.detectando,
  });

  final List<DisponibilidadSensor> sensores;
  final bool detectando;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Sensores del dispositivo',
                style: tema.textTheme.titleMedium,
              ),
            ),
            if (detectando)
              const ListTile(
                leading: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                title: Text('Detectando sensores…'),
              )
            else if (sensores.isEmpty)
              const ListTile(title: Text('No se pudieron detectar sensores.'))
            else
              for (final s in sensores)
                ListTile(
                  leading: Icon(
                    s.disponible ? Icons.check_circle : Icons.cancel_outlined,
                    color: s.disponible
                        ? tema.colorScheme.primary
                        : tema.colorScheme.error,
                  ),
                  title: Text(s.tipo.etiqueta),
                  subtitle: Text(s.detalle),
                ),
          ],
        ),
      ),
    );
  }
}
