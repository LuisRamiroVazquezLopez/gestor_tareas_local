# Gestor de tareas local

Aplicación Flutter para administrar tareas con una base de datos **SQLite local**: sin servidor, sin MySQL y sin conexión a internet. Es la práctica «Gestor de tareas con SQLite» de Programación de Dispositivos Móviles (UAA), pensada para funcionar en Android, iOS, Windows, Linux, macOS y web con una sola base de código.

**Autor:** Luis Ramiro Vázquez López

## Estado del proyecto

| Etapa | Contenido | Estado |
| --- | --- | --- |
| 1 | Preparación y diseño: tecnología elegida y tabla de tareas | Hecha (este README) |
| 2 | Persistencia real: abrir la base, crear y consultar | Hecha |
| 3 | Editar título, cambiar estado, eliminar, validaciones y errores | Pendiente |
| 4 | Web, pruebas automatizadas y verificación en plataformas | Pendiente |

Ya hay **persistencia real**: las tareas se guardan en una base SQLite y siguen ahí después de cerrar por completo la app y volver a abrirla (comprobado en macOS). Todavía no se puede editar, marcar ni eliminar: esos botones solo muestran un aviso hasta la Etapa 3. Este README se actualiza en cada etapa.

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

## Organización del código

```
lib/
  main.dart                 arranque de la app y tema; crea la base y se la pasa a la pantalla
  data/
    app_database.dart       tabla Tareas, clase AppDatabase y sus operaciones (Drift)
    app_database.g.dart     código generado por build_runner (no editar)
  screens/
    tareas_page.dart        TareasPage: lista con StreamBuilder; sin consultas dentro de build()
test/
  widget_test.dart          prueba de arranque con una base en memoria
```

La clase `Tarea` (id, título, completada) ya no se escribe a mano: la genera Drift a partir de la tabla. `AppDatabase` recibe opcionalmente el ejecutor de la base; sin argumento abre el archivo real, y las pruebas le pasan una base en memoria.

## Cómo ejecutarlo

Requisitos: Flutter (probado con 3.44.9 y Dart 3.12.2).

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
flutter run -d chrome
```

- `flutter analyze` debe terminar con «No issues found».
- Solo si cambias la tabla o la clase de la base, regenera el código: `dart run build_runner build`. La opción `--delete-conflicting-outputs` que aparece en algunas guías ya no existe en esta versión: `build_runner` avisa que la ignora.
- En macOS con Xcode 27 la compilación fallaba porque `MACOSX_DEPLOYMENT_TARGET` estaba en 10.15 y Xcode solo admite desde 12.0. Se cambió a 12.0 en `macos/Runner.xcodeproj/project.pbxproj` y ya viene aplicado en este repositorio.

## Plataformas

| Plataforma | Estado |
| --- | --- |
| macOS | Compila y guarda las tareas en SQLite; tres tareas agregadas siguen ahí tras cerrar y abrir la app. Edición, marcado y eliminación pendientes (Etapa 3) |
| Web (Chrome) | Pendiente de configurar (Etapa 4); hasta entonces no se garantiza que la base funcione en el navegador |
| Android, iOS, Windows, Linux | Previstas en el diseño; no probadas |

## Web (pendiente, Etapa 4)

En web, Drift necesita dos archivos dentro de `web/`: `sqlite3.wasm` y el worker de Drift, ambos del mismo release que la versión de `drift` del `pubspec.lock`. Aquí se documentará de dónde se descargan y cómo se comprobó que los datos sobreviven a recargar y a cerrar la pestaña en el mismo origen y perfil.

## Pruebas (pendiente)

Por ahora solo existe la prueba de arranque de la pantalla, que ya usa una base en memoria en lugar del archivo real. Se agregarán pruebas de validación de entradas y de operaciones de almacenamiento.

## Referencias

- [Drift](https://drift.simonbinder.eu/) y [Drift en web](https://drift.simonbinder.eu/platforms/web/)
- [drift_flutter](https://pub.dev/packages/drift_flutter)
- [Flutter: almacenamiento local con SQLite](https://docs.flutter.dev/cookbook/persistence/sqlite)
