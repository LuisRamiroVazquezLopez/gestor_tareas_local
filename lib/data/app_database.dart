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
    : super(executor ?? driftDatabase(name: 'tareas'));

  @override
  int get schemaVersion => 1;

  /// Todas las tareas; se vuelve a emitir cuando la tabla cambia.
  Stream<List<Tarea>> observarTareas() =>
      (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<int> agregarTarea(String titulo) =>
      into(tareas).insert(TareasCompanion.insert(titulo: titulo));
}
