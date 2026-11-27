# Guía de permisos de ubicación

Responsable: Cody (feature `ubicacion` y permisos de ubicación, sección 5 del documento de arquitectura)

Esta guía explica qué permisos de ubicación usa SensorTrack, cómo están configurados en Android e iOS, qué ve el usuario en cada caso y cómo probarlos en un teléfono real.

> Resumen: la app pide la ubicación **solo en primer plano** y **solo cuando el usuario pulsa "Obtener ubicación"**, después de aceptar la política de uso. Nunca la lee en segundo plano.

---

## 1. Qué permisos usa y por qué

| Plataforma | Permiso | Para qué | ¿Se usa? |
|---|---|---|---|
| Android | `ACCESS_FINE_LOCATION` | Ubicación precisa por GPS (unos metros) | Sí |
| Android | `ACCESS_COARSE_LOCATION` | Ubicación aproximada por red. Desde Android 12 el usuario puede elegirla en lugar de la precisa | Sí |
| Android | `ACCESS_BACKGROUND_LOCATION` | Leer la ubicación con la app cerrada | **No.** La app no captura en segundo plano |
| iOS | `NSLocationWhenInUseUsageDescription` | Texto que explica el uso mientras la app está abierta | Sí, si se agrega iOS (sección 3) |
| iOS | `NSLocationAlwaysAndWhenInUseUsageDescription` | Ubicación siempre, también en segundo plano | **No** |

No pedir permisos de segundo plano cumple la consideración técnica del taller: *"No almacenar información de ubicación sin conocimiento y autorización del usuario"*. Además, la tienda no pide justificarlos.

---

## 2. Android

### 2.1 Manifiesto (ya configurado)

Archivo: [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml). Los permisos van como hijos directos de `<manifest>`, **antes** de `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

- Se declaran **los dos** de ubicación. Desde Android 12, el sistema muestra en un mismo diálogo la opción precisa y la aproximada; si solo se declarara `FINE`, la petición falla en esos teléfonos.
- `INTERNET` no es de ubicación, pero sin él la APK de release no puede guardar en Supabase.

### 2.2 Requisitos de compilación

- geolocator 14 necesita `compileSdk` 35 o mayor. El proyecto usa `flutter.compileSdkVersion`, que en la versión de Flutter del equipo es 36, así que **no hay que cambiar nada**.
- AndroidX ya viene activado en los proyectos creados con Flutter.

### 2.3 Qué ve el usuario

Al pulsar **Obtener ubicación** por primera vez:

1. **Política de uso de la app** (ver sección 5). Si pulsa *No acepto*, no se pide ningún permiso.
2. **Diálogo del sistema**, con dos decisiones:
   - *Precisa* o *Aproximada* (Android 12+).
   - *Mientras la app está en uso*, *Solo esta vez* o *No permitir*.

| Elección del usuario | Qué pasa en la app |
|---|---|
| Precisa + Mientras la app está en uso | Muestra latitud, longitud y una precisión de pocos metros |
| Aproximada | Funciona, pero la precisión baja a cientos de metros o más. La pantalla la muestra en "Precisión" |
| Solo esta vez | Funciona. Al cerrar la app, Android retira el permiso y la próxima vez vuelve a preguntar |
| No permitir (1.ª vez) | Mensaje *"Se necesita permiso de ubicación…"* y botón **Reintentar**, que vuelve a pedirlo |
| No permitir (2.ª vez) | Android ya no muestra el diálogo (Android 11+). Mensaje *"El permiso de ubicación está bloqueado…"* y botón **Abrir ajustes** |

### 2.4 Cambiar o restablecer el permiso a mano

Útil para repetir las pruebas de la sección 6:

**Ajustes → Aplicaciones → SensorTrack → Permisos → Ubicación**, y elegir *Preguntar siempre* o *No permitir*. En la misma pantalla está el interruptor **Usar ubicación precisa**.

Para dejar la app como recién instalada: **Ajustes → Aplicaciones → SensorTrack → Almacenamiento → Borrar datos**, o desinstalar y volver a instalar.

---

## 3. iOS

El repositorio **no tiene carpeta `ios/`** todavía: la app se prueba en Android. Si el equipo decide compilar para iPhone (se necesita una Mac con Xcode), estos son los pasos.

1. **Crear la plataforma** desde la raíz del proyecto:
   ```
   flutter create --platforms=ios .
   ```
2. **Texto del permiso** en `ios/Runner/Info.plist`, dentro del `<dict>` principal. Sin esta clave la app se cierra al pedir la ubicación:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>SensorTrack usa tu ubicación solo cuando pulsas "Obtener ubicación", para la práctica de medición del GPS. Las ubicaciones guardadas son visibles para el equipo del taller.</string>
   ```
3. **Evitar el permiso "siempre".** Por defecto geolocator también enlaza el código de ubicación en segundo plano, y Apple pide justificarlo. Agregar al final de `ios/Podfile`, dentro del bloque `post_install` que ya existe:
   ```ruby
   installer.pods_project.targets.each do |target|
     if target.name == "geolocator_apple"
       target.build_configurations.each do |config|
         config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'BYPASS_PERMISSION_LOCATION_ALWAYS=1']
       end
     end
   end
   ```
4. **No** agregar `UIBackgroundModes` → `location` ni la clave `NSLocationAlwaysAndWhenInUseUsageDescription`.

**Diferencia importante con Android:** iOS muestra el diálogo del permiso **una sola vez**. Si el usuario elige *No permitir*, la app recibe directamente "permiso bloqueado" y solo ofrece **Abrir ajustes** (**Ajustes → SensorTrack → Ubicación**). Las opciones son *Permitir una vez*, *Permitir al usar la app* y *No permitir*, más el interruptor *Ubicación exacta*.

---

