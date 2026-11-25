# SensorTrack: arquitectura por features, reparto y documentación

Asignatura: Desarrollo de Plataformas Móviles
Stack: Flutter + Dart, sensors_plus, geolocator, fl_chart, Supabase (PostgreSQL en la nube, base de datos compartida)

> Documento de planificación. No contiene implementación.

---

## 1. Equipo y responsabilidades

| Integrante | Features asignadas | Responsabilidades transversales |
|---|---|---|
| **Alberto** | `home` (M1), `sensores` (M2 acelerómetro y giroscopio) | Shell de la app (`main.dart`, `app/`), `core/`, tema, convenciones y coordinación de entregables |
| **Josué** | `registro` (M3), `historial` (M4) | Base de datos compartida: proyecto Supabase, migraciones, RLS y `shared/datos/` |
| **Cody** | `ubicacion` (M2 GPS), `estadisticas` (M5) | Permisos de ubicación, mapa opcional y gráficos |

### Por qué este reparto

- **Cada integrante es dueño de un conjunto de features completo**, desde la pantalla hasta los datos. Así cada quien puede avanzar sin esperar a los demás.
- **Josué es dueño de la base compartida.** Como todos leen y escriben la misma tabla, un solo responsable del esquema evita cambios que rompan a los demás.
- **Alberto lleva el shell** porque es quien toca `main.dart`, la navegación y el tema.
- **Supuesto a confirmar con el docente:** el GPS pertenece al Módulo 2 en el taller, pero aquí va a la feature `ubicacion` para equilibrar la carga con Cody.

---

## 2. Arquitectura por features

El código se organiza por **funcionalidad de negocio**, no por tipo de archivo. Cada feature es una carpeta autocontenida: tiene sus pantallas, su lógica, su acceso a datos y sus pruebas. Lo que una feature necesita de otra pasa por un punto de entrada explícito.

### 2.1 Reglas de la arquitectura

1. **Una feature no importa archivos internos de otra.** Solo puede usar `core/`, `shared/` o la API pública de la otra feature.
2. **Cada feature expone una API pública** mediante un único archivo de entrada (por ejemplo `registro.dart`). Lo que no se exporta es interno y puede cambiar sin avisar.
3. **Los datos de la base compartida se leen y escriben solo desde `shared/datos/`** o desde la feature que es dueña de esos datos. Las pantallas no hablan con Supabase ni con los sensores directamente.
4. **Los modelos compartidos viven en `shared/modelos/`.** Un cambio en ellos requiere revisión de los tres integrantes.
5. **Los streams y suscripciones se cancelan al salir de la pantalla** que los abrió.
6. **`core/` no contiene lógica de negocio.** Solo configuración, errores, constantes y tema.

### 2.2 Estructura interna de una feature

Dentro de cada feature la organización es libre, pero se recomienda esta forma mínima para mantener la coherencia del equipo:

```
features/<nombre>/
├── <nombre>.dart        API pública (lo único que otras features pueden importar)
├── pantallas/           pantallas completas
├── widgets/             componentes visuales reutilizables dentro de la feature
├── servicios/           acceso a sensores, GPS o datos propios de la feature
└── estado/              estado y lógica de presentación de la feature
```

No todas las carpetas son obligatorias. Una feature pequeña puede tener solo `pantallas/` y `servicios/`.

### 2.3 Comunicación entre features

Solo hay tres formas permitidas:

1. **Modelos compartidos** en `shared/modelos/`. Ejemplo: `SensorReading`.
2. **Repositorio compartido** en `shared/datos/`, con una interfaz definida. Ejemplo: `ReadingsRepository`.
3. **Widgets públicos** que una feature exporta para otra. Ejemplo: `GuardarMedicionButton` pertenece a `registro` y se incrusta en la pantalla de `sensores`. Recibe un callback que devuelve la lectura actual, así `registro` no depende de `sensores`.

### 2.4 Flujo de ejemplo: guardar una medición

```
Usuario pulsa "Guardar medición" (widget de registro, dentro de la pantalla de sensores)
   → estado de registro valida la lectura recibida por callback
   → ReadingsRepository.guardar(lectura)      [shared/datos]
   → Supabase (base compartida en la nube)
   ← resultado o AppException
   → la pantalla muestra: guardando / éxito / error con mensaje en español
```

