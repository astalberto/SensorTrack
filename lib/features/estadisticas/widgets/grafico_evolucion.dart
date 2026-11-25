// Gráfico de evolución temporal de las mediciones (fl_chart).
// Responsable: Cody

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoEvolucion extends StatelessWidget {
  const GraficoEvolucion({super.key, required this.puntos});

  /// Puntos ya ordenados por tiempo (x = tiempo, y = valor).
  final List<FlSpot> puntos;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(lineBarsData: [LineChartBarData(spots: puntos)]),
    );
  }
}
