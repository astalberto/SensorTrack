// Estado de la conexión con la base compartida y quién firma las capturas.
// Responsable: Alberto

import 'package:flutter/material.dart';

import '../estado/home_estado.dart';

class TarjetaConexion extends StatelessWidget {
  const TarjetaConexion({
    super.key,
    required this.conexion,
    required this.capturadoPor,
    required this.alReintentar,
  });

  final EstadoConexion conexion;

  /// Valor de `CAPTURADO_POR`. Vacío si no se configuró.
  final String capturadoPor;

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final (icono, titulo, detalle) = switch (conexion) {
      EstadoConexion.comprobando => (
        null,
        'Comprobando conexión…',
        'Consultando la base compartida.',
      ),
      EstadoConexion.conectado => (
        Icons.cloud_done_outlined,
        'Conectado a Supabase',
        'Las mediciones se guardan en la base compartida.',
      ),
      EstadoConexion.sinConexion => (
        Icons.cloud_off_outlined,
        'Sin conexión',
        'Revisa tu internet. Los sensores funcionan igual, pero no se '
            'podrá guardar ni ver el historial.',
      ),
      EstadoConexion.sinConfigurar => (
        Icons.settings_outlined,
        'Supabase sin configurar',
        'Ejecuta la app con SUPABASE_URL y SUPABASE_KEY. Ver README.',
      ),
    };
    final hayProblema =
        conexion == EstadoConexion.sinConexion ||
        conexion == EstadoConexion.sinConfigurar;
    // Sobre errorContainer el contenido va en onErrorContainer, su color par,
    // para mantener el contraste en tema claro y oscuro.
    final colorContenido = hayProblema ? colores.onErrorContainer : null;

    return Card(
      color: hayProblema ? colores.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: icono == null
                      ? const CircularProgressIndicator(strokeWidth: 2.5)
                      : Icon(icono, color: colorContenido),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: tema.textTheme.titleMedium?.copyWith(
                      color: colorContenido,
                    ),
                  ),
                ),
                if (conexion == EstadoConexion.sinConexion)
                  TextButton(
                    onPressed: alReintentar,
                    style: TextButton.styleFrom(
                      foregroundColor: colorContenido,
                    ),
                    child: const Text('Reintentar'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(detalle, style: TextStyle(color: colorContenido)),
            const Divider(height: 24),
            capturadoPor.trim().isEmpty
                ? Text(
                    'Falta CAPTURADO_POR: no se podrán guardar mediciones.',
                    style: TextStyle(
                      color: colorContenido ?? colores.error,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    'Capturas a nombre de: $capturadoPor',
                    style: TextStyle(color: colorContenido),
                  ),
          ],
        ),
      ),
    );
  }
}