## 4. Cómo lo maneja el código

Todo el acceso al GPS está en la feature `ubicacion`. Ninguna otra feature pide permisos de ubicación. Home solo consulta si el GPS está encendido, sin pedir permiso.

```
Usuario pulsa "Obtener ubicación"
  → ¿Aceptó la política en esta sesión?   no → diálogo de política → "No acepto" → fin
  → ¿GPS encendido?                       no → error gpsDesactivado
  → ¿Hay permiso? si no, se pide          denegado → permisoDenegado
                                          bloqueado → permisoDenegadoSiempre
  → Lectura única, hasta 20 s             sin respuesta → sinSenal
  → Muestra latitud, longitud, precisión, fecha y hora
  → (opcional) "Guardar medición" → registro → Supabase
```

| Problema (`ProblemaUbicacion`) | Mensaje en pantalla | Acción |
|---|---|---|
| `gpsDesactivado` | El GPS está desactivado. Actívalo para obtener la ubicación. | **Abrir ajustes** (ubicación del sistema) |
| `permisoDenegado` | Se necesita permiso de ubicación para mostrar las coordenadas. | **Reintentar** |
| `permisoDenegadoSiempre` | El permiso de ubicación está bloqueado. Habilítalo desde los ajustes de la aplicación. | **Abrir ajustes** (de la app) |
| `sinSenal` | No se recibió señal GPS. Prueba al aire libre y reintenta. | **Reintentar** |
| `desconocido` | No se pudo obtener la ubicación. | **Reintentar** |

Archivos:

- [`servicios/location_service.dart`](../lib/features/ubicacion/servicios/location_service.dart): comprueba el GPS, pide el permiso y traduce cada error de geolocator a `UbicacionException`.
- [`estado/ubicacion_estado.dart`](../lib/features/ubicacion/estado/ubicacion_estado.dart): impide capturar sin la política aceptada y arma la `SensorReading` de tipo `gps`.
- [`pantallas/ubicacion_page.dart`](../lib/features/ubicacion/pantallas/ubicacion_page.dart): muestra cada estado y su botón.
- [`widgets/politica_ubicacion.dart`](../lib/features/ubicacion/widgets/politica_ubicacion.dart): texto de la política.

---

## 5. Política de uso de ubicación (sección 7.4)

Se muestra en la app antes de la primera captura de cada sesión, y se puede volver a leer desde el ícono de privacidad de la barra superior de Ubicación:

- La ubicación se usa solo para la práctica de medición del GPS.
- Solo se captura cuando pulsas "Obtener ubicación". Nunca en segundo plano.
- Solo se guarda en la base de datos si pulsas "Guardar medición".
- Las ubicaciones guardadas son visibles para todo el equipo del taller.

Si cambia el texto, se cambia en `politica_ubicacion.dart` y en esta sección.

---

## 6. Pruebas en dispositivo físico

Las dos primeras filas son las del plan de pruebas (sección 9 del documento de arquitectura); el resto cubre los demás casos. Antes de cada prueba, restablecer el permiso como en 2.4.

| # | Preparación | Pasos | Resultado esperado | Evidencia | Resultado |
|---|---|---|---|---|---|
| 1 | Permiso en *Preguntar siempre*, GPS encendido, al aire libre | Obtener ubicación → Acepto → Precisa + Mientras la app está en uso | Latitud, longitud, precisión de pocos metros, fecha y hora | Captura | _pendiente_ |
| 2 | Igual que 1 | Obtener ubicación → Acepto → No permitir | Mensaje de permiso y **Reintentar** | Captura | _pendiente_ |
| 3 | Después de la 2 | Reintentar → No permitir otra vez | Mensaje de permiso bloqueado y **Abrir ajustes**, que abre los permisos de la app | Captura | _pendiente_ |
| 4 | GPS apagado desde el panel rápido | Obtener ubicación | Mensaje de GPS desactivado y **Abrir ajustes**, que abre la ubicación del sistema | Captura | _pendiente_ |
| 5 | Permiso concedido, interruptor *Ubicación precisa* apagado | Obtener ubicación | Funciona, con precisión de cientos de metros | Captura | _pendiente_ |
| 6 | Permiso concedido, en un lugar cerrado sin señal | Obtener ubicación | Tras 20 s como máximo, mensaje de sin señal y **Reintentar**. La app no se cierra | Captura | _pendiente_ |
| 7 | Primera vez en la sesión | Obtener ubicación → No acepto | No aparece el diálogo del sistema ni se lee el GPS | Captura | _pendiente_ |
| 8 | Con una ubicación en pantalla | Guardar medición | Registro `gps` con `latitude`, `longitude`, `accuracy` y sin `x`, `y`, `z` | Panel de Supabase | _pendiente_ |

Anotar en *Resultado* el modelo del teléfono, la versión de Android y si pasó.

---

## 7. Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---|---|---|
| Nunca aparece el diálogo del permiso | El permiso quedó bloqueado o falta en el manifiesto | Revisar 2.1 y restablecer el permiso (2.4) |
| Siempre dice "sin señal" | En interiores el GPS puede tardar minutos | Probar al aire libre o junto a una ventana |
| La precisión es de cientos de metros | El usuario eligió *Aproximada* | Activar *Usar ubicación precisa* en los permisos de la app |
| En el emulador no hay coordenadas | El emulador no tiene GPS real | Menú **⋯ → Location**, elegir un punto y pulsar **Set location**. Igual hay que probar en un teléfono |
| La app vuelve a pedir permiso cada vez | Se eligió *Solo esta vez* | Es lo esperado: Android lo retira al cerrar la app |
| En iOS la app se cierra al pedir ubicación | Falta `NSLocationWhenInUseUsageDescription` | Agregarla como en el paso 2 de la sección 3 |
