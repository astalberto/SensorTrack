// Pantalla principal: estado de conexión, sensores disponibles y menú.
// Responsable: Alberto

import 'package:flutter/material.dart';

import '../estado/home_estado.dart';
import '../widgets/menu_navegacion.dart';
import '../widgets/tarjeta_conexion.dart';
import '../widgets/tarjeta_sensores.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.crearEstado});

  /// Permite usar un estado de prueba. Por defecto usa Supabase y los
  /// sensores reales.
  final HomeEstado Function()? crearEstado;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeEstado _estado = widget.crearEstado?.call() ?? HomeEstado();

  @override
  void initState() {
    super.initState();
    _estado.cargar();
  }

  @override
  void dispose() {
    _estado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('SensorTrack')),
      body: RefreshIndicator(
        onRefresh: _estado.cargar,
        child: ListenableBuilder(
          listenable: _estado,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TarjetaConexion(
                conexion: _estado.conexion,
                capturadoPor: _estado.capturadoPor,
                alReintentar: _estado.comprobarConexion,
              ),
              const SizedBox(height: 8),
              TarjetaSensores(
                sensores: _estado.sensores,
                detectando: _estado.detectandoSensores,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text('Módulos', style: tema.textTheme.titleMedium),
              ),
              const MenuNavegacion(),
            ],
          ),
        ),
      ),
    );
  }
}
