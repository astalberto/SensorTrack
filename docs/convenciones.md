# Convenciones de código y Git

Responsable: Alberto. Complementa las secciones 2 y 6 de [SensorTrack_reparto_y_arquitectura_v3.md](SensorTrack_reparto_y_arquitectura_v3.md).

## 1. Nombres

| Qué | Forma | Ejemplo |
|---|---|---|
| Archivos y carpetas | `snake_case`, en español | `sensores_estado.dart` |
| Clases y enums | `PascalCase` | `SensoresEstado`, `TipoSensor` |
| Métodos, variables, valores de enum | `camelCase` | `lecturaActual()`, `sinConexion` |
| Miembros privados | prefijo `_` | `_suscripcion` |
| Columnas y valores de la base | como en el taller, en inglés | `sensor_type`, `accelerometer` |

El código va en español. Se mantienen en inglés los nombres que impone Flutter, los paquetes o el taller (`build`, `dispose`, `SensorReading`, columnas de la tabla).

## 2. Estructura de una feature

```
lib/features/<nombre>/
├── <nombre>.dart   API pública: lo único que importan las demás
├── pantallas/
├── widgets/
├── servicios/      sensores, GPS o datos propios
└── estado/         ChangeNotifier de la feature
```

- **Imports dentro de la feature:** relativos (`../estado/...`).
- **Imports de otra feature:** solo su archivo de API (`../../sensores/sensores.dart`), nunca un archivo interno.
- **`core/` y `shared/`** se pueden importar desde cualquier feature.
- **Exportar con `show`** cuando solo se quiere publicar una parte de un archivo: `export 'servicios/sensor_service.dart' show SensorService;`.

## 3. Documentación en el código

- **Cabecera de cada archivo:** una línea con el propósito y otra con `Responsable: <nombre>`.
- **API pública:** comentario `///` con qué devuelve y qué `AppException` puede lanzar, o "No lanza".
- **Comentarios internos:** solo donde el código no se explica solo: cancelación de streams, permisos, cálculos, decisiones poco obvias.

## 4. Estado y pantallas

- **Estado:** un `ChangeNotifier` por pantalla, en `estado/`. La pantalla es un `StatefulWidget` que lo crea en su `State`, lo escucha con `ListenableBuilder` y lo libera en `dispose()`.
- **Pruebas:** la pantalla recibe `crearEstado` opcional, una función que devuelve el estado. Así la prueba usa servicios falsos y la app los reales.
- **Servicios inyectables:** los servicios reciben sus dependencias por constructor con un valor por defecto real (ver `SensorService` o `HomeEstado`).
- **Tareas asíncronas:** si pueden terminar después de salir de la pantalla, el estado no debe notificar tras `dispose()`. Ver `HomeEstado.notifyListeners`.
- **Streams y suscripciones:** se cancelan en `dispose()` (regla 2.1.5). Si la app pasa a segundo plano y el sensor no hace falta, se pausan (`AppLifecycleListener`).

## 5. Errores

- **Servicios:** traducen los errores de plataforma o de red a `AppException(categoria, mensaje)`. El mensaje va en español y listo para mostrar.
- **Categorías:** `conexion`, `permiso`, `sensor`, `validacion`.
- **Pantallas:** muestran `mensaje` y, si tiene sentido, un botón **Reintentar**. La app nunca se cierra por un error esperado (sin internet, sin permiso, sin sensor).

## 6. Formato, análisis y pruebas

- **Antes de cada PR:**
  ```
  dart format lib/features/<tu-feature> test/features/<tu-feature>
  flutter analyze
  flutter test
  ```
- **Formato:** formatea solo tus carpetas. `dart format lib` reformatea archivos de otros y ensucia su PR.
- **Pruebas:** van en `test/` con la misma ruta que en `lib/` (`test/features/sensores/...`).
- **Plugins en pruebas:** no se usan los plugins reales (sensors_plus, geolocator, Supabase). Se inyectan fuentes falsas (ver `test/features/sensores/fuente_falsa.dart`).
- **Dispositivo físico:** acelerómetro, giroscopio y GPS se prueban en un teléfono real (sección 9). El resultado se anota en el plan de pruebas.

## 7. Credenciales

- **Nunca** se suben URL ni claves de Supabase.
- Cada integrante copia `env/ejemplo.json` a `env/dev.json` (ignorado por Git) y ejecuta:
  ```
  flutter run --dart-define-from-file=env/dev.json
  ```
  En VS Code, la configuración **SensorTrack (env/dev.json)** de `.vscode/launch.json` hace lo mismo.

## 8. Git

### Ramas

| Rama | Uso |
|---|---|
| `main` | Versión entregable. Solo recibe merges desde `develop`, con revisión |
| `develop` | Integración diaria |
| `module_<feature>_<feature>` | Una rama por integrante con sus dos features: `module_home_sensores` (Alberto), `module_registro_historial` (Josué), `module_ubicacion_estadisticas` (Cody) |
| `feature/db` | Migraciones y esquema. Solo Josué |

El documento de arquitectura (6.1) proponía una rama `feature/<feature>` por feature. El equipo usa una rama `module_...` por integrante, y esta tabla sigue esa práctica.

Se sale de `develop` y se vuelve a `develop` por PR. Mientras `develop` no esté publicada en GitHub, se sale de `main`. Antes de abrir el PR, actualiza tu rama con la rama destino.

### Commits

- En imperativo, con la feature o el área al inicio: `sensores: agregar selector de frecuencia`, `core: tema oscuro`, `docs: convenciones de Git`.
- Un commit por cambio con sentido propio. No mezclar formato de archivos ajenos.
- Sin credenciales, archivos generados (`build/`) ni cambios de rutas locales (por ejemplo, `.vscode/settings.json` con la ruta de tu PC).

### Pull requests

- Destino: `develop`.
- Descripción: qué cambia, cómo se probó (pruebas automáticas y en dispositivo) y capturas si hay UI.
- Revisión obligatoria según la tabla 6.2: **Alberto revisa a Josué, Josué a Cody y Cody a Alberto**.
- Cambios en `lib/shared/modelos/` necesitan aprobación de **los tres**. GitHub solo exige una; el autor espera las otras dos antes de fusionar.
- Cambios en `pubspec.yaml` se explican en el PR (qué paquete y por qué).
- Cambios de esquema: issue a Josué, que los aplica con una migración en `supabase/migrations/`.

### Definición de terminado

Ver sección 6.3 del documento de arquitectura: cumple el taller, maneja errores en español, probado en dispositivo físico, documentado, revisado y fusionado en `develop`.