---

## 3. Estructura de carpetas

```
lib/
├── main.dart                              (Alberto)  arranque e inicialización de Supabase
│
├── app/                                   (Alberto)  shell de la aplicación
│   ├── app.dart                           MaterialApp, tema y navegación
│   └── rutas.dart                         nombres de rutas
│
├── core/                                  transversal, sin lógica de negocio
│   ├── config/supabase_config.dart        (Josué)   URL y clave por --dart-define
│   ├── errores/app_exception.dart         (Alberto) categorías: conexion, permiso, sensor, validacion
│   ├── constantes/tipos_sensor.dart       (Alberto) accelerometer, gyroscope, gps
│   └── tema/tema_app.dart                 (Alberto)
│
├── shared/                                usado por varias features
│   ├── modelos/
│   │   └── sensor_reading.dart            (todos)   contrato; cambios revisados por los tres
│   └── datos/                             (Josué)
│       ├── supabase_service.dart          cliente y comprobación de conexión
│       ├── readings_repository.dart       interfaz: guardar, listar, obtenerPorId, contarPorTipo
│       └── supabase_readings_repository.dart  implementación sobre sensor_readings
│
└── features/
    │
    ├── home/                              (Alberto)  M1 Pantalla principal
    │   ├── home.dart                      API pública
    │   ├── pantallas/home_page.dart
    │   ├── widgets/menu_navegacion.dart
    │   └── estado/home_estado.dart        estado de conexión y lista de sensores
    │
    ├── sensores/                          (Alberto)  M2 acelerómetro y giroscopio
    │   ├── sensores.dart                  API pública (incluye la pantalla y el widget de captura)
    │   ├── pantallas/sensores_page.dart   tiempo real, iniciar/detener, botón Guardar
    │   ├── widgets/tarjeta_eje.dart
    │   ├── servicios/sensor_service.dart  streams de acelerómetro y giroscopio
    │   └── estado/sensores_estado.dart    frecuencia, suscripciones, último valor
    │
    ├── registro/                          (Josué)    M3 Registro en Supabase
    │   ├── registro.dart                  exporta GuardarMedicionButton
    │   ├── widgets/guardar_medicion_button.dart
    │   ├── servicios/validador_lectura.dart
    │   └── estado/registro_estado.dart    guardando / éxito / error
    │
    ├── historial/                         (Josué)    M4 Historial
    │   ├── historial.dart                 API pública
    │   ├── pantallas/historial_page.dart
    │   ├── pantallas/detalle_registro_page.dart
    │   ├── servicios/historial_consulta.dart  filtros por tipo, paginación
    │   └── estado/historial_estado.dart   lista, selección, carga de detalle
    │
    ├── ubicacion/                         (Cody)     M2 GPS
    │   ├── ubicacion.dart                 API pública
    │   ├── pantallas/ubicacion_page.dart  latitud, longitud, precisión y hora
    │   ├── widgets/mapa_ubicacion.dart    mapa opcional
    │   ├── servicios/location_service.dart  permisos, ubicación actual, stream
    │   └── estado/ubicacion_estado.dart   estados de permiso y de captura
    │
    └── estadisticas/                      (Cody)     M5 Estadísticas
        ├── estadisticas.dart              API pública
        ├── pantallas/estadisticas_page.dart
        ├── widgets/grafico_evolucion.dart fl_chart
        ├── servicios/estadisticas_calculo.dart  conteos, máximos, mínimos, última ubicación
        └── estado/estadisticas_estado.dart
```

### 3.1 Por qué el GPS tiene su propia feature

El GPS tiene permisos, ciclo de vida y pantalla propia. Mezclarlo con acelerómetro y giroscopio obligaría a Alberto y a Cody a tocar los mismos archivos.

### 3.2 Por qué M3 no tiene pantalla propia

M3 es lógica de guardado y un botón. El botón pertenece a `registro` y se incrusta en la pantalla de `sensores`. Así el guardado tiene un solo dueño, aunque se use desde otra feature.

---

## 4. Base de datos compartida en la nube

