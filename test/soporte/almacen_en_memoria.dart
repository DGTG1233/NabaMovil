import 'package:nabamemovil/data/auth/almacen_seguro.dart';

/// Almacén de prueba que guarda todo en un mapa.
class AlmacenEnMemoria implements AlmacenSeguro {
  final Map<String, String> datos = {};

  @override
  Future<String?> leer(String clave) async => datos[clave];

  @override
  Future<void> escribir(String clave, String valor) async {
    datos[clave] = valor;
  }

  @override
  Future<void> borrar(String clave) async {
    datos.remove(clave);
  }
}
