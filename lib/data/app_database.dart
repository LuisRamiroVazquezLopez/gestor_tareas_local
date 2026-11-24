import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Tabla `tareas`. Drift genera de aquí la clase `Tarea`
/// (id, titulo, completada) y `TareasCompanion` para insertar.
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text()();
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  /// Sin argumento abre la base persistente; las pruebas pasarán una en memoria.
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'tareas',
              // Solo se usa en web: archivos que están en la carpeta web/.
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 1;

  /// Todas las tareas; se vuelve a emitir cuando la tabla cambia.
  Stream<List<Tarea>> observarTareas() =>
      (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<int> agregarTarea(String titulo) =>
      into(tareas).insert(TareasCompanion.insert(titulo: titulo));

  /// Marca o desmarca una tarea. Devuelve false si el id no existe.
  Future<bool> cambiarEstado(int id, bool completada) async {
    final filas = await (update(tareas)..where((t) => t.id.equals(id))).write(
      TareasCompanion(completada: Value(completada)),
    );
    return filas > 0;
  }

  /// Cambia solo el título. Devuelve false si el id no existe.
  Future<bool> editarTitulo(int id, String titulo) async {
    final filas = await (update(tareas)..where((t) => t.id.equals(id))).write(
      TareasCompanion(titulo: Value(titulo)),
    );
    return filas > 0;
  }

  /// Elimina por id. Devuelve false si el id no existe.
  Future<bool> eliminarTarea(int id) async {
    final filas = await (delete(tareas)..where((t) => t.id.equals(id))).go();
    return filas > 0;
  }
}
