# SensorTrack: informe técnico

Asignatura: Desarrollo de Plataformas Móviles
Integrantes: Alberto, Josué, Cody
Coordina: Alberto. Cada integrante redacta las secciones de sus features.

> Estado: todas las secciones están redactadas: 1, 2 y 3 (Alberto), 4 y 7 (Cody), 5, 6 y 8 (Josué). Faltan los resultados de las pruebas en dispositivo físico.

---

## 1. Arquitectura (Alberto)

La app se organiza **por features**: cada funcionalidad del taller es una carpeta en `lib/features/` con sus pantallas, su estado, sus servicios y sus pruebas. Lo que una feature ofrece a las demás se publica en un único archivo de entrada (`home.dart`, `sensores.dart`, etc.). El resto es interno.

```
lib/
├── main.dart        arranque
├── app/             MaterialApp, tema y rutas
├── core/            configuración, errores, constantes y tema (sin lógica de negocio)
├── shared/
│   ├── modelos/     SensorReading: una fila de sensor_readings
│   └── datos/       ReadingsRepository y su implementación en Supabase
└── features/        home · sensores · registro · historial · ubicacion · estadisticas
```

**Reglas**

1. Una feature no importa archivos internos de otra; solo su API pública, `core/` o `shared/`.
2. Las pantallas no hablan con Supabase ni con los sensores: lo hacen los servicios de la feature o el repositorio compartido.
3. Los errores se traducen a `AppException`, con una categoría (`conexion`, `permiso`, `sensor`, `validacion`) y un mensaje en español.
4. Los streams se cancelan al salir de la pantalla que los abrió.

**Comunicación entre features.** Las features se comunican de tres formas:

- **Modelo compartido:** `SensorReading`.
- **Repositorio compartido:** `ReadingsRepository`.
- **Widgets públicos:** por ejemplo, `GuardarMedicionButton` es de `registro` y se incrusta en la pantalla de `sensores`. Recibe una función que devuelve la lectura actual, así `registro` no depende de `sensores`.

**Estado.** Cada pantalla tiene un `ChangeNotifier` propio que crea al abrirse y libera al cerrarse. Sus dependencias se reciben por constructor, lo que permite probarlo con fuentes falsas sin sensores ni red.

## 2. M1 · Pantalla principal (`home`) (Alberto)

**Qué muestra**

- **Conexión con la base compartida.** Tiene cuatro estados:
  - *Sin configurar:* faltan `SUPABASE_URL` o `SUPABASE_KEY`.
  - *Comprobando.*
  - *Conectado.*
  - *Sin conexión:* incluye un botón para reintentar.

  Si la consulta tarda más de 5 segundos o falla, se considera sin conexión. La app nunca se cierra por falta de internet.
- **Integrante que firma las capturas** (`CAPTURADO_POR`), con un aviso si falta.
- **Sensores del dispositivo:**
  - Acelerómetro y giroscopio: la app se suscribe a cada sensor y espera la primera muestra hasta 2 segundos. Si llega un error o no llegan datos, el sensor figura como no disponible. La suscripción se cancela siempre.
  - GPS: se consulta si el servicio de ubicación está activado, sin pedir permiso. El permiso lo pide la pantalla Ubicación.
- **Menú** a Sensores, Ubicación, Historial y Estadísticas.

**Archivos:** `estado/home_estado.dart`, `servicios/detector_sensores.dart`, `widgets/tarjeta_conexion.dart`, `widgets/tarjeta_sensores.dart`, `widgets/menu_navegacion.dart`.

## 3. M2 · Acelerómetro y giroscopio (`sensores`) (Alberto)

**Qué hace**

- Selector de sensor, acelerómetro (m/s²) o giroscopio (rad/s), y tres tarjetas X, Y, Z. Cada tarjeta muestra el valor con tres decimales y una barra centrada en cero.
- Botones **Iniciar** y **Detener**, y la hora de la última muestra.
- Frecuencia de muestreo de 5, 15 o 50 Hz (`SensorInterval` de sensors_plus). Es aproximada: Android no garantiza la frecuencia pedida.
- Botón **Guardar medición** (de `registro`), que recibe una foto de la última muestra.

