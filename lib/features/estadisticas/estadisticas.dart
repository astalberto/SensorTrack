// API pública de la feature `estadisticas` (M5 Estadísticas).
// Responsable: Cody
//
// EstadisticasEstado y EstadisticasCalculo se exportan para que el shell o
// las pruebas puedan inyectar un estado con un repositorio falso.

export 'estado/estadisticas_estado.dart' show EstadisticasEstado;
export 'pantallas/estadisticas_page.dart';
export 'servicios/estadisticas_calculo.dart' show EstadisticasCalculo;
