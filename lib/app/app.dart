// Shell de la app: MaterialApp, tema y navegación.
// Responsable: Alberto

import 'package:flutter/material.dart';

import '../core/tema/tema_app.dart';
import '../features/estadisticas/estadisticas.dart';
import '../features/historial/historial.dart';
import '../features/home/home.dart';
import '../features/sensores/sensores.dart';
import '../features/ubicacion/ubicacion.dart';
import 'rutas.dart';

class SensorTrackApp extends StatelessWidget {
  const SensorTrackApp({super.key, this.crearHomeEstado});

  /// Solo para pruebas: estado de Home sin Supabase ni sensores reales.
  final HomeEstado Function()? crearHomeEstado;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SensorTrack',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      darkTheme: TemaApp.oscuro,
      initialRoute: Rutas.home,
      routes: {
        Rutas.home: (_) => HomePage(crearEstado: crearHomeEstado),
        Rutas.sensores: (_) => const SensoresPage(),
        Rutas.ubicacion: (_) => const UbicacionPage(),
        Rutas.historial: (_) => const HistorialPage(),
        Rutas.estadisticas: (_) => const EstadisticasPage(),
      },
      onGenerateRoute: (ajustes) {
        if (ajustes.name == Rutas.detalleRegistro) {
          final id = ajustes.arguments as int;
          return MaterialPageRoute(builder: (_) => DetalleRegistroPage(id: id));
        }
        return null;
      },
    );
  }
}