**Decisiones**

- **Un sensor a la vez.** El botón de guardar no tiene ambigüedad sobre qué lectura guarda y se abre una sola suscripción.
- **Guardado bajo pedido.** Solo se guarda cuando el usuario pulsa el botón, nunca cada evento del sensor. Así se evitan miles de registros (decisión "Frecuencia de guardado").
- **Hora de captura.** `recorded_at` es la hora del dispositivo al llegar la muestra.
- **Sin sensor.** Si el teléfono no tiene el sensor, sensors_plus emite un error (`NO_SENSOR` en Android, `UNAVAILABLE` en iOS). El servicio lo traduce a `AppException(sensor)` y la pantalla muestra el mensaje con **Reintentar**.
- **Escritorio.** En plataformas sin soporte (Windows) se informa de inmediato en vez de esperar datos que no llegan.
- **Ciclo de vida.** La suscripción se cancela al salir de la pantalla. Si la app pasa a segundo plano, se pausa, y se reanuda al volver solo si estaba leyendo.
- **Cambio de frecuencia.** El sistema operativo aplica la frecuencia al suscribirse, así que cambiarla con la lectura activa vuelve a suscribir.

**Archivos:** `servicios/sensor_service.dart`, `estado/sensores_estado.dart`, `pantallas/sensores_page.dart`, `widgets/tarjeta_eje.dart`.

## 4. M2 · GPS (`ubicacion`) (Cody)

**Qué hace**

- Botón **Obtener ubicación** que lee una sola posición del GPS y muestra latitud, longitud (6 decimales), precisión en metros, fecha y hora.
- Botón **Guardar medición** (de `registro`), visible solo cuando hay una posición. Recibe una `SensorReading` de tipo `gps` con `latitude`, `longitude` y `accuracy`, y sin `x`, `y`, `z`.
- Ícono en la barra para volver a leer la política de uso de ubicación.

**Decisiones**

- **Consentimiento antes de capturar.** La primera vez en cada sesión se muestra la política 7.4 (para qué se usa, que solo se captura al pulsar el botón, que solo se guarda al pulsar Guardar y que el equipo ve los datos). Si el usuario no acepta, no se lee el GPS.
- **Una lectura por pulsación, sin stream.** No hay captura continua ni en segundo plano, así que no queda ninguna suscripción abierta al salir. El manifiesto de Android pide solo ubicación en primer plano (`ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION`).
- **Permisos.** El permiso se pide al pulsar el botón. `LocationService` traduce cada caso a `UbicacionException`, un `AppException` con el problema concreto:
  - *GPS desactivado:* botón **Abrir ajustes** de ubicación del sistema.
  - *Permiso denegado:* botón **Reintentar**, que vuelve a pedirlo.
  - *Permiso bloqueado* (denegado para siempre): botón **Abrir ajustes** de la app.
  - *Sin señal:* la espera máxima es de 20 segundos. Luego se pide probar al aire libre y se ofrece **Reintentar**.
- **Hora de captura.** `recorded_at` es el `timestamp` de la posición que entrega geolocator.
- **Mapa.** Opcional y pendiente. Las coordenadas cubren el requisito del taller (decisión "Mapa").

**Archivos:** `servicios/location_service.dart`, `estado/ubicacion_estado.dart`, `pantallas/ubicacion_page.dart`, `widgets/politica_ubicacion.dart`.

## 5. M3 · Registro en Supabase (`registro`) (Josué)

`registro` no tiene pantalla propia. Publica un solo widget, **`GuardarMedicionButton`**, que Sensores (y más adelante Ubicación) pone como `floatingActionButton`. Recibe una función que devuelve la lectura actual, así `registro` no depende de la feature que lo usa.

