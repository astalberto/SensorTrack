// M5: total de registros, mediciones por sensor, máximos y mínimos del
// acelerómetro, última ubicación y gráfico de evolución.
// Responsable: Cody

import 'package:flutter/material.dart';

import '../../../core/constantes/tipos_sensor.dart';
import '../../../shared/datos/supabase_readings_repository.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../estado/estadisticas_estado.dart';
import '../servicios/estadisticas_calculo.dart';
import '../widgets/grafico_evolucion.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key, this.crearEstado});

  /// Permite usar un estado de prueba. Por defecto lee de Supabase.
  final EstadisticasEstado Function()? crearEstado;

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  late final EstadisticasEstado _estado =
      widget.crearEstado?.call() ??
      EstadisticasEstado(EstadisticasCalculo(SupabaseReadingsRepository()));

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
      appBar: AppBar(
        title: const Text('Estadísticas'),
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
        builder: (context, _) => RefreshIndicator(
          onRefresh: _estado.cargar,
          child: _cuerpo(context),
        ),
      ),
    );
  }

  Widget _cuerpo(BuildContext context) {
    final resumen = _estado.resumen;

    if (_estado.cargando && resumen == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (resumen == null) {
      return ListView(
        children: [
          _Error(
            mensaje: _estado.mensajeError ?? 'Sin datos.',
            alReintentar: _estado.cargar,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_estado.mensajeError != null)
          _Error(mensaje: _estado.mensajeError!, alReintentar: _estado.cargar),
        _TarjetaConteos(resumen: resumen),
        _TarjetaExtremos(extremos: resumen.acelerometro),
        _TarjetaUltimaUbicacion(lectura: resumen.ultimaUbicacion),
        _TarjetaGrafico(estado: _estado),
      ],
    );
  }
}

String _dos(int n) => n.toString().padLeft(2, '0');

String _fechaHora(DateTime t) {
  final l = t.toLocal();
  return '${_dos(l.day)}/${_dos(l.month)}/${l.year} '
      '${_dos(l.hour)}:${_dos(l.minute)}:${_dos(l.second)}';
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TarjetaConteos extends StatelessWidget {
  const _TarjetaConteos({required this.resumen});

  final ResumenEstadisticas resumen;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme;
    return _Seccion(
      titulo: 'Registros',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total'),
              Text('${resumen.total}', style: estilo.headlineMedium),
            ],
          ),
          const Divider(),
          for (final tipo in TipoSensor.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tipo.etiqueta),
                  Text('${resumen.conteo(tipo)}', style: estilo.titleMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TarjetaExtremos extends StatelessWidget {
  const _TarjetaExtremos({required this.extremos});

  final ExtremosAcelerometro? extremos;

  @override
  Widget build(BuildContext context) {
    final e = extremos;
    if (e == null) {
      return const _Seccion(
        titulo: 'Acelerómetro: máximos y mínimos',
        child: Text('Aún no hay mediciones del acelerómetro.'),
      );
    }

    TableRow fila(String eje, ExtremosEje v) => TableRow(
      children: [
        _Celda(eje),
        _Celda(v.minimo.toStringAsFixed(3), alDerecha: true),
        _Celda(v.maximo.toStringAsFixed(3), alDerecha: true),
      ],
    );

    return _Seccion(
      titulo:
          'Acelerómetro: máximos y mínimos '
          '(${TipoSensor.accelerometer.unidad})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Table(
            children: [
              const TableRow(
                children: [
                  _Celda('Eje', negrita: true),
                  _Celda('Mínimo', negrita: true, alDerecha: true),
                  _Celda('Máximo', negrita: true, alDerecha: true),
                ],
              ),
              fila('X', e.x),
              fila('Y', e.y),
              fila('Z', e.z),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calculado sobre ${e.muestras} mediciones.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda(this.texto, {this.negrita = false, this.alDerecha = false});

  final String texto;
  final bool negrita;
  final bool alDerecha;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        texto,
        textAlign: alDerecha ? TextAlign.right : TextAlign.left,
        style: negrita ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ),
    );
  }
}

class _TarjetaUltimaUbicacion extends StatelessWidget {
  const _TarjetaUltimaUbicacion({required this.lectura});

  final SensorReading? lectura;

  @override
  Widget build(BuildContext context) {
    final l = lectura;
    return _Seccion(
      titulo: 'Última ubicación registrada',
      child: l == null || l.latitude == null || l.longitude == null
          ? const Text('Aún no hay ubicaciones guardadas.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latitud: ${l.latitude!.toStringAsFixed(6)}'),
                Text('Longitud: ${l.longitude!.toStringAsFixed(6)}'),
                if (l.accuracy != null)
                  Text('Precisión: ± ${l.accuracy!.toStringAsFixed(1)} m'),
                Text('Fecha: ${_fechaHora(l.recordedAt)}'),
              ],
            ),
    );
  }
}

class _TarjetaGrafico extends StatelessWidget {
  const _TarjetaGrafico({required this.estado});

  final EstadisticasEstado estado;

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'Evolución de las mediciones',
      child: Column(
        children: [
          SegmentedButton<TipoSensor>(
            segments: [
              for (final t in EstadisticasEstado.tiposGrafico)
                ButtonSegment(value: t, label: Text(t.etiqueta)),
            ],
            selected: {estado.tipoGrafico},
            onSelectionChanged: (s) => estado.cambiarTipoGrafico(s.first),
          ),
          const SizedBox(height: 16),
          if (estado.cargandoGrafico)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            GraficoEvolucion(lecturas: estado.serie),
          const SizedBox(height: 4),
          Text(
            'Últimas ${EstadisticasCalculo.puntosGrafico} mediciones como máximo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.cloud_off, color: color, size: 40),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          ),
          TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
