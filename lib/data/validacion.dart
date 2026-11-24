/// Devuelve el título limpio, o null si está vacío o solo tiene espacios.
String? tituloValido(String? texto) {
  final limpio = texto?.trim() ?? '';
  return limpio.isEmpty ? null : limpio;
}
