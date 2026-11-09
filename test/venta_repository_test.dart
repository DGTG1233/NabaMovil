import 'package:flutter_test/flutter_test.dart';
import 'package:nabamemovil/data/repositories/venta_repository.dart';
import 'package:nabamemovil/models/venta_estado.dart';

import 'soporte/datos_falsos.dart';

void main() {
  final laura = usuarioPrueba(id: 1, nombre: 'Laura', apellido: 'Peña');
  final jose = usuarioPrueba(id: 2, nombre: 'José', apellido: 'Ríos');

  final ventas = [
    ventaPrueba(id: 1, userId: 1, cliente: 'María Núñez', fecha: DateTime(2026, 9, 10)),
    ventaPrueba(
      id: 2,
      userId: 2,
      cliente: 'José Pérez',
      fecha: DateTime(2026, 10, 5),
      estado: VentaEstado.noEntregado,
    ),
    ventaPrueba(id: 3, userId: 1, cliente: 'Carlos Vela', fecha: DateTime(2026, 10, 2)),
  ];

  late List<VentaConVendedor> todas;

  setUp(() async {
    final repo = VentaRepository(DataSourceFalso([laura, jose], ventas));
    todas = await repo.ventasConVendedor();
  });

  test('ordena de la más reciente a la más antigua y asocia al vendedor', () {
    expect(todas.map((e) => e.venta.id), [2, 3, 1]);
    expect(todas.first.vendedor?.nombre, 'José');
  });

  test('la búsqueda ignora tildes y mayúsculas', () {
    final resultado = VentaRepository.filtrar(todas, consulta: 'JOSE PEREZ');
    expect(resultado.map((e) => e.venta.id), [2]);
  });

  test('la búsqueda también encuentra por nombre del vendedor', () {
    final resultado = VentaRepository.filtrar(todas, consulta: 'pena');
    expect(resultado.map((e) => e.venta.id), [3, 1]);
  });

  test('filtra por estado y por mes', () {
    final porEstado =
        VentaRepository.filtrar(todas, estado: VentaEstado.noEntregado);
    expect(porEstado.map((e) => e.venta.id), [2]);

    final porMes = VentaRepository.filtrar(todas, mes: '2026-10');
    expect(porMes.map((e) => e.venta.id), [2, 3]);
  });

  test('permite invertir el orden', () {
    final resultado =
        VentaRepository.filtrar(todas, masRecientesPrimero: false);
    expect(resultado.map((e) => e.venta.id), [1, 3, 2]);
  });
}