# Contratos entre features

Responsables: los tres. Redactó Josué a partir del código del 2026-11-25.

> **Revisión pendiente:** Alberto (`AppException`, `TipoSensor`) y Cody (`LocationService`) deben confirmar sus secciones. Cualquier cambio en `SensorReading` necesita la aprobación de los tres (sección 2.1 del documento de arquitectura).

Este documento describe lo que una feature puede usar de otra. Si un contrato cambia, se actualiza aquí en el mismo PR.

| Contrato | Archivo | Dueño | Lo usan |
|---|---|---|---|
| `SensorReading` | `lib/shared/modelos/sensor_reading.dart` | Los tres | Todas las features |
| `TipoSensor` | `lib/core/constantes/tipos_sensor.dart` | Alberto | Todas las features |
| `AppException` | `lib/core/errores/app_exception.dart` | Alberto | Todas las features |
| `ReadingsRepository` | `lib/shared/datos/readings_repository.dart` | Josué | registro, historial, estadisticas |
| `SupabaseService` | `lib/shared/datos/supabase_service.dart` | Josué | `main.dart`, home |
| `GuardarMedicionButton` | `lib/features/registro/registro.dart` | Josué | sensores, ubicacion |
| `LocationService` | `lib/features/ubicacion/ubicacion.dart` | Cody | ubicacion (y pruebas) |

---

## 1. `SensorReading`

Una fila de `sensor_readings`. Es inmutable.

| Campo | Tipo Dart | Columna | Regla |
|---|---|---|---|
| `id` | `int?` | `id` | Null al crear; lo genera la base |
| `tipo` | `TipoSensor` | `sensor_type` | Obligatorio |
| `x`, `y`, `z` | `double?` | `x`, `y`, `z` | Solo `accelerometer` y `gyroscope`, finitos |
| `latitude`, `longitude` | `double?` | `latitude`, `longitude` | Solo `gps`; −90…90 y −180…180 |
| `accuracy` | `double?` | `accuracy` | Solo `gps`; ≥ 0, en metros |
| `recordedAt` | `DateTime` | `recorded_at` | Hora real de la captura |
| `capturadoPor` | `String` | `capturado_por` | `alberto`, `josue` o `cody` |

- **`toMap()`** arma el mapa para INSERT: no incluye `id` y envía `recorded_at` en UTC (ISO 8601).
- **`SensorReading.fromMap(map)`** lee una fila de Supabase. `recordedAt` queda en UTC; para mostrarlo se usa `.toLocal()`.
- **Quién arma la lectura:** la feature que captura. Sensores lo hace en `SensoresEstado.lecturaActual()` y ubicación en `UbicacionEstado.lecturaActual()`. Las dos ponen `capturadoPor: SupabaseConfig.capturadoPor`.

Las reglas de la tabla las valida `registro` antes de guardar y también las restricciones CHECK de la base. Las pruebas `test/features/registro/contrato_*_test.dart` comprueban que las lecturas de sensores y ubicación las cumplen.

## 2. `TipoSensor`

| Valor | `valorBd` | `etiqueta` | `unidad` |
|---|---|---|---|
| `accelerometer` | `accelerometer` | Acelerómetro | m/s² |
| `gyroscope` | `gyroscope` | Giroscopio | rad/s |
| `gps` | `gps` | GPS | null |

`TipoSensor.desdeBd(texto)` convierte el valor de la columna. Agregar un tipo requiere también una migración que amplíe el CHECK `sensor_readings_sensor_type_valido`.

## 3. `AppException`

```dart
AppException(CategoriaError categoria, String mensaje, {Object? causa})
```

| Categoría | Cuándo |
|---|---|
| `conexion` | Sin internet, tiempo agotado, Supabase sin configurar, clave inválida, tabla ausente |
| `permiso` | Permiso de ubicación denegado o rechazo de la base por RLS |
| `sensor` | Sensor o GPS no disponible, desactivado o sin señal |
| `validacion` | Lectura con campos que no corresponden a su tipo, o `CAPTURADO_POR` inválido |

- `mensaje` va en español y listo para mostrar. La pantalla lo muestra tal cual.
- `causa` guarda el error original solo para depurar.
- Subclases: `UbicacionException` (Cody) agrega `problema` (`ProblemaUbicacion`) para elegir la acción: reintentar, abrir los ajustes de la app o abrir los del GPS.

## 4. `ReadingsRepository`

Única puerta a la tabla compartida. La implementación real es `SupabaseReadingsRepository`. Para pruebas hay repositorios en memoria en `test/helpers/repositorio_en_memoria.dart` y `test/features/estadisticas/repositorio_falso.dart`.

| Método | Devuelve | Lanza |
|---|---|---|
| `guardar(lectura)` | `Future<void>` | `conexion`, `permiso`, `validacion` |
| `listar({tipo, capturadoPor, limite = 50, desplazamiento = 0})` | Lecturas de la más reciente a la más antigua | `conexion`, `permiso` |
| `obtenerPorId(id)` | La lectura o null | `conexion`, `permiso` |
| `contarPorTipo({capturadoPor})` | Un conteo por cada `TipoSensor`, con 0 si no hay | `conexion`, `permiso` |

- Los filtros null no se aplican.
- `listar` desempata por `id` descendente, así la paginación por `desplazamiento` es estable.
- `contarPorTipo` cuenta en la base, sin descargar filas.
- Solo lanza `AppException`. Cada operación tiene un tope de 15 s.
- No hay `actualizar` ni `borrar`: la base solo permite SELECT e INSERT a la app.

## 5. `SupabaseService`

| Miembro | Comportamiento |
|---|---|
| `inicializar()` | Inicializa Supabase si hay `SUPABASE_URL` y `SUPABASE_KEY`. No lanza |
| `estaInicializado` | `true` si la inicialización funcionó |
| `cliente` | Cliente de Supabase. Lanza `AppException(conexion)` si no está inicializado. Solo lo usa `lib/shared/datos/` |
| `hayConexion()` | `true` si se puede leer `sensor_readings` en menos de 5 s. No lanza |

## 6. `GuardarMedicionButton`

```dart
GuardarMedicionButton(obtenerLectura: _estado.lecturaActual)
```

- `obtenerLectura` devuelve la lectura actual o null si todavía no hay datos.
- Valida la lectura, impide más de un guardado cada 2 s, la guarda y muestra el resultado en un SnackBar. No lanza.
- `crearEstado` es opcional y sirve solo para pruebas.

## 7. `LocationService`

| Método | Comportamiento | Lanza |
|---|---|---|
| `asegurarPermiso()` | Comprueba que el GPS esté activo y pide el permiso si hace falta | `UbicacionException` |
| `ubicacionActual()` | Una sola posición en primer plano, con espera máxima de 20 s | `UbicacionException` |
| `abrirAjustesApp()` | Abre los ajustes de la app (permiso bloqueado) | No lanza |
| `abrirAjustesGps()` | Abre los ajustes de ubicación del sistema | No lanza |

| `ProblemaUbicacion` | Categoría | Acción en pantalla |
|---|---|---|
| `gpsDesactivado` | `sensor` | Abrir ajustes del GPS |
| `permisoDenegado` | `permiso` | Reintentar |
| `permisoDenegadoSiempre` | `permiso` | Abrir ajustes de la app |
| `sinSenal` | `sensor` | Reintentar al aire libre |
| `desconocido` | `sensor` | Reintentar |
