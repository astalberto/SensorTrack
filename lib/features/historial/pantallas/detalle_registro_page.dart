// Detalle completo de un registro.
// Responsable: Josué

import 'package:flutter/material.dart';

import '../../../core/constantes/tipos_sensor.dart';
import '../../../shared/datos/supabase_readings_repository.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../estado/detalle_registro_estado.dart';
import '../servicios/historial_consulta.dart';
import '../widgets/formato_registro.dart';
import '../widgets/mensaje_central.dart';

/// Detalle del registro [id]. La abre HistorialPage y también la ruta
/// `Rutas.detalleRegistro` del shell.
class DetalleRegistroPage extends StatefulWidget {
  const DetalleRegistroPage({super.key, required this.id, this.crearEstado});

  final int id;

  /// Permite usar un estado de prueba. Por defecto lee de Supabase.
  final DetalleRegistroEstado Function()? crearEstado;

  @override
  State<DetalleRegistroPage> createState() => _DetalleRegistroPageState();
}

class _DetalleRegistroPageState extends State<DetalleRegistroPage> {
  late final DetalleRegistroEstado _estado =
      widget.crearEstado?.call() ??
      DetalleRegistroEstado(
        HistorialConsulta(SupabaseReadingsRepository()),
        widget.id,
      );

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
    return Scaffold(
      appBar: AppBar(title: Text('Registro #${widget.id}')),
      body: ListenableBuilder(
        listenable: _estado,
        builder: (context, _) {
          if (_estado.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_estado.mensajeError case final mensaje?) {
            return MensajeCentral(
              icono: Icons.cloud_off,
              texto: mensaje,
              accion: FilledButton.icon(
                onPressed: _estado.cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            );
          }
          final registro = _estado.registro;
          if (registro == null) {
            return MensajeCentral(
              icono: Icons.search_off,
              texto:
                  'No existe el registro #${widget.id}. '
                  'Puede que lo hayan borrado.',
            );
          }
          return _Detalle(registro: registro);
        },
      ),
    );
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({required this.registro});

  final SensorReading registro;

  @override
  Widget build(BuildContext context) {
    final r = registro;
    final tema = Theme.of(context);
    final unidad = r.tipo.unidad ?? '';

    final datosSensor = switch (r.tipo) {
      TipoSensor.gps => [
        ('Latitud', '${formatearNumero(r.latitude, 6)}°'),
        ('Longitud', '${formatearNumero(r.longitude, 6)}°'),
        ('Precisión', '± ${formatearNumero(r.accuracy, 1)} m'),
      ],
      _ => [
        ('Eje X', '${formatearNumero(r.x, 4)} $unidad'),
        ('Eje Y', '${formatearNumero(r.y, 4)} $unidad'),
        ('Eje Z', '${formatearNumero(r.z, 4)} $unidad'),
      ],
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Icon(iconoTipo(r.tipo))),
          title: Text(r.tipo.etiqueta, style: tema.textTheme.titleLarge),
          subtitle: Text(formatearFecha(r.recordedAt)),
        ),
        const SizedBox(height: 8),
        _Seccion(titulo: 'Medición', datos: datosSensor),
        const SizedBox(height: 16),
        _Seccion(
          titulo: 'Registro',
          datos: [
            ('ID', '${r.id ?? '—'}'),
            ('Tipo de sensor', r.tipo.valorBd),
            ('Fecha y hora (local)', formatearFecha(r.recordedAt)),
            ('Fecha y hora (UTC)', r.recordedAt.toUtc().toIso8601String()),
            ('Capturado por', r.capturadoPor.isEmpty ? '—' : r.capturadoPor),
          ],
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.datos});

  final String titulo;
  final List<(String, String)> datos;

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
              child: Text(titulo, style: tema.textTheme.titleMedium),
            ),
            for (final (etiqueta, valor) in datos)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(etiqueta, style: tema.textTheme.bodyMedium),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        valor,
                        textAlign: TextAlign.end,
                        style: tema.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
