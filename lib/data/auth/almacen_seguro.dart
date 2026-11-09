import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lugar donde se guardan los datos de acceso. Separarlo del plugin permite
/// probar la autenticación con un almacén en memoria.
abstract class AlmacenSeguro {
  Future<String?> leer(String clave);

  Future<void> escribir(String clave, String valor);

  Future<void> borrar(String clave);
}

/// Almacén real, apoyado en el almacenamiento seguro del teléfono.
class AlmacenSeguroFlutter implements AlmacenSeguro {
  final FlutterSecureStorage _storage;

  AlmacenSeguroFlutter([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> leer(String clave) => _storage.read(key: clave);

  @override
  Future<void> escribir(String clave, String valor) =>
      _storage.write(key: clave, value: valor);

  @override
  Future<void> borrar(String clave) => _storage.delete(key: clave);
}
