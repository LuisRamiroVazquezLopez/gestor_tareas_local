import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/validacion.dart';

void main() {
  group('tituloValido', () {
    test('rechaza null, vacío y solo espacios', () {
      expect(tituloValido(null), isNull);
      expect(tituloValido(''), isNull);
      expect(tituloValido('   '), isNull);
      expect(tituloValido('\n\t '), isNull);
    });

    test('devuelve el título sin espacios sobrantes', () {
      expect(tituloValido('  Comprar pan  '), 'Comprar pan');
    });
  });
}