**Qué hace al pulsar el botón**

1. Pide la lectura a la función. Si devuelve `null`, avisa *Todavía no hay datos del sensor para guardar*.
2. Comprueba la frecuencia máxima: **una medición cada 2 segundos**.
3. Valida la lectura con `ValidadorLectura`.
4. La guarda con `ReadingsRepository.guardar` y muestra el resultado en un SnackBar: *Medición guardada.* o el mensaje de error en rojo.

**Validación** (tabla 4.4 del documento de arquitectura)

| `sensor_type` | Debe traer | No debe traer |
|---|---|---|
| `accelerometer`, `gyroscope` | `x`, `y`, `z` finitos | `latitude`, `longitude`, `accuracy` |
| `gps` | latitud entre −90 y 90, longitud entre −180 y 180, precisión ≥ 0 | `x`, `y`, `z` |

`capturado_por` es obligatorio y va en minúsculas sin tildes (`alberto`, `josue`, `cody`). Son las mismas reglas que los CHECK de la base (sección 8): la app avisa antes de enviar, con un mensaje claro, y la base es la segunda barrera.

**Estados:** `inactivo`, `guardando`, `exito` y `error`. Mientras guarda, el botón muestra *Guardando…* y no responde a más toques.

**Errores.** El repositorio traduce todo a `AppException` con mensaje en español: sin internet o tiempo agotado (`conexion`), rechazo por RLS (`permiso`) y datos rechazados por la base (`validacion`). La app nunca se cierra al guardar sin conexión.

**Decisiones**

- **Frecuencia en `registro`.** Sensores ya guarda solo cuando el usuario lo pide. `registro` además impide dos guardados en menos de 2 s, para que los toques repetidos no dupliquen registros. Un guardado fallido no cuenta, así se puede reintentar enseguida.
- **Guardado después de salir.** Si el usuario sale de la pantalla mientras se guarda, la operación termina igual, pero el estado ya liberado no notifica.

**Archivos:** `widgets/guardar_medicion_button.dart`, `estado/registro_estado.dart`, `servicios/validador_lectura.dart`.

## 6. M4 · Historial (`historial`) (Josué)

**Qué muestra**

- **Lista** de las mediciones de los tres integrantes, de la más reciente a la más antigua. Cada fila trae el tipo, los valores principales, la fecha y hora local y quién la capturó.
- **Filtros:** por tipo (*Todos*, *Acelerómetro*, *Giroscopio*, *GPS*) y *Solo míos*, que filtra por el `CAPTURADO_POR` del teléfono. *Solo míos* no aparece si `CAPTURADO_POR` está vacío.
- **Paginación** de 20 registros. La página siguiente se pide al acercarse al final de la lista. También se puede actualizar deslizando hacia abajo o con el botón de la barra.
- **Detalle** al tocar un registro: todos los campos, con unidades (m/s², rad/s, grados, metros), la hora local y la hora UTC guardada.
- **Estados:** cargando, vacío (con un texto distinto si hay filtro), error con **Reintentar**, y *No existe el registro* en el detalle.

**Decisiones**

- **Respuestas viejas.** Si el usuario cambia de filtro antes de que llegue la respuesta anterior, esa respuesta se descarta.
- **Filas nuevas entre páginas.** Si otro integrante guarda mientras alguien recorre el historial, el desplazamiento se corre y podría repetirse una fila. Las filas repetidas se descartan por `id`.
- **Error al cargar más.** Se conserva lo que ya estaba cargado y se muestra **Reintentar** al final. El desplazamiento no reintenta por su cuenta.
- **Navegación al detalle.** La lista abre el detalle directamente y le pasa su misma consulta. La ruta `Rutas.detalleRegistro` del shell también funciona.

**Archivos:** `pantallas/historial_page.dart`, `pantallas/detalle_registro_page.dart`, `estado/historial_estado.dart`, `estado/detalle_registro_estado.dart`, `servicios/historial_consulta.dart`, `widgets/`.

