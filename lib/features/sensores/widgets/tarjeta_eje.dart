// Muestra el valor de un eje (X, Y o Z).
// Responsable: Alberto

import 'package:flutter/material.dart';

class TarjetaEje extends StatelessWidget {
  const TarjetaEje({super.key, required this.eje, required this.valor});

  final String eje;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(eje),
        trailing: Text(valor.toStringAsFixed(3)),
      ),
    );
  }
}
