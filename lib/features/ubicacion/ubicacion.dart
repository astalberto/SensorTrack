// API pública de la feature `ubicacion` (M2 GPS).
// Responsable: Cody
//
// UbicacionEstado se exporta para que el shell o las pruebas puedan inyectar
// un estado con un LocationService falso.

export 'estado/ubicacion_estado.dart' show EstadoUbicacion, UbicacionEstado;
export 'pantallas/ubicacion_page.dart';
export 'servicios/location_service.dart'
    show LocationService, ProblemaUbicacion, UbicacionException;
