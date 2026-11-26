// Cálculos de M5: total, conteo por sensor, máximos y mínimos del
// acelerómetro, última ubicación y serie para el gráfico de evolución.
// Responsable: Cody
//
// Solo usa la interfaz ReadingsRepository, nunca Supabase directamente.

import '../../../core/constantes/tipos_sensor.dart';
import '../../../shared/datos/readings_repository.dart';
import '../../../shared/modelos/sensor_reading.dart';

class ExtremosEje {
  const ExtremosEje(this.minimo, this.maximo);

  final double minimo;
  final double maximo;
}

class ExtremosAcelerometro {
  const ExtremosAcelerometro({
    required this.x,
    required this.y,
    required this.z,
    required this.muestras,
  });

  final ExtremosEje x;
  final ExtremosEje y;
  final ExtremosEje z;

  /// Cantidad de lecturas usadas en el cálculo.
  final int muestras;
}

class ResumenEstadisticas {
  const ResumenEstadisticas({
    required this.porSensor,
    required this.acelerometro,
    required this.ultimaUbicacion,
  });

  final Map<TipoSensor, int> porSensor;

  /// null si no hay lecturas de acelerómetro.
  final ExtremosAcelerometro? acelerometro;

  /// null si no hay lecturas de GPS.
  final SensorReading? ultimaUbicacion;

  int get total => porSensor.values.fold(0, (a, b) => a + b);

  int conteo(TipoSensor tipo) => porSensor[tipo] ?? 0;
}

class EstadisticasCalculo {
  EstadisticasCalculo(this._repositorio);

  final ReadingsRepository _repositorio;

  /// Tamaño de página al recorrer lecturas para máximos y mínimos.
  static const tamanoPagina = 500;

  /// Tope de lecturas leídas para máximos y mínimos, para no descargar la
  /// tabla entera si crece mucho.
  static const maximoLecturas = 5000;

  /// Puntos que se muestran en el gráfico de evolución.
  static const puntosGrafico = 100;

  /// Lanza AppException(conexion) si falla el repositorio.
  Future<ResumenEstadisticas> resumen() async {
    final resultados = await Future.wait<Object?>([
      _repositorio.contarPorTipo(),
      _listarTodas(TipoSensor.accelerometer),
      _repositorio.listar(tipo: TipoSensor.gps, limite: 1),
    ]);

    final conteos = resultados[0] as Map<TipoSensor, int>;
    final acelerometro = resultados[1] as List<SensorReading>;
    final gps = resultados[2] as List<SensorReading>;

    return ResumenEstadisticas(
      porSensor: {for (final t in TipoSensor.values) t: conteos[t] ?? 0},
      acelerometro: calcularExtremos(acelerometro),
      ultimaUbicacion: gps.isEmpty ? null : gps.first,
    );
  }

  /// Últimas lecturas de [tipo], ordenadas de la más antigua a la más
  /// reciente para dibujarlas en orden temporal.
  /// Lanza AppException(conexion) si falla el repositorio.
  Future<List<SensorReading>> evolucion(
    TipoSensor tipo, {
    int limite = puntosGrafico,
  }) async {
    final lecturas = await _repositorio.listar(tipo: tipo, limite: limite);
    return ordenarPorTiempo(lecturas);
  }

  Future<List<SensorReading>> _listarTodas(TipoSensor tipo) async {
    final todas = <SensorReading>[];
    while (todas.length < maximoLecturas) {
      final pagina = await _repositorio.listar(
        tipo: tipo,
        limite: tamanoPagina,
        desplazamiento: todas.length,
      );
      todas.addAll(pagina);
      if (pagina.length < tamanoPagina) break;
    }
    return todas;
  }

  /// Mínimo y máximo por eje. Ignora valores nulos. Devuelve null si
  /// ninguna lectura tiene los tres ejes.
  static ExtremosAcelerometro? calcularExtremos(List<SensorReading> lecturas) {
    final validas = lecturas
        .where((l) => l.x != null && l.y != null && l.z != null)
        .toList();
    if (validas.isEmpty) return null;

    ExtremosEje eje(double Function(SensorReading) valor) {
      var minimo = valor(validas.first);
      var maximo = minimo;
      for (final l in validas.skip(1)) {
        final v = valor(l);
        if (v < minimo) minimo = v;
        if (v > maximo) maximo = v;
      }
      return ExtremosEje(minimo, maximo);
    }

    return ExtremosAcelerometro(
      x: eje((l) => l.x!),
      y: eje((l) => l.y!),
      z: eje((l) => l.z!),
      muestras: validas.length,
    );
  }

  static List<SensorReading> ordenarPorTiempo(List<SensorReading> lecturas) =>
      [...lecturas]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
}
