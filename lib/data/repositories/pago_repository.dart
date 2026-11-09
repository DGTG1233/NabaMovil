import '../datasource/data_source.dart';
import 'historial_pagos.dart';

class PagoRepository {
  final DataSource dataSource;

  PagoRepository(this.dataSource);

  Future<HistorialPagos> cargar() async {
    final pagos = await dataSource.getPagos();
    final usuarios = await dataSource.getUsuarios();
    return HistorialPagos.construir(pagos: pagos, usuarios: usuarios);
  }
}
