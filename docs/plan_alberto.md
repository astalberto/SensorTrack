# Plan de trabajo de Alberto

Fuente: [SensorTrack_reparto_y_arquitectura_v3.md](SensorTrack_reparto_y_arquitectura_v3.md)

**Alcance de Alberto**

- Features: `home` (M1) y `sensores` (M2, acelerómetro y giroscopio).
- Transversal: `main.dart`, `app/`, `core/` (salvo `core/config/`, que es de Josué), tema, convenciones, CODEOWNERS, README y coordinación de entregables.

**Punto de partida (25-11-2026):** la estructura de carpetas, los stubs y los contratos (`SensorReading`, `ReadingsRepository`, `AppException`, `TipoSensor`) ya están en `main`. Falta la lógica real de `home` y `sensores` y los entregables transversales.

Leyenda: `[x]` hecho · `[ ]` pendiente · 📱 requiere dispositivo físico · 🤝 depende de otro integrante

---

## Sprint 0: cierre de la base

- [ ] Rama `develop` creada a partir de `main` (local; falta publicarla en GitHub).
- [x] `docs/convenciones.md`: nombres, estructura de feature, ramas, commits, PR y revisión.
- [x] Credenciales fuera del repo: `env/*` en `.gitignore` y `env/ejemplo.json` como plantilla para `--dart-define-from-file`, más `.vscode/launch.json`.

## Sprint 1: shell (`main.dart`, `app/`, `core/`)

- [x] `main.dart`: la app arranca aunque falle la inicialización de Supabase (prueba "abrir sin internet").
- [x] `core/tema`: tema claro y oscuro según el sistema.
- [x] `core/constantes/tipos_sensor.dart`: etiqueta en español y unidad por tipo, para mostrarlas en pantalla.
- [x] Android: nombre visible "SensorTrack" y permiso `INTERNET` en el manifiesto principal (sin él, Supabase falla en la APK de release).

## Sprint 1: feature `home` (M1)

- [x] Estado de conexión: sin configurar / comprobando / conectado / sin conexión, con tiempo límite y botón de reintento.
- [x] Sensores disponibles: acelerómetro y giroscopio (sondeo del stream con tiempo límite) y servicio de GPS activado o no (sin pedir permiso).
- [x] Mostrar el valor de `CAPTURADO_POR` y avisar si falta.
- [x] Menú de navegación a los módulos.
- [x] Pruebas unitarias de `HomeEstado` y `DetectorSensores`, y prueba de widget de la app.

## Sprint 1: feature `sensores` (M2)

- [x] `SensorService`: streams de acelerómetro y giroscopio con un tipo propio (`MuestraSensor`), errores traducidos a `AppException(sensor)` y `estaDisponible()`. En plataformas sin soporte (Windows) avisa de inmediato.
- [x] `SensoresEstado`: iniciar, detener, cambiar de sensor y de frecuencia, último valor y `lecturaActual()` para el botón de guardar.
- [x] Las suscripciones se cancelan al salir de la pantalla (regla 2.1.5) y se pausan con la app en segundo plano.
- [x] `SensoresPage`: selector de sensor, selector de frecuencia, tarjetas X/Y/Z con unidad, iniciar/detener y `GuardarMedicionButton`.
- [x] Pruebas unitarias del servicio y del estado, y prueba de widget de "salir y volver sin suscripciones activas".

## Documentación

- [x] `README.md`: descripción, requisitos, ejecución con credenciales, mapa de features y enlaces.
- [x] `docs/informe_tecnico.md`: esqueleto con responsable por sección, y redacción de las secciones de Alberto (arquitectura, home, sensores).

## Sprint 2-3: pendiente fuera del código

- [ ] 📱 Completar las pruebas de la sección 9 en el teléfono y anotar el resultado (tabla abajo).
- [ ] 📱 Evidencia de sensores: video corto moviendo y girando el teléfono. Ya hay capturas en `docs/evidencias/`.
- [ ] 🤝 Guía de demostración con los tres (orden y responsable por pantalla).
- [ ] 🤝 Coordinar el informe técnico: Josué y Cody redactan sus secciones.
- [ ] Publicar `develop` y abrir el PR de `feature/home-sensores` hacia `develop`, con revisión de Cody (tabla 6.2).

### Pruebas de Alberto (sección 9)

Automáticas: `flutter test`, 37 pruebas en verde (25-11-2026).

| Feature | Prueba | Resultado esperado | Resultado real | Evidencia |
|---|---|---|---|---|
| home | Abrir con y sin internet | Estado correcto, sin cierre de la app | Parcial: sin credenciales muestra "Supabase sin configurar" sin cerrarse (Pixel 8). "Sin internet" espera a `hayConexion()` 🤝 | `docs/evidencias/home_pixel8.png` |
| home | Ver sensores disponibles | Lista los sensores del dispositivo | OK en Pixel 8 (Android 17): acelerómetro, giroscopio y GPS detectados | `docs/evidencias/home_pixel8.png` |
| sensores | Mover el dispositivo | X, Y, Z cambian en tiempo real | Pendiente 📱 | |
| sensores | Girar el dispositivo | Valores del giroscopio cambian | Visto en Pixel 8: lectura en vivo, Z = −3.124 rad/s al girar. Falta el video | `docs/evidencias/sensores_giroscopio_pixel8.png` |
| sensores | Salir y volver a la pantalla | No quedan suscripciones activas | Prueba automática OK (`sensores_page_test.dart`). En el teléfono: pendiente 📱 | |

## Dependencias con el equipo

| Con | Qué necesito | Para qué |
|---|---|---|
| Josué | `SupabaseService.hayConexion()` real (hoy solo mira si hay credenciales) | Que Home muestre "sin conexión" cuando no hay internet |
| Josué | `GuardarMedicionButton` y `RegistroEstado` reales | Que el botón de la pantalla de sensores guarde de verdad |
| Josué y Cody | Usuarios de GitHub | Completar CODEOWNERS |
