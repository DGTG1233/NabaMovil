import 'package:flutter/foundation.dart';

import '../../data/repositories/avisos.dart';

/// Recuerda qué avisos ya se leyeron mientras la aplicación está abierta.
/// Al cerrarla se olvida: los avisos se vuelven a calcular de los datos.
class AvisosController extends ChangeNotifier {
  final Set<String> _leidos = {};

  bool estaLeido(String id) => _leidos.contains(id);

  int noLeidos(List<Aviso> avisos) =>
      avisos.where((a) => !_leidos.contains(a.id)).length;

  void marcarLeido(String id) {
    if (_leidos.add(id)) notifyListeners();
  }

  void marcarTodos(List<Aviso> avisos) {
    final antes = _leidos.length;
    _leidos.addAll(avisos.map((a) => a.id));
    if (_leidos.length != antes) notifyListeners();
  }
}
