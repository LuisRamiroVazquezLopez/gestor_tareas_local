# Gestor de tareas local

Aplicación Flutter para administrar tareas con una base de datos **SQLite local**: sin servidor, sin MySQL y sin conexión a internet. Es la práctica «Gestor de tareas con SQLite» de Programación de Dispositivos Móviles (UAA), pensada para funcionar en Android, iOS, Windows, Linux, macOS y web con una sola base de código.

**Autor:** Luis Ramiro Vázquez López

## Estado del proyecto

| Etapa | Contenido | Estado |
| --- | --- | --- |
| 1 | Preparación y diseño: tecnología elegida y tabla de tareas | Hecha (este README) |
| 2 | Persistencia real: abrir la base, crear y consultar | Hecha |
| 3 | Editar título, cambiar estado, eliminar, validaciones y errores | Hecha |
| 4 | Web, pruebas automatizadas y verificación en plataformas | Hecha (macOS y web; el resto de plataformas no se probó) |

La app agrega, lista, edita el título, marca como completada y elimina tareas, con persistencia real en SQLite: los datos siguen ahí después de cerrar por completo la app y volver a abrirla. Se comprobó en macOS y en Chrome (web). Un título vacío o con solo espacios no se registra, ni al agregar ni al editar.

## Tecnología de persistencia elegida

**SQLite con Drift y `drift_flutter`.**

- SQLite guarda los datos en un archivo en disco, así que sobreviven al cierre de la app. Una lista en memoria se pierde al reiniciar.
- `sqflite`, el paquete de la receta oficial de Flutter, solo admite Android, iOS y macOS. Drift cubre las seis plataformas: usa SQLite por `dart:ffi` en nativo y SQLite compilado a WebAssembly en web.
- `drift_flutter` abre la base correcta en cada plataforma con una sola llamada (`driftDatabase`).
- Las tablas se escriben en Dart, las consultas se pueden escuchar como `Stream` (la lista se actualiza sola después de escribir) y se pueden probar con una base en memoria.
- Drift genera código con `build_runner` (`app_database.g.dart`). Ese archivo se genera, no se escribe a mano; se incluye en el repositorio para que el proyecto compile sin volver a generarlo.

No se usa MySQL, API REST, `shared_preferences` ni una lista en memoria como almacenamiento.

## Diseño de la tabla `tareas`

| Columna | Tipo en SQLite | Restricciones | Descripción |
| --- | --- | --- | --- |
| `id` | `INTEGER` | clave primaria, autoincremental | Identificador único de la tarea |
| `titulo` | `TEXT` | `NOT NULL` | Texto de la tarea |
| `completada` | `INTEGER` (0 o 1) | `NOT NULL`, por defecto 0 | SQLite no tiene tipo booleano: 0 = pendiente, 1 = completada |

**Cómo se identifica cada registro:** por `id`. Lo asigna la base al insertar y el usuario nunca lo escribe. Editar el título, cambiar el estado y eliminar usan `WHERE id = ?`, así que dos tareas con el mismo título no se confunden.

| Función | Operación SQL |
| --- | --- |
| Agregar tarea | `INSERT` |
| Listar tareas | `SELECT` |
| Editar título o marcar completada | `UPDATE ... WHERE id = ?` |
| Eliminar tarea | `DELETE ... WHERE id = ?` |

**Validación:** un título vacío o formado solo por espacios no se registra. Se comprueba antes de tocar la base.

**Esquema real que crea Drift** (leído del archivo con `sqlite3 ... ".schema"`):

```sql
CREATE TABLE IF NOT EXISTS "tareas" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "titulo" TEXT NOT NULL,
  "completada" INTEGER NOT NULL DEFAULT 0 CHECK ("completada" IN (0, 1))
);
```

La restricción `CHECK` la agrega Drift al declarar la columna como booleana: la propia base rechaza cualquier valor distinto de 0 o 1.

## Dónde se guarda la base

