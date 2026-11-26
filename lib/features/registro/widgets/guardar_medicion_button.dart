// Botón "Guardar medición". Se incrusta en otras features (sensores,
// ubicacion) y recibe la lectura por callback, así `registro` no depende
// de ellas.
// Responsable: Josué

import 'package:flutter/material.dart';

import '../../../shared/datos/supabase_readings_repository.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../estado/registro_estado.dart';

/// Valida y guarda en la base compartida la lectura que devuelve
/// [obtenerLectura], y muestra el resultado en un SnackBar.
///
/// Uso desde otra feature, como `floatingActionButton`:
///
/// ```dart
/// GuardarMedicionButton(obtenerLectura: _estado.lecturaActual)
/// ```
///
/// La lectura debe traer `capturadoPor: SupabaseConfig.capturadoPor` y solo
/// los campos de su tipo (tabla 4.4). Devolver `null` si todavía no hay
/// datos: el botón muestra un aviso. No se guarda más de una medición cada
/// [RegistroEstado.intervaloPorDefecto].
class GuardarMedicionButton extends StatefulWidget {
  const GuardarMedicionButton({
    super.key,
    required this.obtenerLectura,
    this.crearEstado,
  });

  /// Devuelve la lectura actual o null si todavía no hay datos.
  final SensorReading? Function() obtenerLectura;

  /// Permite usar un estado de prueba. Por defecto guarda en Supabase.
  final RegistroEstado Function()? crearEstado;

  @override
  State<GuardarMedicionButton> createState() => _GuardarMedicionButtonState();
}

class _GuardarMedicionButtonState extends State<GuardarMedicionButton> {
  late final RegistroEstado _estado =
      widget.crearEstado?.call() ??
      RegistroEstado(SupabaseReadingsRepository());

  @override
  void dispose() {
    _estado.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final guardado = await _estado.guardar(widget.obtenerLectura());
    final mensaje = _estado.mensaje;
    if (!mounted || mensaje == null) return;

    final colores = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensaje,
            style: guardado ? null : TextStyle(color: colores.onError),
          ),
          backgroundColor: guardado ? null : colores.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _estado,
      builder: (context, _) {
        final guardando = _estado.guardando;
        return FloatingActionButton.extended(
          onPressed: guardando ? null : _guardar,
          icon: guardando
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(guardando ? 'Guardando…' : 'Guardar medición'),
        );
      },
    );
  }
}
