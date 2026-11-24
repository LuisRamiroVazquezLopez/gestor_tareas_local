import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/validacion.dart';

// Pantalla base SIN persistencia ni operaciones CRUD implementadas.
// Conserva las indicaciones TODO para orientar tu trabajo.
class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.db});

  final AppDatabase db;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  // Se crea una sola vez; así el StreamBuilder no vuelve a consultar en cada build().
  late final Stream<List<Tarea>> _tareas = widget.db.observarTareas();

  /// Ejecuta una escritura y avisa si la base falla, en lugar de dejar la
  /// excepción sin atender. Devuelve true si se guardó.
  Future<bool> _guardar(Future<Object?> Function() operacion) async {
    try {
      await operacion();
      return true;
    } catch (e) {
      if (mounted) {
        _pendiente('No se pudo guardar el cambio. Intenta de nuevo.');
      }
      return false;
    }
  }

  Future<void> _agregarTarea() async {
    final titulo = tituloValido(_tituloController.text);
    if (titulo == null) {
      _pendiente('El título no puede estar vacío');
      return;
    }
    if (await _guardar(() => widget.db.agregarTarea(titulo))) {
      _tituloController.clear();
    }
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    await _guardar(() => widget.db.cambiarEstado(tarea.id, completada));
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditar(inicial: tarea.titulo),
    );
    if (nuevo == null || !mounted) return; // canceló
    final titulo = tituloValido(nuevo);
    if (titulo == null) {
      _pendiente('El título no puede estar vacío');
      return;
    }
    await _guardar(() => widget.db.editarTitulo(tarea.id, titulo));
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    await _guardar(() => widget.db.eliminarTarea(tarea.id));
  }

  void _pendiente(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Tarea>>(
                stream: _tareas,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('No se pudieron leer las tareas'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tareas = snapshot.data!;
                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }
                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: tarea.completada,
                            onChanged: (valor) {
                              if (valor != null) {
                                _alternarCompletada(tarea, valor);
                              }
                            },
                          ),
                          title: Text(tarea.titulo),
                          subtitle: Text('ID: ${tarea.id}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarTarea(tarea),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _eliminarTarea(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuadro para editar el título. Es un widget aparte para poder liberar su
/// controlador en dispose().
class _DialogoEditar extends StatefulWidget {
  const _DialogoEditar({required this.inicial});

  final String inicial;

  @override
  State<_DialogoEditar> createState() => _DialogoEditarState();
}

class _DialogoEditarState extends State<_DialogoEditar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.inicial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Título'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
