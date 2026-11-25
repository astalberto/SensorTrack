// Estado de Home: conexión con Supabase y lista de sensores disponibles.
// Responsable: Alberto

import 'package:flutter/foundation.dart';

class HomeEstado extends ChangeNotifier {
  bool cargando = false;
  bool conectado = false;

  // TODO(Alberto): comprobar conexión y sensores disponibles.
  Future<void> cargar() async {}
}
