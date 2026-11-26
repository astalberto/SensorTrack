# SensorTrack

App Flutter de la asignatura Desarrollo de Plataformas Móviles. Lee el acelerómetro, el giroscopio y el GPS del teléfono, guarda mediciones en una base compartida de Supabase y muestra el historial y estadísticas de los tres integrantes.

## Requisitos

- Flutter 3.47 o superior (Dart 3.13).
- Un teléfono Android o iOS. Los sensores no funcionan en el emulador de escritorio ni en Windows.
- Acceso al proyecto de Supabase compartido. La URL y la clave pública las entrega Josué.

## Ejecución

1. Instala las dependencias:
   ```
   flutter pub get
   ```
2. Copia la plantilla de credenciales y complétala. `env/dev.json` está en `.gitignore` y no se sube:
   ```
   cp env/ejemplo.json env/dev.json
   ```
   ```json
   {
     "SUPABASE_URL": "https://<proyecto>.supabase.co",
     "SUPABASE_KEY": "<clave pública>",
     "CAPTURADO_POR": "<tu nombre>"
   }
   ```
3. Ejecuta en el teléfono:
   ```
   flutter run --dart-define-from-file=env/dev.json
   ```
   En VS Code, usa la configuración **SensorTrack (env/dev.json)**.

También se pueden pasar los valores uno por uno:

```
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=... --dart-define=CAPTURADO_POR=...
```

Sin credenciales la app arranca igual. Home muestra "Supabase sin configurar" y los sensores funcionan, pero no se puede guardar.

## Pruebas

```
flutter analyze
flutter test
```

Las pruebas automáticas usan fuentes falsas en lugar de los sensores y de Supabase. Las pruebas en dispositivo físico están en la sección 9 del documento de arquitectura.

## Mapa de features

| Módulo | Feature | Qué hace | Responsable |
|---|---|---|---|
| M1 | [`home`](lib/features/home/) | Estado de conexión, sensores disponibles y menú | Alberto |
| M2 | [`sensores`](lib/features/sensores/) | Acelerómetro y giroscopio en tiempo real | Alberto |
| M2 | [`ubicacion`](lib/features/ubicacion/) | Latitud, longitud, precisión y hora del GPS | Cody |
| M3 | [`registro`](lib/features/registro/) | Botón "Guardar medición" y guardado en Supabase | Josué |
| M4 | [`historial`](lib/features/historial/) | Lista y detalle de las mediciones guardadas | Josué |
| M5 | [`estadisticas`](lib/features/estadisticas/) | Conteos, máximos, mínimos y gráfico de evolución | Cody |

Transversal:

- [`lib/app/`](lib/app/) y [`lib/core/`](lib/core/): shell, rutas, tema, errores y constantes. Responsable: Alberto.
- [`lib/shared/`](lib/shared/): modelo `SensorReading` (de los tres) y repositorio de datos (Josué).
- [`supabase/migrations/`](supabase/migrations/): esquema de la base. Responsable: Josué.

## Documentación

- [Arquitectura y reparto](docs/SensorTrack_reparto_y_arquitectura_v3.md)
- [Convenciones de código y Git](docs/convenciones.md)
- [Informe técnico](docs/informe_tecnico.md)
- [Plan de trabajo de Alberto](docs/plan_alberto.md)
- Guía de configuración de Supabase: pendiente (Josué)
- Guía de permisos de ubicación: pendiente (Cody)
