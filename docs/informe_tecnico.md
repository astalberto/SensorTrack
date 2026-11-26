# SensorTrack: informe técnico

Asignatura: Desarrollo de Plataformas Móviles
Integrantes: Alberto, Josué, Cody
Coordina: Alberto. Cada integrante redacta las secciones de sus features.

> Estado: las secciones 1, 2 y 3 están redactadas (Alberto), y la 4 y la 7 (Cody). Las secciones 5, 6 y 8 están pendientes.

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

_Pendiente: validación por `sensor_type`, estados de guardado, manejo de errores y frecuencia._

## 6. M4 · Historial (`historial`) (Josué)

_Pendiente: filtros, paginación y detalle._

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

_Pendiente: esquema de `sensor_readings`, restricciones, índices, políticas RLS y migraciones._

## 9. Pruebas

| Área | Automáticas | En dispositivo físico |
|---|---|---|
| home | `test/features/home/home_estado_test.dart`, `test/widget_test.dart` | Sección 9 del documento de arquitectura: pendiente |
| sensores | `test/features/sensores/*_test.dart` | Sección 9: pendiente |
| ubicacion | `test/features/ubicacion/ubicacion_estado_test.dart` | Sección 9: pendiente |
| estadisticas | `test/features/estadisticas/estadisticas_calculo_test.dart` | Sección 9: pendiente |
| Resto | _Cada responsable_ | _Cada responsable_ |

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
