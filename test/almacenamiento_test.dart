import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';

void main() {
  group('AppDatabase en memoria', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
    });
    tearDown(() async => db.close());

    test('agrega una tarea pendiente con id asignado por la base', () async {
      final id = await db.agregarTarea('Estudiar Drift');
      final lista = await db.observarTareas().first;
      expect(lista, hasLength(1));
      expect(lista.first.id, id);
      expect(lista.first.titulo, 'Estudiar Drift');
      expect(lista.first.completada, false);
    });

    test('cambia estado y título solo de la tarea indicada', () async {
      final a = await db.agregarTarea('A');
      final b = await db.agregarTarea('B');

      expect(await db.cambiarEstado(a, true), true);
      expect(await db.editarTitulo(b, 'B editada'), true);

      final lista = await db.observarTareas().first;
      expect(lista.firstWhere((t) => t.id == a).completada, true);
      expect(lista.firstWhere((t) => t.id == a).titulo, 'A');
      expect(lista.firstWhere((t) => t.id == b).titulo, 'B editada');
      expect(lista.firstWhere((t) => t.id == b).completada, false);
    });

    test('elimina por id y devuelve false si el id no existe', () async {
      final id = await db.agregarTarea('Borrar');
      expect(await db.eliminarTarea(id), true);
      expect(await db.eliminarTarea(id), false);
      expect(await db.observarTareas().first, isEmpty);
    });

    test('el stream vuelve a emitir cuando se escribe', () async {
      final emisiones = <int>[];
      final sub = db.observarTareas().listen((l) => emisiones.add(l.length));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await db.agregarTarea('a');
      await db.agregarTarea('b');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(emisiones.first, 0);
      expect(emisiones.last, 2);
    });
  });

  test('los datos sobreviven a cerrar y volver a abrir el archivo', () async {
    final dir = await Directory.systemTemp.createTemp('tareas_test');
    addTearDown(() => dir.delete(recursive: true));
    final archivo = File('${dir.path}/tareas.sqlite');

    var db = AppDatabase(NativeDatabase(archivo));
    final id = await db.agregarTarea('Persistente');
    await db.cambiarEstado(id, true);
    await db.close();

    db = AppDatabase(NativeDatabase(archivo));
    final lista = await db.observarTareas().first;
    await db.close();

    expect(lista, hasLength(1));
    expect(lista.first.titulo, 'Persistente');
    expect(lista.first.completada, true);
  });
}
