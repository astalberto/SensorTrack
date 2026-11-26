// API pública de la feature `home` (M1 Pantalla principal).
// Responsable: Alberto
//
// HomeEstado y DisponibilidadSensor se exportan para que el shell (`app/`)
// pueda inyectar un estado de prueba.

export 'estado/home_estado.dart' show EstadoConexion, HomeEstado;
export 'pantallas/home_page.dart';
export 'servicios/detector_sensores.dart' show DisponibilidadSensor;
