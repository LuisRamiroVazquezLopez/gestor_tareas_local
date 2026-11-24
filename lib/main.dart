import 'package:flutter/material.dart';
import 'data/app_database.dart';
import 'screens/tareas_page.dart';

void main() {
  // Una sola base para toda la app; se abre al primer uso.
  runApp(GestorTareasApp(db: AppDatabase()));
}

/// Punto de entrada de la aplicación.
/// Recibe la base de datos para poder cambiarla en las pruebas.
class GestorTareasApp extends StatelessWidget {
  const GestorTareasApp({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(db: db),
    );
  }
}
