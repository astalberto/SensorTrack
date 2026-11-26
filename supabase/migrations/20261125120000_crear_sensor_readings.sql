-- =============================================================================
-- Migración 001: tabla compartida `sensor_readings`
-- Fecha:       2026-11-25
-- Responsable: Josué (dueño del esquema)
--
-- Crea la tabla del taller con el campo adicional `capturado_por` y aplica las
-- mejoras de la sección 4.4 del documento de arquitectura:
--   1. `sensor_type` solo acepta accelerometer, gyroscope o gps.
--   2. Cada tipo trae solo sus campos (x, y, z  o  latitude, longitude, accuracy).
--   3. Índices para el historial (más recientes primero) y el filtro por tipo.
--   4. RLS activado: la app (rol anon) solo puede hacer INSERT y SELECT.
--
-- Cómo aplicarla: docs/supabase_configuracion.md, sección 3.
-- El SQL Editor y `supabase db push` ejecutan el archivo como una sola
-- transacción: si algún paso falla, no queda ningún cambio a medias.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. Tabla previa creada a mano
-- -----------------------------------------------------------------------------
-- Si alguien ya creó `sensor_readings` desde el panel siguiendo el taller, se
-- reemplaza por la versión de esta migración, pero SOLO si está vacía. Si tiene
-- filas, la migración se detiene sin borrar nada.
do $$
begin
  if to_regclass('public.sensor_readings') is not null then
    if exists (select 1 from public.sensor_readings) then
      raise exception 'La tabla sensor_readings ya existe y tiene datos. Respáldalos y vacíala antes de aplicar esta migración (ver docs/supabase_configuracion.md).';
    end if;
    drop table public.sensor_readings;
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- 1. Tabla
-- -----------------------------------------------------------------------------
create table public.sensor_readings (
  -- La base genera el id; la app nunca lo envía.
  id            bigint generated always as identity primary key,

  sensor_type   text             not null,

  -- Acelerómetro (m/s²) y giroscopio (rad/s).
  x             double precision,
  y             double precision,
  z             double precision,

  -- GPS: grados decimales y precisión en metros.
  latitude      double precision,
  longitude     double precision,
  accuracy      double precision,

  -- Hora real de la captura. La app la envía siempre; el valor por defecto
  -- solo cubre inserciones manuales desde el panel.
  recorded_at   timestamptz      not null default now(),

  -- Integrante que hizo la captura (sección 4.2). Valores acordados:
  -- alberto, josue, cody.
  capturado_por text             not null,

  constraint sensor_readings_sensor_type_valido
    check (sensor_type in ('accelerometer', 'gyroscope', 'gps')),

  -- Tabla 4.4: cada tipo de sensor llena solo sus columnas.
  constraint sensor_readings_campos_por_tipo check (
    (
      sensor_type in ('accelerometer', 'gyroscope')
      and x is not null and y is not null and z is not null
      and latitude is null and longitude is null and accuracy is null
    )
    or
    (
      sensor_type = 'gps'
      and latitude is not null and longitude is not null and accuracy is not null
      and x is null and y is null and z is null
    )
  ),

  constraint sensor_readings_coordenadas_validas check (
    (latitude  is null or latitude  between  -90 and  90)
    and (longitude is null or longitude between -180 and 180)
    and (accuracy  is null or accuracy >= 0)
  ),

  -- Minúsculas, sin tildes ni espacios, para que los conteos por persona de
  -- estadísticas no se dividan entre "Josué", "josue" y "Josue ".
  constraint sensor_readings_capturado_por_valido
    check (capturado_por ~ '^[a-z][a-z0-9_]{1,29}$')
);

comment on table public.sensor_readings is
  'Lecturas de acelerómetro, giroscopio y GPS capturadas por el equipo SensorTrack.';
comment on column public.sensor_readings.capturado_por is
  'Integrante que hizo la captura (alberto, josue, cody). Lo envía la app desde CAPTURADO_POR.';
comment on column public.sensor_readings.recorded_at is
  'Hora real de la captura en el dispositivo, en UTC.';

-- -----------------------------------------------------------------------------
-- 2. Índices
-- -----------------------------------------------------------------------------
-- Historial sin filtro: más recientes primero.
create index sensor_readings_recorded_at_idx
  on public.sensor_readings (recorded_at desc);

-- Historial filtrado por tipo y conteos por tipo de estadísticas.
create index sensor_readings_tipo_recorded_at_idx
  on public.sensor_readings (sensor_type, recorded_at desc);

-- -----------------------------------------------------------------------------
-- 3. Permisos
-- -----------------------------------------------------------------------------
-- No se depende de los permisos por defecto del proyecto: sin este GRANT la
-- API respondía "permission denied for table sensor_readings" al rol anon.
-- Se quitan todos los permisos (incluido TRUNCATE, que no pasa por RLS) y se
-- dan solo SELECT e INSERT.
-- (Las columnas identity no necesitan permiso sobre su secuencia.)
revoke all on table public.sensor_readings from anon, authenticated;
grant select, insert on table public.sensor_readings to anon, authenticated;

-- -----------------------------------------------------------------------------
-- 4. Row Level Security
-- -----------------------------------------------------------------------------
-- | Rol                 | Operación | Condición                        |
-- |---------------------|-----------|----------------------------------|
-- | anon, authenticated | SELECT    | todas las filas (ver datos de 3) |
-- | anon, authenticated | INSERT    | cualquier fila que pase los CHECK|
-- | anon, authenticated | UPDATE    | no permitido (sin política)      |
-- | anon, authenticated | DELETE    | no permitido (sin política)      |
--
-- El borrado de datos de prueba lo hace Josué o el docente desde el panel,
-- que usa el rol postgres y no pasa por RLS.
alter table public.sensor_readings enable row level security;

create policy "app_lee_todas_las_lecturas"
  on public.sensor_readings
  for select
  to anon, authenticated
  using (true);

create policy "app_inserta_lecturas"
  on public.sensor_readings
  for insert
  to anon, authenticated
  with check (true);
