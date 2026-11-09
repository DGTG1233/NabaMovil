import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../../models/caso_morosidad.dart';
import '../../models/usuario.dart';
import '../../models/venta.dart';
import '../../models/pago.dart';
import 'data_source.dart';

/// Implementación de [DataSource] con datos de prueba cargados desde
/// archivos JSON empaquetados en el proyecto (lib/mock_data/). Simula
/// una latencia de red para que la UI se comporte igual que si estuviera
/// consumiendo una API real (estados de carga, posibilidad de error).
class MockDataSource implements DataSource {
  static const _latencia = Duration(milliseconds: 400);

  List<Usuario>? _usuariosCache;
  List<Venta>? _ventasCache;
  List<Pago>? _pagosCache;
  List<CasoMorosidad>? _morosidadCache;

  @override
  Future<List<Usuario>> getUsuarios() async {
    await Future.delayed(_latencia);
    if (_usuariosCache != null) return _usuariosCache!;
    final data = await _leerJson('lib/mock_data/usuarios.json');
    _usuariosCache = data.map((e) => Usuario.fromJson(e)).toList();
    return _usuariosCache!;
  }

  @override
  Future<List<Venta>> getVentas() async {
    await Future.delayed(_latencia);
    if (_ventasCache != null) return _ventasCache!;
    final data = await _leerJson('lib/mock_data/ventas.json');
    _ventasCache = data.map((e) => Venta.fromJson(e)).toList();
    return _ventasCache!;
  }

  @override
  Future<List<Pago>> getPagos() async {
    await Future.delayed(_latencia);
    if (_pagosCache != null) return _pagosCache!;
    final data = await _leerJson('lib/mock_data/pagos.json');
    _pagosCache = data.map((e) => Pago.fromJson(e)).toList();
    return _pagosCache!;
  }

  @override
  Future<List<CasoMorosidad>> getMorosidad() async {
    await Future.delayed(_latencia);
    if (_morosidadCache != null) return _morosidadCache!;
    final data = await _leerJson('lib/mock_data/morosidad.json');
    _morosidadCache = data.map((e) => CasoMorosidad.fromJson(e)).toList();
    return _morosidadCache!;
  }

  Future<List<Map<String, dynamic>>> _leerJson(String assetPath) async {
    final contenido = await rootBundle.loadString(assetPath);
    final decodificado = jsonDecode(contenido) as List<dynamic>;
    return decodificado.cast<Map<String, dynamic>>();
  }
}