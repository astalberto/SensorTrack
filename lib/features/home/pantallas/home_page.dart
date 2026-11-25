// Pantalla principal: estado de conexión, sensores disponibles y menú.
// Responsable: Alberto

import 'package:flutter/material.dart';

import '../widgets/menu_navegacion.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SensorTrack')),
      // TODO(Alberto): mostrar estado de conexión y sensores con HomeEstado.
      body: const MenuNavegacion(),
    );
  }
}