Todos los integrantes conectan la app a **un mismo proyecto de Supabase**.

### 4.1 Reglas de la base compartida

| Tema | Regla |
|---|---|
| **Dueño del esquema** | Josué. Los cambios se hacen solo con migraciones versionadas en `supabase/migrations/` |
| **Cambios pedidos por otros** | Se piden en un issue y Josué los aplica mediante PR |
| **Credenciales** | URL y clave pública se pasan por `--dart-define`. Nunca se suben al repositorio |
| **Escritura desde la app** | Solo INSERT. No hay UPDATE ni DELETE para clientes |
| **Borrado de datos de prueba** | Lo hace el docente o Josué desde el panel |
| **Lectura** | SELECT para todos. Historial y estadísticas muestran datos de los tres |

### 4.2 Atribución de datos

Se propone un campo adicional a la tabla del taller:

- `capturado_por` (TEXT): integrante que hizo la captura, tomado de la configuración de la app.

Permite filtrar el historial, comparar conteos por persona y explicar en la demostración de dónde vienen los datos. Como no lo pide el taller, se documenta como decisión y se confirma con el docente.

### 4.3 Consecuencias

- **Las estadísticas de M5 incluyen los datos de los tres.** Deben acordar si usan el filtro por `capturado_por`.
- **Privacidad entre integrantes:** las ubicaciones de un integrante serán visibles para los demás. Se avisa antes de capturar GPS (ver sección 7.4).
- **Concurrencia:** las inserciones son independientes. El riesgo real son los cambios de esquema.

### 4.4 Modelo de la tabla `sensor_readings`

Campos del taller: `id`, `sensor_type`, `x`, `y`, `z`, `latitude`, `longitude`, `accuracy`, `recorded_at`, más `capturado_por`.

| sensor_type | x, y, z | latitude, longitude | accuracy |
|---|---|---|---|
| `accelerometer` | Sí | No | No |
| `gyroscope` | Sí | No | No |
| `gps` | No | Sí | Sí |

Mejoras que Josué aplica en la migración inicial:
- Restricción para que `sensor_type` acepte solo los tres valores.
- Índices sobre `recorded_at` (descendente) y `sensor_type`.
- La app envía `recorded_at` con la hora real de captura.
- RLS activado. Políticas: INSERT y SELECT para el rol anónimo con la clave pública. Ningún UPDATE ni DELETE.

---

## 5. Configuración del entorno

- **Credenciales:** `core/config/supabase_config.dart` lee URL y clave desde `--dart-define`. El comando de ejecución va en el README.
- **Dependencias:** `supabase_flutter`, `sensors_plus`, `geolocator`, `fl_chart`. Cada integrante registra cambios de `pubspec.yaml` mediante PR.
- **Permisos de ubicación:** Android (manifiesto) e iOS (`Info.plist` con la descripción de uso). Responsable: Cody.
- **Pruebas en dispositivo físico:** acelerómetro, giroscopio y GPS se prueban en un teléfono real.

---

## 6. Flujo de trabajo del equipo

### 6.1 Ramas y commits

- `main`: versión entregable, solo con revisión.
- `develop`: integración diaria.
- Ramas de trabajo: `feature/home`, `feature/sensores`, `feature/registro`, `feature/historial`, `feature/ubicacion`, `feature/estadisticas`, `feature/db` (solo Josué).
- Commits en imperativo con la feature al inicio, por ejemplo `historial: agregar filtro por sensor`.

### 6.2 Propiedad del código (CODEOWNERS)

| Ruta | Dueño | Revisor obligatorio |
|---|---|---|
| `lib/main.dart`, `lib/app/`, `lib/core/` | Alberto | Josué |
| `lib/features/home/`, `lib/features/sensores/` | Alberto | Cody |
| `lib/features/registro/`, `lib/features/historial/`, `lib/shared/datos/`, `supabase/` | Josué | Alberto |
| `lib/features/ubicacion/`, `lib/features/estadisticas/` | Cody | Josué |
| `lib/shared/modelos/` | Todos | Los tres |

La revisión cruzada sigue el orden: Alberto revisa a Josué, Josué a Cody y Cody a Alberto.

### 6.3 Definición de terminado

