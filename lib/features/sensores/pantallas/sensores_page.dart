// Lecturas en tiempo real de acelerómetro y giroscopio, con botón Guardar.
// Responsable: Alberto

import 'package:flutter/material.dart';

import '../../../core/constantes/tipos_sensor.dart';
import '../../registro/registro.dart';
import '../estado/sensores_estado.dart';
import '../servicios/sensor_service.dart';
import '../widgets/tarjeta_eje.dart';

class SensoresPage extends StatefulWidget {
  const SensoresPage({super.key, this.crearEstado});

  /// Permite usar un estado de prueba. Por defecto lee los sensores reales.
  final SensoresEstado Function()? crearEstado;

  @override
  State<SensoresPage> createState() => _SensoresPageState();
}

class _SensoresPageState extends State<SensoresPage> {
  late final SensoresEstado _estado =
      widget.crearEstado?.call() ?? SensoresEstado(SensorService());
  late final AppLifecycleListener _cicloDeVida;

  @override
  void initState() {
    super.initState();
    // Sin pantalla visible no se lee el sensor: se pausa y se reanuda solo.
    _cicloDeVida = AppLifecycleListener(
      onHide: _estado.pausarPorSegundoPlano,
      onShow: _estado.reanudarDesdeSegundoPlano,
    );
  }

  @override
  void dispose() {
    _cicloDeVida.dispose();
    // Cancela la suscripción al salir de la pantalla (regla 2.1.5).
    _estado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensores')),
      body: ListenableBuilder(
        listenable: _estado,
        builder: (context, _) => _Contenido(estado: _estado),
      ),
      floatingActionButton: GuardarMedicionButton(
        obtenerLectura: _estado.lecturaActual,
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.estado});

  final SensoresEstado estado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final muestra = estado.ultimaMuestra;
    final escala = estado.sensor == TipoSensor.gyroscope ? 10.0 : 20.0;
    final error = estado.mensajeError;

    return ListView(
      // Espacio inferior para que el botón Guardar no tape el contenido.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        SegmentedButton<TipoSensor>(
          segments: [
            for (final tipo in SensoresEstado.sensores)
              ButtonSegment(
                value: tipo,
                label: Text(tipo.etiqueta),
                icon: Icon(
                  tipo == TipoSensor.gyroscope
                      ? Icons.threesixty
                      : Icons.vibration,
                ),
              ),
          ],
          selected: {estado.sensor},
          onSelectionChanged: (s) => estado.seleccionarSensor(s.first),
        ),
        const SizedBox(height: 16),
        if (error != null) ...[
          _AvisoError(mensaje: error, alReintentar: estado.iniciar),
          const SizedBox(height: 8),
        ],
        for (final (eje, valor) in [
          ('X', muestra?.x),
          ('Y', muestra?.y),
          ('Z', muestra?.z),
        ])
          TarjetaEje(
            eje: eje,
            valor: valor,
            unidad: estado.sensor.unidad,
            escala: escala,
          ),
        const SizedBox(height: 8),
        Text(
          _textoEstado(estado),
          style: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        estado.activo
            ? FilledButton.tonalIcon(
                onPressed: estado.detener,
                icon: const Icon(Icons.stop),
                label: const Text('Detener'),
              )
            : FilledButton.icon(
                onPressed: estado.iniciar,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar'),
              ),
        const SizedBox(height: 24),
        Text(
          'Frecuencia de muestreo (aproximada)',
          style: tema.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<FrecuenciaMuestreo>(
          segments: [
            for (final f in FrecuenciaMuestreo.values)
              ButtonSegment(value: f, label: Text(f.etiqueta)),
          ],
          selected: {estado.frecuencia},
          onSelectionChanged: (s) => estado.cambiarFrecuencia(s.first),
        ),
      ],
    );
  }

  static String _textoEstado(SensoresEstado estado) {
    final muestra = estado.ultimaMuestra;
    if (muestra == null) {
      return estado.activo
          ? 'Esperando datos del sensor…'
          : 'Pulsa Iniciar para leer el sensor.';
    }
    final hora = _hora(muestra.momento);
    return estado.activo
        ? 'Leyendo · última muestra $hora'
        : 'Detenido · última muestra $hora';
  }

  static String _hora(DateTime t) {
    String dos(int n) => n.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '${dos(t.hour)}:${dos(t.minute)}:${dos(t.second)}.$ms';
  }
}

class _AvisoError extends StatelessWidget {
  const _AvisoError({required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Card(
      color: colores.errorContainer,
      child: ListTile(
        leading: Icon(Icons.error_outline, color: colores.onErrorContainer),
        title: Text(mensaje, style: TextStyle(color: colores.onErrorContainer)),
        trailing: TextButton(
          onPressed: alReintentar,
          style: TextButton.styleFrom(
            foregroundColor: colores.onErrorContainer,
          ),
          child: const Text('Reintentar'),
        ),
      ),
    );
  }
}
