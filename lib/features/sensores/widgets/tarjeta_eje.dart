// Muestra el valor de un eje (X, Y o Z) con una barra centrada en cero.
// Responsable: Alberto

import 'package:flutter/material.dart';

class TarjetaEje extends StatelessWidget {
  const TarjetaEje({
    super.key,
    required this.eje,
    required this.valor,
    this.unidad,
    this.escala = 20,
  });

  final String eje;

  /// Valor actual, o null si todavía no hay datos.
  final double? valor;

  final String? unidad;

  /// Valor absoluto que llena media barra. Valores mayores se recortan.
  final double escala;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final valor = this.valor;
    final fraccion = valor == null ? 0.0 : (valor / escala).clamp(-1.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(eje, style: tema.textTheme.titleLarge),
                const Spacer(),
                Text(
                  valor == null ? '—' : valor.toStringAsFixed(3),
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (unidad != null) ...[
                  const SizedBox(width: 6),
                  Text(unidad!, style: tema.textTheme.bodySmall),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _BarraCentrada(fraccion: fraccion),
          ],
        ),
      ),
    );
  }
}

/// Barra que crece hacia la derecha con valores positivos y hacia la
/// izquierda con negativos.
class _BarraCentrada extends StatelessWidget {
  const _BarraCentrada({required this.fraccion});

  /// Entre -1 y 1.
  final double fraccion;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final relleno = Container(height: 6, color: colores.primary);

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: ColoredBox(
        color: colores.surfaceContainerHighest,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: fraccion < 0 ? -fraccion : 0,
                  child: relleno,
                ),
              ),
            ),
            Container(width: 2, height: 10, color: colores.outline),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraccion > 0 ? fraccion : 0,
                  child: relleno,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