Una feature está terminada cuando:
1. Cumple sus requisitos del taller.
2. Maneja errores de conexión, permiso y sensor no disponible, con mensajes en español.
3. Sus pruebas de la sección 9 están hechas en dispositivo físico.
4. Su documentación está escrita.
5. Pasó la revisión de otro integrante y está fusionada en `develop`.

---

## 7. Documentación

### 7.1 Entregables del taller

| Documento | Responsable | Contenido |
|---|---|---|
| **README.md** | Alberto | Descripción, requisitos, ejecución con `--dart-define`, mapa de features, enlaces |
| **Informe técnico** (arquitectura y funcionamiento) | Alberto coordina; cada uno redacta su feature | Arquitectura por features, reglas (2.1), comunicación (2.3), flujo (2.4), decisiones (sección 8) |
| **Script SQL de creación** | Josué | Script comentado con las mejoras de 4.4 y políticas RLS |
| **Guía de configuración de Supabase** | Josué | Crear proyecto, obtener URL y clave pública, aplicar migraciones, agregar integrantes |
| **Guía de permisos de ubicación** | Cody | Pasos para Android e iOS |
| **Documento de contratos** | Los tres | `SensorReading`, `ReadingsRepository`, `LocationService`, `AppException` |
| **Registro de decisiones** | Autor de cada decisión | Tema, decisión, alternativa, motivo |
| **Plan de pruebas y resultados** | Cada uno para su feature | Tabla de la sección 9 con resultados reales |
| **Evidencia de sensores** | Alberto | Video o capturas de valores en movimiento |
| **Evidencia de GPS** | Cody | Capturas de coordenadas, precisión y mapa |
| **Evidencia de registros en Supabase** | Josué | Panel con registros de cada `sensor_type` y `capturado_por` |
| **Evidencia en dispositivo físico** | Cody coordina | Capturas de cada pantalla |
| **Política de uso de ubicación** | Cody | Texto en la app sobre el uso, la visibilidad para el equipo y la captura explícita |
| **Convenciones de código y Git** | Alberto | Nombres, ramas, commits, CODEOWNERS |
| **Guía de demostración** | Los tres | Orden, responsable por pantalla y datos a mostrar |

### 7.2 Documentación dentro del código

- Comentario de cabecera en cada archivo público: propósito y responsable.
- Documentación de cada método de la API pública: qué devuelve y qué errores puede lanzar.
- Comentarios solo donde el código no se explica solo: cancelación de streams, manejo de permisos, cálculo de estadísticas.

### 7.3 Documentación de la base compartida

- Un archivo por migración en `supabase/migrations/`, con fecha y descripción.
- Tabla de políticas RLS (rol, operación, condición).
- Lista de integrantes registrados en `capturado_por`.

### 7.4 Política de uso de ubicación

La política debe indicar:
- Para qué se usa la ubicación (medición del GPS en la práctica).
- Que los datos son visibles para el equipo del taller.
- Que la captura ocurre solo cuando el usuario pulsa un botón.
- Que no se captura en segundo plano.

---

## 8. Decisiones de arquitectura

| Tema | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| Organización | Por features, con API pública por feature | Organización por tipo de archivo (carpetas globales de modelos, vistas y controladores) | Cada integrante trabaja en carpetas propias y los conflictos bajan |
| Acceso a datos | Repositorio con interfaz en `shared/datos/` | Llamadas a Supabase desde las pantallas | Permite usar stubs y no acopla la UI a Supabase |
| Estado | Estado propio de cada feature con `ChangeNotifier` | Bloc, Riverpod | Curva de aprendizaje baja |
| Base de datos | Una tabla y un proyecto compartidos | Un proyecto por integrante | Lo pide el equipo y simplifica estadísticas e historial |
| Atribución | Campo `capturado_por` | Sin atribución | Distingue los datos de cada integrante |
| Escritura | Solo INSERT desde la app | INSERT, UPDATE y DELETE | Evita que un integrante altere datos de otro |
| Frecuencia de guardado | Limitada por la feature `sensores` | Guardar cada evento del sensor | Evita miles de registros innecesarios |
| Mapa | Coordenadas primero; mapa como mejora | Mapa desde el inicio | Reduce riesgo; el mapa es opcional |

