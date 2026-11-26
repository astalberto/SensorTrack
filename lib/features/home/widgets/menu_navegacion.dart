// Menú con accesos a cada módulo.
// Responsable: Alberto

import 'package:flutter/material.dart';

import '../../../app/rutas.dart';

class MenuNavegacion extends StatelessWidget {
  const MenuNavegacion({super.key});

  static const _opciones = [
    (Icons.sensors, 'Sensores', 'Acelerómetro y giroscopio', Rutas.sensores),
    (Icons.location_on, 'Ubicación', 'Coordenadas GPS', Rutas.ubicacion),
    (Icons.history, 'Historial', 'Mediciones guardadas', Rutas.historial),
    (Icons.bar_chart, 'Estadísticas', 'Conteos y gráficos', Rutas.estadisticas),
  ];

  @override
  Widget build(BuildContext context) {
    // Column y no ListView: el menú va dentro del ListView de Home.
    return Column(
      children: [
        for (final (icono, titulo, detalle, ruta) in _opciones)
          Card(
            child: ListTile(
              leading: Icon(icono),
              title: Text(titulo),
              subtitle: Text(detalle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, ruta),
            ),
          ),
      ],
    );
  }
}
