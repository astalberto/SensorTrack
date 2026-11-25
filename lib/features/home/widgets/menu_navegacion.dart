// Menú con accesos a cada módulo.
// Responsable: Alberto

import 'package:flutter/material.dart';

import '../../../app/rutas.dart';

class MenuNavegacion extends StatelessWidget {
  const MenuNavegacion({super.key});

  static const _opciones = [
    (Icons.sensors, 'Sensores', Rutas.sensores),
    (Icons.location_on, 'Ubicación', Rutas.ubicacion),
    (Icons.history, 'Historial', Rutas.historial),
    (Icons.bar_chart, 'Estadísticas', Rutas.estadisticas),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final (icono, titulo, ruta) in _opciones)
          ListTile(
            leading: Icon(icono),
            title: Text(titulo),
            onTap: () => Navigator.pushNamed(context, ruta),
          ),
      ],
    );
  }
}
