# SensorTrack: informe técnico

Asignatura: Desarrollo de Plataformas Móviles
Integrantes: Alberto, Josué, Cody
Coordina: Alberto. Cada integrante redacta las secciones de sus features.

> Estado: las secciones 1, 2 y 3 están redactadas (Alberto). Las secciones 4 a 7 están pendientes.

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

_Pendiente: permisos, estados de captura, política de uso de ubicación (7.4) y mapa opcional._

## 5. M3 · Registro en Supabase (`registro`) (Josué)

_Pendiente: validación por `sensor_type`, estados de guardado, manejo de errores y frecuencia._

## 6. M4 · Historial (`historial`) (Josué)

_Pendiente: filtros, paginación y detalle._

## 7. M5 · Estadísticas (`estadisticas`) (Cody)

_Pendiente: conteos, máximos y mínimos, última ubicación, gráfico y filtro por `capturado_por`._

## 8. Base de datos compartida (Josué)

_Pendiente: esquema de `sensor_readings`, restricciones, índices, políticas RLS y migraciones._

## 9. Pruebas

| Área | Automáticas | En dispositivo físico |
|---|---|---|
| home | `test/features/home/home_estado_test.dart`, `test/widget_test.dart` | Sección 9 del documento de arquitectura: pendiente |
| sensores | `test/features/sensores/*_test.dart` | Sección 9: pendiente |
| Resto | _Cada responsable_ | _Cada responsable_ |

## 10. Registro de decisiones

| Tema | Decisión | Alternativa | Motivo | Autor |
|---|---|---|---|---|
| Sensores en pantalla | Un sensor a la vez, con selector | Acelerómetro y giroscopio juntos | El botón de guardar sabe qué lectura guarda; una sola suscripción | Alberto |
| Hora de captura | Hora del dispositivo al llegar la muestra | `timestamp` del evento de sensors_plus | Igual en todas las plataformas | Alberto |
| Disponibilidad de sensores | Suscribirse y esperar la primera muestra hasta 2 s | Sin comprobación | sensors_plus no tiene una API para listar sensores | Alberto |
| GPS en Home | Solo si el servicio está activado, sin pedir permiso | Pedir permiso al abrir la app | El permiso se pide al capturar (política 7.4) | Alberto |
| Credenciales | `--dart-define-from-file=env/dev.json`, ignorado por Git | Solo `--dart-define` sueltos | Menos errores al ejecutar; el archivo nunca se sube | Alberto |
