# Guía de configuración de Supabase

Responsable: Josué (dueño del esquema y de `lib/shared/datos/`)

Los tres integrantes usan **un mismo proyecto de Supabase** y una sola tabla, `sensor_readings`. Esta guía explica cómo dejarlo listo, cómo conectar la app y cómo revisar los datos.

> Nunca subas al repositorio la URL ni la clave del proyecto. Van en `env/dev.json`, que está en `.gitignore`.

---

## 1. Crear el proyecto (solo Josué, una vez)

1. Entrar a [supabase.com](https://supabase.com) → **New project**.
2. Nombre: `sensortrack`. Región: la más cercana. Guardar la contraseña de la base en un lugar seguro: no la necesita la app.
3. Esperar a que el proyecto termine de crearse.

## 2. Agregar a los integrantes y al docente

**Organization settings → Team → Invite**, con el correo de cada uno.

- Alberto y Cody: rol **Developer**, para que puedan ver la tabla, los registros y los logs.
- Docente: el rol que pida.

Aunque el rol lo permita, **solo Josué cambia el esquema**, y siempre con una migración nueva en `supabase/migrations/` y un PR (sección 4.1 del documento de arquitectura). Si necesitas un cambio en la tabla, ábrelo como issue.

## 3. Aplicar las migraciones

Las migraciones están en `supabase/migrations/` y se aplican **en orden**, de la más antigua a la más nueva.

### Opción A: SQL Editor (recomendada para el taller)

1. En el panel: **SQL Editor → New query**.
2. Copiar el archivo completo, por ejemplo `20261125120000_crear_sensor_readings.sql`, y pulsar **Run**.
3. Debe terminar con `Success. No rows returned`.

### Opción B: Supabase CLI

```bash
supabase link --project-ref <ref-del-proyecto>
supabase db push
```

### Si la tabla ya existía

Si alguien creó `sensor_readings` a mano desde el panel siguiendo el taller, la migración 001 hace esto:

- **Si está vacía**, la borra y la vuelve a crear con la definición correcta.
- **Si tiene filas**, se detiene con el error `La tabla sensor_readings ya existe y tiene datos` y no modifica nada.

En el segundo caso, revisa los datos con `select * from sensor_readings;`. Si son de prueba, vacía la tabla con `truncate table public.sensor_readings;` y vuelve a ejecutar la migración. Si quieres conservarlos, primero expórtalos desde **Table Editor → Export to CSV**.

### Comprobar que quedó bien

```sql
-- Políticas: deben salir 2 (select e insert).
select policyname, cmd, roles from pg_policies where tablename = 'sensor_readings';

-- Permisos del rol anon: deben salir solo INSERT y SELECT.
select privilege_type from information_schema.role_table_grants
where table_name = 'sensor_readings' and grantee = 'anon';
```

## 4. Obtener la URL y la clave pública

**Project Settings → API Keys**:

- **URL del proyecto**: `https://<ref>.supabase.co`.
- **Publishable key**: empieza con `sb_publishable_`. Es la que usa la app.

> No uses nunca la **secret key** (`sb_secret_...`) ni la `service_role`. Esas claves saltan RLS y no deben estar en una app móvil.

La clave pública puede estar en la app porque RLS limita lo que permite: solo leer e insertar en `sensor_readings`.

## 5. Ejecutar la app

Es el mismo procedimiento del [README](../README.md#ejecución):

1. Copiar `env/ejemplo.json` como `env/dev.json`. `env/dev.json` está en `.gitignore`.
2. Completar los tres valores. `CAPTURADO_POR` es uno de los de la sección 6:

   ```json
   {
     "SUPABASE_URL": "https://<ref>.supabase.co",
     "SUPABASE_KEY": "sb_publishable_...",
     "CAPTURADO_POR": "josue"
   }
   ```

3. Ejecutar `flutter run --dart-define-from-file=env/dev.json`. En VS Code, usar la configuración **SensorTrack (env/dev.json)**.

Si ejecutas sin `SUPABASE_URL` y `SUPABASE_KEY`, la app arranca igual: Home muestra "Supabase sin configurar", y guardar o abrir el historial muestra *Supabase no está configurado*.

## 6. Valores de `capturado_por`

Cada integrante pone su valor en `CAPTURADO_POR`. La base solo acepta **minúsculas, sin tildes ni espacios**, para que los conteos por persona de estadísticas no se dividan entre "Josué", "josue" y "Josue ".

| Integrante | `CAPTURADO_POR` |
|---|---|
| Alberto | `alberto` |
| Josué | `josue` |
| Cody | `cody` |

## 7. Políticas RLS

RLS está activado en `sensor_readings`. La app usa el rol `anon` (clave pública, sin inicio de sesión).

| Rol | Operación | Condición |
|---|---|---|
| `anon`, `authenticated` | SELECT | Todas las filas (el historial muestra datos de los tres) |
| `anon`, `authenticated` | INSERT | Cualquier fila que cumpla las restricciones CHECK |
| `anon`, `authenticated` | UPDATE | No permitido: no hay política ni permiso |
| `anon`, `authenticated` | DELETE | No permitido: no hay política ni permiso |

El borrado de datos de prueba lo hacen Josué o el docente desde el panel, que usa el rol `postgres` y no pasa por RLS.

Restricciones de la tabla (las mismas que valida la app antes de enviar):

| Restricción | Regla |
|---|---|
| `sensor_readings_sensor_type_valido` | `sensor_type` es `accelerometer`, `gyroscope` o `gps` |
| `sensor_readings_campos_por_tipo` | Acelerómetro y giroscopio: solo `x`, `y`, `z`. GPS: solo `latitude`, `longitude`, `accuracy` |
| `sensor_readings_coordenadas_validas` | Latitud entre −90 y 90, longitud entre −180 y 180, precisión ≥ 0 |
| `sensor_readings_capturado_por_valido` | Minúsculas, empieza con letra, entre 2 y 30 caracteres |

## 8. Registro de migraciones

| Archivo | Fecha | Autor | Descripción |
|---|---|---|---|
| `20261125120000_crear_sensor_readings.sql` | 2026-11-25 | Josué | Tabla `sensor_readings` con `capturado_por`, CHECK por tipo, índices, GRANT y RLS (solo SELECT e INSERT) |

Para un cambio nuevo: crear `supabase/migrations/<AAAAMMDDHHMMSS>_<descripcion>.sql`, agregar una fila a esta tabla y abrir el PR. Las migraciones ya aplicadas no se editan.

## 9. Consultas para las evidencias

```sql
-- Registros por tipo y por integrante (evidencia de M3).
select sensor_type, capturado_por, count(*)
from sensor_readings
group by sensor_type, capturado_por
order by sensor_type, capturado_por;

-- Últimos 20 registros.
select * from sensor_readings order by recorded_at desc limit 20;
```

Para comparar con la pantalla de Estadísticas (pruebas "Comparar conteos" y "Máximos y mínimos del acelerómetro" del plan):

```sql
-- Total y conteo por sensor: deben coincidir con las tarjetas de Estadísticas.
select sensor_type, count(*) from sensor_readings group by sensor_type
union all
select 'total', count(*) from sensor_readings;

-- Máximos y mínimos por eje del acelerómetro.
select min(x), max(x), min(y), max(y), min(z), max(z), count(*)
from sensor_readings where sensor_type = 'accelerometer';

-- Última ubicación registrada.
select latitude, longitude, accuracy, recorded_at, capturado_por
from sensor_readings where sensor_type = 'gps'
order by recorded_at desc limit 1;
```

Estadísticas lee como máximo las últimas 5000 lecturas del acelerómetro. Con más registros, los máximos y mínimos de la pantalla pueden diferir de esta consulta.

Para borrar datos de prueba (solo Josué o el docente):

```sql
delete from sensor_readings where capturado_por = 'josue' and recorded_at < '2026-12-01';
```

## 10. Problemas frecuentes

| Mensaje en la app | Causa | Solución |
|---|---|---|
| *Supabase no está configurado* | Se ejecutó sin `--dart-define-from-file=env/dev.json` | Sección 5 |
| *La clave de Supabase no es válida* | `SUPABASE_KEY` mal copiada o revocada | Volver a copiarla (sección 4) |
| *La base de datos no permite esta operación* | Falta la migración 001 (sin GRANT ni políticas) | Sección 3 |
| *La tabla sensor_readings no existe* | No se aplicó la migración | Sección 3 |
| *CAPTURADO_POR debe ir en minúsculas…* | Valor con tilde, mayúscula o espacio | Usar los valores de la sección 6 |
| *No se pudo conectar con la base de datos* | Sin internet | Revisar la conexión del teléfono |
| *Espera N s antes de guardar otra medición* | Se pulsó Guardar dos veces seguidas | Es el límite de frecuencia: una medición cada 2 s |

Sin internet, las consultas de lectura tardan unos 7 s en mostrar el error, porque la librería reintenta 3 veces (supabase 2.16.5 no permite desactivar esos reintentos desde `SupabaseClient`). El repositorio corta cualquier operación a los 15 s.

## 11. Decisiones

Las decisiones de la base, del registro y del historial están en el registro común del equipo: [informe técnico, sección 10](informe_tecnico.md#10-registro-de-decisiones).