`driftDatabase(name: 'tareas')` crea el archivo `tareas.sqlite`. En macOS, con el sandbox activado (la configuración por defecto de Flutter), queda dentro del contenedor de la app:

```
~/Library/Containers/com.example.gestorTareasLocal/Data/Documents/tareas.sqlite
```

Para ver su contenido con la app cerrada:

```bash
sqlite3 -readonly -header -column ~/Library/Containers/com.example.gestorTareasLocal/Data/Documents/tareas.sqlite "SELECT * FROM tareas;"
```

En web no hay archivo visible: Drift guarda los datos en **IndexedDB** del navegador, dentro del origen de la página (ver la sección Web). En las herramientas de desarrollo de Chrome, pestaña Application, aparece una base llamada `tareas`.

## Organización del código

```
lib/
  main.dart                 arranque de la app y tema; crea la base y se la pasa a la pantalla
  data/
    app_database.dart       tabla Tareas, clase AppDatabase y sus operaciones (Drift)
    app_database.g.dart     código generado por build_runner (no editar)
    validacion.dart         tituloValido: rechaza títulos vacíos o de solo espacios
  screens/
    tareas_page.dart        TareasPage: lista con StreamBuilder; sin consultas dentro de build()
test/
  validacion_test.dart      pruebas de validación de entradas
  almacenamiento_test.dart  pruebas de almacenamiento (memoria y archivo)
  widget_test.dart          prueba de arranque con una base en memoria
web/
  sqlite3.wasm              SQLite compilado a WebAssembly (release de Drift)
  drift_worker.js           worker de Drift (mismo release)
```

La clase `Tarea` (id, título, completada) ya no se escribe a mano: la genera Drift a partir de la tabla. `AppDatabase` recibe opcionalmente el ejecutor de la base; sin argumento abre el archivo real, y las pruebas le pasan una base en memoria.

## Cómo ejecutarlo

