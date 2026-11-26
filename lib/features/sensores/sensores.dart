// API pública de la feature `sensores` (M2 acelerómetro y giroscopio).
// Responsable: Alberto
//
// - SensoresPage: pantalla con lectura en tiempo real y el botón de guardar.
// - SensorService: streams y comprobación de disponibilidad. Home lo usa para
//   listar los sensores del dispositivo.

export 'pantallas/sensores_page.dart';
export 'servicios/sensor_service.dart' show SensorService;
