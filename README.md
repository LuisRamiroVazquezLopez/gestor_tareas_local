# Gestor de tareas local

Aplicación Flutter para administrar tareas con una base de datos **SQLite local**: sin servidor, sin MySQL y sin conexión a internet. Es la práctica «Gestor de tareas con SQLite» de Programación de Dispositivos Móviles (UAA), pensada para funcionar en Android, iOS, Windows, Linux, macOS y web con una sola base de código.

**Autor:** Luis Ramiro Vázquez López

## Estado del proyecto

| Etapa | Contenido | Estado |
| --- | --- | --- |
| 1 | Preparación y diseño: tecnología elegida y tabla de tareas | Hecha (este README) |
| 2 | Persistencia real: abrir la base, crear y consultar | Pendiente |
| 3 | Editar título, cambiar estado, eliminar, validaciones y errores | Pendiente |
| 4 | Web, pruebas automatizadas y verificación en plataformas | Pendiente |

Por ahora **todavía no hay persistencia**: la pantalla es la base entregada por el profesor y las operaciones solo muestran un aviso. Este README se actualiza en cada etapa.

## Tecnología de persistencia elegida

**SQLite con Drift y `drift_flutter`.**

- SQLite guarda los datos en un archivo en disco, así que sobreviven al cierre de la app. Una lista en memoria se pierde al reiniciar.
- `sqflite`, el paquete de la receta oficial de Flutter, solo admite Android, iOS y macOS. Drift cubre las seis plataformas: usa SQLite por `dart:ffi` en nativo y SQLite compilado a WebAssembly en web.
- `drift_flutter` abre la base correcta en cada plataforma con una sola llamada (`driftDatabase`).
- Las tablas se escriben en Dart, las consultas se pueden escuchar como `Stream` (la lista se actualiza sola después de escribir) y se pueden probar con una base en memoria.
- Drift genera código con `build_runner` (`database.g.dart`). Ese archivo se genera, no se escribe a mano.

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

## Organización del código (propuesta)

```
lib/
  main.dart        arranque de la app y tema
  models/          modelo Tarea (id, título, completada)
  data/            tabla, base de datos y operaciones (Drift)
  screens/         TareasPage: muestra la lista y lanza las acciones; sin consultas dentro de build()
test/              pruebas automatizadas
```

Esta organización se confirma al implementar la Etapa 2.

## Cómo ejecutarlo

Requisitos: Flutter (probado con 3.44.9 y Dart 3.12.2).

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
flutter run -d chrome
```

- `flutter analyze` muestra 1 aviso informativo (`prefer_final_fields`) del código base. Desaparece cuando la lista en memoria se reemplace por la base de datos.
- En macOS con Xcode 27 la compilación fallaba porque `MACOSX_DEPLOYMENT_TARGET` estaba en 10.15 y Xcode solo admite desde 12.0. Se cambió a 12.0 en `macos/Runner.xcodeproj/project.pbxproj` y ya viene aplicado en este repositorio.

## Plataformas

| Plataforma | Estado |
| --- | --- |
| macOS | Compila y abre la app base. Persistencia pendiente de probar |
| Web (Chrome) | Abre la app base. Persistencia pendiente de probar |
| Android, iOS, Windows, Linux | Previstas en el diseño; no probadas |

## Web (pendiente, Etapa 4)

En web, Drift necesita dos archivos dentro de `web/`: `sqlite3.wasm` y el worker de Drift, ambos del mismo release que la versión de `drift` del `pubspec.lock`. Aquí se documentará de dónde se descargan y cómo se comprobó que los datos sobreviven a recargar y a cerrar la pestaña en el mismo origen y perfil.

## Pruebas (pendiente)

Por ahora solo existe la prueba de arranque de la pantalla. Se agregarán pruebas de validación de entradas y de operaciones de almacenamiento con una base en memoria.

## Referencias

- [Drift](https://drift.simonbinder.eu/) y [Drift en web](https://drift.simonbinder.eu/platforms/web/)
- [drift_flutter](https://pub.dev/packages/drift_flutter)
- [Flutter: almacenamiento local con SQLite](https://docs.flutter.dev/cookbook/persistence/sqlite)