## 7. M5 · Estadísticas (`estadisticas`) (Cody)

**Qué muestra**

- **Cantidad total de registros** y **mediciones por sensor** (acelerómetro, giroscopio y GPS).
- **Máximos y mínimos del acelerómetro** por eje (X, Y, Z), con el número de mediciones usadas.
- **Última ubicación registrada:** latitud, longitud, precisión y fecha.
- **Gráfico de evolución** (fl_chart) de X, Y y Z en orden temporal, con selector entre acelerómetro y giroscopio. Muestra las últimas 100 mediciones como máximo.
- Se actualiza deslizando hacia abajo o con el botón de la barra. Si falla la conexión, muestra el mensaje y **Reintentar**.

**Decisiones**

- **Solo a través del repositorio.** Los cálculos usan la interfaz `ReadingsRepository` (`contarPorTipo` y `listar`), nunca Supabase directamente. Así se prueban con un repositorio en memoria.
- **Máximos y mínimos en el teléfono.** Se leen las lecturas del acelerómetro en páginas de 500, con un tope de 5000. Si la tabla crece, conviene agregar al repositorio un método de agregación que lo calcule en la base.
- **Datos de los tres integrantes.** No se filtra por `capturado_por`: la tabla del taller no tiene esa columna y las estadísticas deben coincidir con la tabla completa (prueba "Comparar conteos").

**Archivos:** `servicios/estadisticas_calculo.dart`, `estado/estadisticas_estado.dart`, `pantallas/estadisticas_page.dart`, `widgets/grafico_evolucion.dart`.

## 8. Base de datos compartida (Josué)

Un solo proyecto de Supabase con una tabla, `sensor_readings`. El esquema se crea con la migración `supabase/migrations/20261125120000_crear_sensor_readings.sql`. La configuración paso a paso está en la [guía de Supabase](supabase_configuracion.md).

**Tabla `sensor_readings`**

| Columna | Tipo | Notas |
|---|---|---|
| `id` | `bigint` identity | Lo genera la base |
| `sensor_type` | `text` | `accelerometer`, `gyroscope` o `gps` |
| `x`, `y`, `z` | `double precision` | Solo acelerómetro y giroscopio |
| `latitude`, `longitude`, `accuracy` | `double precision` | Solo GPS |
| `recorded_at` | `timestamptz` | Hora real de captura, enviada por la app en UTC |
| `capturado_por` | `text` | Integrante: `alberto`, `josue` o `cody` |

**Restricciones:** tipo válido, campos según el tipo, rangos de coordenadas y formato de `capturado_por`. Son las mismas que valida `registro`.

**Índices:** `recorded_at` descendente, para el historial, y `(sensor_type, recorded_at)`, para el filtro por tipo y los conteos de estadísticas.

**Seguridad.** La app usa la clave pública con el rol `anon`. RLS está activado.

| Rol | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `anon`, `authenticated` | Todas las filas | Si cumple los CHECK | No | No |

Los permisos se dan con un `GRANT` explícito de SELECT e INSERT, que además quita TRUNCATE (TRUNCATE no pasa por RLS). Los datos de prueba los borran Josué o el docente desde el panel.

**Acceso desde la app.** Solo `lib/shared/datos/` habla con Supabase:

- `SupabaseService`: inicializa el cliente y comprueba la conexión para Home. Nunca lanza.
- `ReadingsRepository`: la interfaz que usan las features (`guardar`, `listar`, `obtenerPorId`, `contarPorTipo`).
- `SupabaseReadingsRepository`: la implementación. Ordena por `recorded_at` y `id`, pagina con `range`, cuenta con peticiones HEAD sin descargar filas y corta cada operación a los 15 s. Traduce los errores de PostgreSQL y de red a `AppException`.

