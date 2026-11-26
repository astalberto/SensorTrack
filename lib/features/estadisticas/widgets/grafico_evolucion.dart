// Gráfico de evolución temporal de X, Y y Z (fl_chart).
// Responsable: Cody

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/modelos/sensor_reading.dart';

class GraficoEvolucion extends StatelessWidget {
  const GraficoEvolucion({super.key, required this.lecturas});

  /// Lecturas ordenadas de la más antigua a la más reciente.
  final List<SensorReading> lecturas;

  static const _series = [
    ('X', Colors.red),
    ('Y', Colors.green),
    ('Z', Colors.blue),
  ];

  @override
  Widget build(BuildContext context) {
    if (lecturas.length < 2) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('Se necesitan al menos 2 mediciones para el gráfico.'),
        ),
      );
    }

    final inicio = lecturas.first.recordedAt;
    // Eje horizontal: segundos desde la primera lectura.
    double segundos(SensorReading l) =>
        l.recordedAt.difference(inicio).inMilliseconds / 1000;
    final rango = segundos(lecturas.last);

    List<FlSpot> puntos(double? Function(SensorReading) valor) => [
      for (final l in lecturas)
        if (valor(l) != null) FlSpot(segundos(l), valor(l)!),
    ];

    final valores = [
      puntos((l) => l.x),
      puntos((l) => l.y),
      puntos((l) => l.z),
    ];

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                for (var i = 0; i < _series.length; i++)
                  LineChartBarData(
                    spots: valores[i],
                    color: _series[i].$2,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
              ],
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 44),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: rango > 0 ? rango / 3 : 1,
                    getTitlesWidget: (valor, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _hora(
                          inicio.add(
                            Duration(milliseconds: (valor * 1000).round()),
                          ),
                        ),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (tocados) => [
                    for (final t in tocados)
                      LineTooltipItem(
                        '${_series[t.barIndex].$1}: ${t.y.toStringAsFixed(3)}',
                        TextStyle(color: _series[t.barIndex].$2),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (nombre, color) in _series) ...[
              Container(width: 12, height: 12, color: color),
              const SizedBox(width: 4),
              Text(nombre),
              const SizedBox(width: 16),
            ],
          ],
        ),
      ],
    );
  }

  static String _hora(DateTime t) {
    final l = t.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(l.hour)}:${dos(l.minute)}:${dos(l.second)}';
  }
}
