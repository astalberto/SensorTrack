// Estado del historial: lista paginada y filtros seleccionados.
// Responsable: Josué

import 'package:flutter/foundation.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/constantes/tipos_sensor.dart';
import '../../../core/errores/app_exception.dart';
import '../../../shared/modelos/sensor_reading.dart';
import '../servicios/historial_consulta.dart';

class HistorialEstado extends ChangeNotifier {
  /// [capturadoPorPropio] es el integrante de esta instalación; por defecto
  /// `CAPTURADO_POR`. Si está vacío no se ofrece el filtro "Solo míos".
  HistorialEstado(this.consulta, {String? capturadoPorPropio})
    : _propio = capturadoPorPropio ?? SupabaseConfig.capturadoPor;

  /// Pública para que el detalle use la misma fuente de datos que la lista.
  final HistorialConsulta consulta;
  final String _propio;

  /// Cargando la primera página.
  bool cargando = false;

  /// Cargando una página siguiente.
  bool cargandoMas = false;

  /// `false` cuando la última página llegó incompleta.
  bool hayMas = true;

  List<SensorReading> registros = [];

  /// Error al cargar la primera página; la pantalla muestra "Reintentar".
  String? mensajeError;

  /// Error al cargar una página siguiente; la lista ya cargada se conserva.
  String? errorAlCargarMas;

  TipoSensor? filtroTipo;
  bool soloMios = false;

  bool get puedeFiltrarMios => _propio.isNotEmpty;
  bool get hayFiltros => filtroTipo != null || soloMios;

  int _paginaSiguiente = 0;

  // Cada carga nueva invalida las respuestas que lleguen de cargas anteriores
  // (por ejemplo, si el usuario cambia de filtro antes de que termine).
  int _generacion = 0;
  bool _descartado = false;

  /// Vuelve a cargar desde la primera página con los filtros actuales.
  /// La lista anterior sigue visible hasta que llega la nueva.
  Future<void> cargar() async {
    final generacion = ++_generacion;
    cargando = true;
    cargandoMas = false;
    mensajeError = null;
    errorAlCargarMas = null;
    _notificar();

    try {
      final pagina = await _pedir(0);
      if (generacion != _generacion) return;
      registros = pagina;
      _paginaSiguiente = 1;
      hayMas = pagina.length == HistorialConsulta.tamanoPagina;
    } catch (e) {
      if (generacion != _generacion) return;
      registros = [];
      hayMas = false;
      mensajeError = _mensajeDe(e);
    }
    cargando = false;
    _notificar();
  }

  /// Carga la página siguiente. No hace nada si ya está cargando, si no hay
  /// más páginas o si la anterior falló (usar [reintentarCargarMas]).
  Future<void> cargarMas() async {
    if (cargando || cargandoMas || !hayMas || errorAlCargarMas != null) {
      return;
    }
    final generacion = _generacion;
    cargandoMas = true;
    _notificar();

    try {
      final pagina = await _pedir(_paginaSiguiente);
      if (generacion != _generacion) return;
      // Si alguien insertó registros mientras tanto, el desplazamiento se
      // corre y pueden llegar filas repetidas: se descartan por id.
      final vistos = {for (final r in registros) r.id};
      registros = [
        ...registros,
        ...pagina.where((r) => !vistos.contains(r.id)),
      ];
      _paginaSiguiente++;
      hayMas = pagina.length == HistorialConsulta.tamanoPagina;
    } catch (e) {
      if (generacion != _generacion) return;
      errorAlCargarMas = _mensajeDe(e);
    }
    cargandoMas = false;
    _notificar();
  }

  Future<void> reintentarCargarMas() {
    errorAlCargarMas = null;
    return cargarMas();
  }

  /// `null` muestra todos los tipos.
  Future<void> filtrarPorTipo(TipoSensor? tipo) {
    if (tipo == filtroTipo) return Future.value();
    filtroTipo = tipo;
    return _reiniciar();
  }

  Future<void> cambiarSoloMios(bool valor) {
    if (!puedeFiltrarMios || valor == soloMios) return Future.value();
    soloMios = valor;
    return _reiniciar();
  }

  // Con un filtro nuevo, la lista anterior ya no corresponde: se vacía.
  Future<void> _reiniciar() {
    registros = [];
    hayMas = true;
    return cargar();
  }

  Future<List<SensorReading>> _pedir(int numero) => consulta.pagina(
    numero,
    tipo: filtroTipo,
    capturadoPor: soloMios ? _propio : null,
  );

  static String _mensajeDe(Object error) {
    if (error is AppException) return error.mensaje;
    debugPrint('HistorialEstado: error inesperado: $error');
    return 'Ocurrió un error inesperado al cargar el historial.';
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