**Limitación conocida.** supabase 2.16.5 ignora `retryEnabled` en `SupabaseClient.from()`. Por eso, sin internet, las lecturas reintentan 3 veces y tardan unos 7 s en mostrar el error.

## 9. Pruebas

| Área | Automáticas | En dispositivo físico |
|---|---|---|
| home | `test/features/home/home_estado_test.dart`, `test/widget_test.dart` | Sección 9 del documento de arquitectura: pendiente |
| sensores | `test/features/sensores/*_test.dart` | Sección 9: pendiente |
| ubicacion | `test/features/ubicacion/ubicacion_estado_test.dart` | Sección 9: pendiente |
| estadisticas | `test/features/estadisticas/estadisticas_calculo_test.dart` | Sección 9: pendiente |
| registro | `test/features/registro/*_test.dart` | Sección 9: pendiente |
| historial | `test/features/historial/*_test.dart` | Sección 9: pendiente |
| datos compartidos | `test/shared/datos/supabase_readings_repository_test.dart`, contra un servidor simulado | Evidencia en el panel de Supabase: pendiente |

`test/helpers/repositorio_en_memoria.dart` es un `ReadingsRepository` en memoria que cualquier feature puede usar en sus pruebas, con lecturas de ejemplo de los tres tipos.

## 10. Registro de decisiones

| Tema | Decisión | Alternativa | Motivo | Autor |
|---|---|---|---|---|
| Sensores en pantalla | Un sensor a la vez, con selector | Acelerómetro y giroscopio juntos | El botón de guardar sabe qué lectura guarda; una sola suscripción | Alberto |
| Hora de captura | Hora del dispositivo al llegar la muestra | `timestamp` del evento de sensors_plus | Igual en todas las plataformas | Alberto |
| Disponibilidad de sensores | Suscribirse y esperar la primera muestra hasta 2 s | Sin comprobación | sensors_plus no tiene una API para listar sensores | Alberto |
| GPS en Home | Solo si el servicio está activado, sin pedir permiso | Pedir permiso al abrir la app | El permiso se pide al capturar (política 7.4) | Alberto |
| Credenciales | `--dart-define-from-file=env/dev.json`, ignorado por Git | Solo `--dart-define` sueltos | Menos errores al ejecutar; el archivo nunca se sube | Alberto |
| Captura de GPS | Una lectura por pulsación, con política aceptada antes | Stream continuo de posiciones | No se guarda ubicación sin autorización; ninguna suscripción queda abierta | Cody |
| Máximos y mínimos | Calculados en el teléfono, hasta 5000 lecturas | Consulta de agregación en Supabase | La interfaz del repositorio no tiene agregaciones; se puede migrar después | Cody |
| Validación de lecturas | CHECK por tipo en la base y las mismas reglas en la app | Validar solo en la app | Ninguna versión de la app puede guardar filas inconsistentes; la app avisa antes con un mensaje claro | Josué |
| Formato de `capturado_por` | Minúsculas sin tildes: `alberto`, `josue`, `cody` | Texto libre | Los conteos por persona de estadísticas necesitan valores idénticos | Josué |
| Permisos de la tabla | `GRANT SELECT, INSERT` explícito al rol `anon`, más RLS | Depender de los permisos por defecto | En nuestro proyecto `anon` no tenía permisos (la API respondía 401); además se quitan UPDATE, DELETE y TRUNCATE | Josué |
| Tabla creada a mano | La migración la reemplaza solo si está vacía y se detiene si tiene datos | `create table if not exists` | `if not exists` dejaría en silencio una tabla sin restricciones ni RLS | Josué |
| Frecuencia de guardado en `registro` | Una medición cada 2 s; un fallo no cuenta | Sin límite | Evita registros duplicados por toques repetidos | Josué |
| Paginación del historial | Páginas de 20 por desplazamiento, descartando ids repetidos | Paginación por cursor | Respeta la interfaz `ReadingsRepository` acordada; si llegan filas nuevas entre páginas no se repiten | Josué |
