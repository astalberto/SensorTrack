// Latitud, longitud, precisión y hora de la ubicación actual.
// Responsable: Cody

import 'package:flutter/material.dart';

import '../../registro/registro.dart';
import '../estado/ubicacion_estado.dart';
import '../servicios/location_service.dart';
import '../widgets/politica_ubicacion.dart';

class UbicacionPage extends StatefulWidget {
  const UbicacionPage({super.key, this.crearEstado});

  /// Permite usar un estado de prueba. Por defecto lee el GPS real.
  final UbicacionEstado Function()? crearEstado;

  @override
  State<UbicacionPage> createState() => _UbicacionPageState();
}

class _UbicacionPageState extends State<UbicacionPage> {
  late final UbicacionEstado _estado =
      widget.crearEstado?.call() ?? UbicacionEstado(LocationService());

  @override
  void dispose() {
    _estado.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    if (!_estado.politicaAceptada) {
      final acepto = await PoliticaUbicacion.pedirAceptacion(context);
      if (!acepto) return;
      _estado.aceptarPolitica();
    }
    await _estado.capturar();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _estado,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Ubicación'),
          actions: [
            IconButton(
              tooltip: 'Política de ubicación',
              icon: const Icon(Icons.privacy_tip_outlined),
              onPressed: () => PoliticaUbicacion.mostrar(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _contenido(context),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _estado.estado == EstadoUbicacion.capturando
                  ? null
                  : _obtenerUbicacion,
              icon: const Icon(Icons.my_location),
              label: Text(
                _estado.ultimaPosicion == null
                    ? 'Obtener ubicación'
                    : 'Actualizar ubicación',
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
        floatingActionButton: _estado.ultimaPosicion == null
            ? null
            : GuardarMedicionButton(obtenerLectura: _estado.lecturaActual),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    switch (_estado.estado) {
      case EstadoUbicacion.inicial:
        return const _Mensaje(
          icono: Icons.location_searching,
          texto: 'Pulsa "Obtener ubicación" para leer el GPS.',
        );
      case EstadoUbicacion.capturando:
        return const Column(
          children: [
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Esperando señal GPS…'),
          ],
        );
      case EstadoUbicacion.error:
        return _Mensaje(
          icono: Icons.location_off,
          texto: _estado.error?.mensaje ?? 'No se pudo obtener la ubicación.',
          color: Theme.of(context).colorScheme.error,
          accion: _estado.puedeAbrirAjustes
              ? OutlinedButton(
                  onPressed: _estado.abrirAjustes,
                  child: const Text('Abrir ajustes'),
                )
              : OutlinedButton(
                  onPressed: _obtenerUbicacion,
                  child: const Text('Reintentar'),
                ),
        );
      case EstadoUbicacion.listo:
        return _TarjetaCoordenadas(estado: _estado);
    }
  }
}

class _TarjetaCoordenadas extends StatelessWidget {
  const _TarjetaCoordenadas({required this.estado});

  final UbicacionEstado estado;

  @override
  Widget build(BuildContext context) {
    final p = estado.ultimaPosicion!;
    final hora = p.timestamp.toLocal();
    return Card(
      child: Column(
        children: [
          _Fila('Latitud', p.latitude.toStringAsFixed(6)),
          _Fila('Longitud', p.longitude.toStringAsFixed(6)),
          _Fila('Precisión', '± ${p.accuracy.toStringAsFixed(1)} m'),
          _Fila('Fecha', '${_dos(hora.day)}/${_dos(hora.month)}/${hora.year}'),
          _Fila(
            'Hora',
            '${_dos(hora.hour)}:${_dos(hora.minute)}:${_dos(hora.second)}',
          ),
        ],
      ),
    );
  }
}

String _dos(int n) => n.toString().padLeft(2, '0');

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(etiqueta),
      trailing: Text(valor, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({
    required this.icono,
    required this.texto,
    this.color,
    this.accion,
  });

  final IconData icono;
  final String texto;
  final Color? color;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icono, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          ),
          if (accion != null) ...[const SizedBox(height: 12), accion!],
        ],
      ),
    );
  }
}
