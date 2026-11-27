// Lista de registros guardados por los tres integrantes.
// Responsable: Josué

import 'package:flutter/material.dart';

import '../../../shared/datos/supabase_readings_repository.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../estado/detalle_registro_estado.dart';
import '../estado/historial_estado.dart';
import '../servicios/historial_consulta.dart';
import '../widgets/filtros_historial.dart';
import '../widgets/mensaje_central.dart';
import '../widgets/registro_tile.dart';
import 'detalle_registro_page.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key, this.crearEstado});

  /// Permite usar un estado de prueba. Por defecto lee de Supabase.
  final HistorialEstado Function()? crearEstado;

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  late final HistorialEstado _estado =
      widget.crearEstado?.call() ??
      HistorialEstado(HistorialConsulta(SupabaseReadingsRepository()));
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alDesplazar);
    _estado.cargar();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _estado.dispose();
    super.dispose();
  }

  // Pide la página siguiente un poco antes de llegar al final.
  void _alDesplazar() {
    if (_scroll.position.extentAfter < 400) _estado.cargarMas();
  }

  // El detalle usa la misma consulta que la lista (en pruebas, la falsa).
  void _abrirDetalle(SensorReading registro) {
    final id = registro.id;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalleRegistroPage(
          id: id,
          crearEstado: () => DetalleRegistroEstado(_estado.consulta, id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _estado.cargar,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _estado,
        builder: (context, _) => Column(
          children: [
            FiltrosHistorial(
              tipo: _estado.filtroTipo,
              alCambiarTipo: _estado.filtrarPorTipo,
              soloMios: _estado.soloMios,
              alCambiarSoloMios: _estado.puedeFiltrarMios
                  ? _estado.cambiarSoloMios
                  : null,
            ),
            const Divider(height: 1),
            Expanded(child: _contenido(context)),
          ],
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    final estado = _estado;

    if (estado.cargando && estado.registros.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (estado.mensajeError case final mensaje?) {
      return MensajeCentral(
        icono: Icons.cloud_off,
        texto: mensaje,
        accion: FilledButton.icon(
          onPressed: estado.cargar,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }

    if (estado.registros.isEmpty) {
      return RefreshIndicator(
        onRefresh: estado.cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            MensajeCentral(
              icono: Icons.inbox_outlined,
              texto: estado.hayFiltros
                  ? 'No hay registros con este filtro.'
                  : 'Todavía no hay registros guardados.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: estado.cargar,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: estado.registros.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == estado.registros.length) return _pieLista(context);
          final registro = estado.registros[i];
          return RegistroTile(
            registro: registro,
            onTap: () => _abrirDetalle(registro),
          );
        },
      ),
    );
  }

  Widget _pieLista(BuildContext context) {
    final estado = _estado;
    final Widget contenido;
    if (estado.cargandoMas) {
      contenido = const CircularProgressIndicator();
    } else if (estado.errorAlCargarMas case final error?) {
      contenido = Column(
        children: [
          Text(error, textAlign: TextAlign.center),
          TextButton(
            onPressed: estado.reintentarCargarMas,
            child: const Text('Reintentar'),
          ),
        ],
      );
    } else if (estado.hayMas) {
      // Por si la lista no llena la pantalla y no hay desplazamiento.
      contenido = TextButton(
        onPressed: estado.cargarMas,
        child: const Text('Cargar más'),
      );
    } else {
      contenido = Text(
        'No hay más registros',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(child: contenido),
    );
  }
}