Requisitos: Flutter (probado con 3.44.9 y Dart 3.12.2).

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
flutter run -d chrome --web-port=8080
```

- `flutter analyze` debe terminar con «No issues found».
- En web conviene usar siempre el mismo puerto (`--web-port=8080`): los datos pertenecen al origen, y con otro puerto la base parecería vacía.
- Solo si cambias la tabla o la clase de la base, regenera el código: `dart run build_runner build`. La opción `--delete-conflicting-outputs` que aparece en algunas guías ya no existe en esta versión: `build_runner` avisa que la ignora.
- En macOS con Xcode 27 la compilación fallaba porque `MACOSX_DEPLOYMENT_TARGET` estaba en 10.15 y Xcode solo admite desde 12.0. Se cambió a 12.0 en `macos/Runner.xcodeproj/project.pbxproj` y ya viene aplicado en este repositorio.

## Plataformas

| Plataforma | Estado |
| --- | --- |
| macOS | Probada: P1 a P5 pasaron (ver Pruebas). Base en el contenedor de la app, ruta arriba |
| Web (Chrome) | Probada: P1 a P6 pasaron. Drift guarda en IndexedDB (`sharedIndexedDb`) |
| Android | No probada: licencias del SDK sin aceptar y sin emulador |
| iOS | No probada: no está instalado el runtime del simulador |
| Windows y Linux | No probadas: requieren compilar en cada sistema |

El código es el mismo para todas; solo las dos primeras se ejecutaron.

## Web

En web, SQLite corre compilado a WebAssembly dentro de un worker, así que `web/` necesita dos archivos del **mismo release** que la versión de `drift` del `pubspec.lock` (2.35.4):

| Archivo | Tamaño | Descarga |
| --- | --- | --- |
| `web/sqlite3.wasm` | 758 836 bytes | https://github.com/simolus3/drift/releases/download/drift-2.35.4/sqlite3.wasm |
| `web/drift_worker.js` | 363 283 bytes | https://github.com/simolus3/drift/releases/download/drift-2.35.4/drift_worker.js |

```bash
curl -L -o web/sqlite3.wasm https://github.com/simolus3/drift/releases/download/drift-2.35.4/sqlite3.wasm
curl -L -o web/drift_worker.js https://github.com/simolus3/drift/releases/download/drift-2.35.4/drift_worker.js
```

La consigna y algunos ejemplos de la documentación de Drift llaman al worker `drift_worker.dart.js`, pero ese archivo no existe en el release 2.35.4: el publicado se llama `drift_worker.js`, y ese nombre es el que usa `DriftWebOptions` en `lib/data/app_database.dart`. Si se actualiza `drift`, hay que volver a descargar ambos archivos del release nuevo.

**Dónde guarda.** Al abrir la app en Chrome, la consola muestra:

```
Using WasmStorageImplementation.sharedIndexedDb due to missing browser features: {MissingBrowserFeature.dedicatedWorkersInSharedWorkers, MissingBrowserFeature.sharedArrayBuffers}
```

Es un aviso informativo, no un error: Drift no pudo usar OPFS (el sistema de archivos privado del navegador) porque la página no tiene `SharedArrayBuffer`, que exige las cabeceras COOP y COEP, ni puede crear workers dedicados dentro de workers compartidos. Por eso guarda en IndexedDB mediante un worker compartido. Es más lento que OPFS, pero conserva los datos.

**Cómo se comprobó.** Con `flutter run -d chrome --web-port=8080` se agregaron tareas, se marcó una, se editó una y se eliminó una; se probó el título vacío; se recargó con F5; se detuvo la ejecución y se volvió a correr con el mismo comando; y se cerró y abrió la pestaña. Los datos permanecieron.

**Limitaciones.** Los datos web pertenecen al origen (esquema, host y puerto) y al perfil del navegador. El navegador puede borrarlos por presión de almacenamiento, porque el usuario borre los datos del sitio, o en modo privado. Solo se probó en Chrome; Safari y Firefox no.

## Pruebas

### Automatizadas (`flutter test`, 8 pruebas)

| Archivo | Qué cubre |
| --- | --- |
| `validacion_test.dart` (2) | `tituloValido` rechaza `null`, vacío y solo espacios, y devuelve el título sin espacios sobrantes |
| `almacenamiento_test.dart` (5) | Con base en memoria: agregar (el id lo asigna la base y la tarea queda pendiente), cambiar estado y título solo de la tarea indicada, eliminar por id (devuelve `false` si no existe) y que el `Stream` vuelve a emitir al escribir. Con archivo: escribir, cerrar y reabrir la base y comprobar que los datos permanecen |
| `widget_test.dart` (1) | La pantalla inicial se muestra con una base en memoria |

### Manuales (cerrar por completo y volver a abrir; no hot reload ni hot restart)

| ID | Acción | macOS | Web |
| --- | --- | --- | --- |
| P1 | Agregar tres tareas, cerrar la app y abrirla | Pasó | Pasó |
| P2 | Marcar una como completada y reiniciar | Pasó | Pasó |
| P3 | Cambiar el título de una tarea y reiniciar | Pasó | Pasó |
| P4 | Eliminar una tarea y reiniciar | Pasó | Pasó |
| P5 | Intentar agregar un título vacío | Pasó | Pasó |
| P6 | Recargar y cerrar/abrir la pestaña (mismo origen y perfil) | No aplica | Pasó |

## Referencias

- [Drift](https://drift.simonbinder.eu/) y [Drift en web](https://drift.simonbinder.eu/platforms/web/)
- [drift_flutter](https://pub.dev/packages/drift_flutter)
- [Flutter: almacenamiento local con SQLite](https://docs.flutter.dev/cookbook/persistence/sqlite)
- [Release drift-2.35.4 (sqlite3.wasm y drift_worker.js)](https://github.com/simolus3/drift/releases/tag/drift-2.35.4)