---

## 9. Plan de pruebas

| Feature | Responsable | Prueba | Resultado esperado | Evidencia |
|---|---|---|---|---|
| home | Alberto | Abrir con y sin internet | Estado correcto, sin cierre de la app | Capturas de ambos estados |
| home | Alberto | Ver sensores disponibles | Lista los sensores del dispositivo | Captura |
| sensores | Alberto | Mover el dispositivo | X, Y, Z cambian en tiempo real | Video corto |
| sensores | Alberto | Girar el dispositivo | Valores del giroscopio cambian | Video corto |
| sensores | Alberto | Salir y volver a la pantalla | No quedan suscripciones activas | Revisión de código y prueba |
| registro | Josué | Guardar con conexión | Registro con campos correctos y `capturado_por` | Panel de Supabase |
| registro | Josué | Guardar sin conexión | Error claro y la app sigue funcionando | Captura |
| registro | Josué | Guardar varias veces seguidas | Se respeta la frecuencia | Conteo de registros |
| historial | Josué | Abrir la lista | Muestra registros de los tres integrantes | Captura |
| historial | Josué | Seleccionar un registro | Muestra el detalle completo | Captura |
| ubicacion | Cody | Permiso concedido | Latitud, longitud, precisión y hora | Captura |
| ubicacion | Cody | Permiso denegado | Mensaje y opción de reintentar | Captura |
| estadisticas | Cody | Comparar conteos | Coinciden con la tabla | Captura de tabla y pantalla |
| estadisticas | Cody | Máximos y mínimos del acelerómetro | Coinciden con los datos guardados | Verificación manual |
| estadisticas | Cody | Gráfico de evolución | Mediciones en orden temporal | Captura |

---

## 10. Plan de trabajo por etapas

| Etapa | Qué se hace | Responsables |
|---|---|---|
| **Sprint 0** (días 1-2) | Crear proyecto Supabase compartido, aplicar migración inicial, crear estructura de carpetas, acordar `SensorReading` y las interfaces, crear CODEOWNERS, dejar stubs | Josué (base), Alberto (estructura), Cody (interfaz de ubicación) |
| **Sprint 1** (desarrollo) | Cada uno desarrolla sus features contra interfaces. Integración diaria a `develop` | Alberto: home, sensores. Josué: registro, historial. Cody: ubicacion, estadisticas |
| **Sprint 2** (integración) | Reemplazar stubs por implementaciones reales. Pruebas en dispositivo físico | Los tres |
| **Sprint 3** (cierre) | Documentación final, evidencias, ensayo de la demostración | Los tres; Alberto coordina entregables |

---

## 11. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Un cambio de esquema rompe a los demás | Solo Josué aplica migraciones, vía PR |
| Clave de Supabase en el repositorio | `--dart-define` y `.gitignore` desde el inicio |
| Datos de prueba mezclados con datos reales | Identificar con `capturado_por`; limpieza solo por Josué o el docente |
| Estadísticas no cuadran entre integrantes | Acordar desde el Sprint 0 si se filtra por `capturado_por` |
| GPS sin señal en interiores | Probar al aire libre y mostrar mensaje de espera |
| Sensores no disponibles en el emulador | Pruebas en dispositivo físico desde el Sprint 1 |
| Conflictos en `main.dart` y `app/` | Propiedad de Alberto y CODEOWNERS |
| Un integrante se atrasa y bloquea a otro | Stubs desde el día 1 y revisión diaria |

---

## 12. Checklist antes de la entrega

- [ ] Las cinco funcionalidades (M1 a M5) tienen responsable, código y pruebas en dispositivo físico.
- [ ] Hay evidencia de captura de acelerómetro, giroscopio y GPS.
- [ ] La tabla compartida tiene registros de cada `sensor_type` y de cada integrante.
- [ ] El script SQL, las migraciones y las políticas RLS están incluidos.
- [ ] No hay URLs ni claves reales en el repositorio.
- [ ] README, informe técnico, guía de configuración y plan de pruebas están completos.
- [ ] La política de uso de ubicación está publicada en la app.
- [ ] La demostración al docente tiene orden y responsable definidos.
