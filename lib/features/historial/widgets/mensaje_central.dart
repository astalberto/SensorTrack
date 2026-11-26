// Mensaje centrado con ícono y acción opcional (vacío, error, no encontrado).
// Responsable: Josué

import 'package:flutter/material.dart';

class MensajeCentral extends StatelessWidget {
  const MensajeCentral({
    super.key,
    required this.icono,
    required this.texto,
    this.accion,
  });

  final IconData icono;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: tema.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyLarge,
            ),
            if (accion case final accion?) ...[
              const SizedBox(height: 16),
              accion,
            ],
          ],
        ),
      ),
    );
  }
}
