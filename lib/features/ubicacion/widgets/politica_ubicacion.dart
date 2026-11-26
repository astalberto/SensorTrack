// Política de uso de la ubicación (sección 7.4 del documento de arquitectura).
// Responsable: Cody

import 'package:flutter/material.dart';

class PoliticaUbicacion {
  PoliticaUbicacion._();

  static const titulo = 'Uso de tu ubicación';

  static const puntos = [
    'La ubicación se usa solo para la práctica de medición del GPS.',
    'Solo se captura cuando pulsas "Obtener ubicación". Nunca en segundo plano.',
    'Solo se guarda en la base de datos si pulsas "Guardar medición".',
    'Las ubicaciones guardadas son visibles para todo el equipo del taller.',
  ];

  /// Muestra la política y devuelve true si el usuario la acepta.
  static Future<bool> pedirAceptacion(BuildContext context) async {
    final acepto = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(titulo),
        content: const _ListaPuntos(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No acepto'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Acepto'),
          ),
        ],
      ),
    );
    return acepto ?? false;
  }

  /// Muestra la política solo para consulta.
  static Future<void> mostrar(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(titulo),
      content: const _ListaPuntos(),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

class _ListaPuntos extends StatelessWidget {
  const _ListaPuntos();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final punto in PoliticaUbicacion.puntos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(punto)),
              ],
            ),
          ),
      ],
    );
  }
}
