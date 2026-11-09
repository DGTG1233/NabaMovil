import 'package:flutter_test/flutter_test.dart';
import 'package:nabamemovil/data/repositories/arbol_equipo.dart';
import 'package:nabamemovil/data/repositories/venta_repository.dart';
import 'package:nabamemovil/models/venta_estado.dart';

import 'soporte/datos_falsos.dart';

void main() {
  const mes = '2026-10';

  // Socio 10 con dos supervisores. El 11 tiene a los vendedores 1 y 2; el 12
  // tiene al 3 y al 4 (inactivo). El vendedor 5 no tiene superior. El
  // administrador y el visor apuntan al socio pero no son de la cadena.
  final usuarios = [
    usuarioPrueba(id: 10, nombre: 'Ricardo', apellido: 'Mori', tipo: 'socio_comercial'),
    usuarioPrueba(id: 11, nombre: 'Luciana', apellido: 'Grandez', tipo: 'supervisor', supervisorId: 10),
    usuarioPrueba(id: 12, nombre: 'Marco', apellido: 'Caceres', tipo: 'supervisor', supervisorId: 10),
    usuarioPrueba(id: 1, nombre: 'Katherine', apellido: 'Rios', tipo: 'full_time', supervisorId: 11, cuota: 10),
    usuarioPrueba(id: 2, nombre: 'Jhonatan', apellido: 'Paredes', tipo: 'part_time', supervisorId: 11, cuota: 10),
    usuarioPrueba(id: 3, nombre: 'Milagros', apellido: 'Tuesta', supervisorId: 12, cuota: 20),
    usuarioPrueba(id: 4, nombre: 'Renzo', apellido: 'Vasquez', supervisorId: 12, activo: false, cuota: 10),
    usuarioPrueba(id: 5, nombre: 'Yesenia', apellido: 'Del Aguila', tipo: 'part_time', cuota: 5),
    usuarioPrueba(id: 98, tipo: 'visor', supervisorId: 10),
    usuarioPrueba(id: 99, tipo: 'admin', supervisorId: 10),
  ];

  final ventas = [
    ventaPrueba(id: 1, userId: 1, fecha: DateTime(2026, 10, 2), comision: 50),
    ventaPrueba(id: 2, userId: 1, fecha: DateTime(2026, 10, 3), comision: 30),
    ventaPrueba(id: 3, userId: 1, fecha: DateTime(2026, 10, 4), estado: VentaEstado.noEntregado),
    ventaPrueba(id: 4, userId: 2, fecha: DateTime(2026, 10, 5), comision: 40),
    ventaPrueba(id: 5, userId: 3, fecha: DateTime(2026, 10, 6), comision: 100),
    ventaPrueba(id: 6, userId: 4, fecha: DateTime(2026, 10, 7), comision: 20),
    ventaPrueba(id: 7, userId: 5, fecha: DateTime(2026, 10, 8), comision: 15),
    ventaPrueba(id: 8, userId: 1, fecha: DateTime(2026, 9, 20), comision: 999),
  ];

  late ArbolEquipo arbol;

  NodoEquipo nodo(int id) =>
      arbol.todos.firstWhere((n) => n.persona.id == id);

  setUp(() {
    arbol = ArbolEquipo.construir(usuarios: usuarios, ventas: ventas, mes: mes);
  });

  test('arma la jerarquía y deja fuera a quien no es de la cadena de ventas', () {
    expect(arbol.raices.map((n) => n.persona.id), [10]);
    expect(nodo(10).miembros.map((n) => n.persona.id), [11, 12]);
    expect(nodo(11).miembros.map((n) => n.persona.id), [1, 2]);
    expect(arbol.sinSuperior.map((n) => n.persona.id), [5]);

    final ids = arbol.todos.map((n) => n.persona.id);
    expect(ids, isNot(contains(98)));
    expect(ids, isNot(contains(99)));
  });

  test('cada nodo conoce a su superior directo', () {
    expect(nodo(1).superior?.id, 11);
    expect(nodo(11).superior?.id, 10);
    expect(nodo(10).superior, isNull);
    expect(nodo(5).superior, isNull);
  });

  test('suma ventas entregadas y comisión del mes sobre el equipo completo', () {
    // El vendedor 1 tiene una venta no entregada y otra de septiembre:
    // ninguna de las dos cuenta.
    expect(nodo(1).ventasEntregadas, 2);
    expect(nodo(1).comisionMes, 80);

    expect(nodo(11).ventasEntregadas, 3);
    expect(nodo(11).comisionMes, 120);

    expect(nodo(12).ventasEntregadas, 2);
    expect(nodo(12).comisionMes, 120);

    expect(nodo(10).ventasEntregadas, 5);
    expect(nodo(10).comisionMes, 240);
  });

  test('un mes sin ventas deja todo en cero', () {
    final agosto = ArbolEquipo.construir(
      usuarios: usuarios,
      ventas: ventas,
      mes: '2026-08',
    );
    expect(agosto.ventasEntregadas, 0);
    expect(agosto.comisionMes, 0);
    expect(agosto.personas, 7);
  });

  test('cuenta como personas a cargo solo a los activos', () {
    expect(nodo(11).personasACargo, 2);
    expect(nodo(12).personasACargo, 1);
    expect(nodo(10).personasACargo, 5);
    expect(nodo(1).personasACargo, 0);
  });

  test('la cuota suma solo activos y el rendimiento mide lo mismo', () {
    expect(nodo(11).cuotaMes, 20);
    expect(nodo(11).rendimiento, closeTo(0.15, 0.0001));

    // El inactivo (4) entregó una venta pero no entra en la cuota.
    expect(nodo(12).cuotaMes, 20);
    expect(nodo(12).ventasParaCuota, 1);
    expect(nodo(12).rendimiento, closeTo(0.05, 0.0001));

    expect(nodo(10).cuotaMes, 40);
    expect(nodo(10).rendimiento, closeTo(0.1, 0.0001));
  });

  test('sin cuota no hay rendimiento', () {
    final sinCuota = ArbolEquipo.construir(
      usuarios: [usuarioPrueba(id: 1)],
      ventas: [ventaPrueba(id: 1, userId: 1, fecha: DateTime(2026, 10, 2), comision: 10)],
      mes: mes,
    );
    expect(sinCuota.sinSuperior.single.cuotaMes, isNull);
    expect(sinCuota.sinSuperior.single.rendimiento, isNull);
  });

  test('ordena por ventas entregadas y deja a los inactivos al final', () {
    expect(nodo(11).miembros.map((n) => n.persona.id), [1, 2]);
    expect(nodo(12).miembros.map((n) => n.persona.id), [3, 4]);
    expect(nodo(10).miembros.map((n) => n.persona.id), [11, 12]);
  });

  test('separa a los inactivos sin equipo de la lista principal', () {
    expect(nodo(12).miembrosEnLista.map((n) => n.persona.id), [3]);
    expect(nodo(12).miembrosInactivos.map((n) => n.persona.id), [4]);
  });

  test('un inactivo con gente a cargo se queda en la lista principal', () {
    final conInactivo = ArbolEquipo.construir(
      usuarios: [
        usuarioPrueba(id: 20, tipo: 'supervisor', activo: false),
        usuarioPrueba(id: 21, supervisorId: 20),
      ],
      ventas: const [],
      mes: mes,
    );
    final supervisor = conInactivo.raices.single;
    expect(supervisor.esInactivoSinEquipo, isFalse);
    expect(supervisor.miembros.map((n) => n.persona.id), [21]);
    expect(conInactivo.personas, 1);
  });

  test('un supervisor_id que no existe o apunta a un vendedor deja sin superior', () {
    final huerfanos = ArbolEquipo.construir(
      usuarios: [
        usuarioPrueba(id: 1, supervisorId: 999),
        usuarioPrueba(id: 2),
        usuarioPrueba(id: 3, supervisorId: 2),
        usuarioPrueba(id: 4, supervisorId: 4),
      ],
      ventas: const [],
      mes: mes,
    );
    expect(huerfanos.raices, isEmpty);
    expect(huerfanos.sinSuperior.map((n) => n.persona.id), unorderedEquals([1, 2, 3, 4]));
  });

  test('los totales del árbol suman raíces y vendedores sin superior', () {
    expect(arbol.ventasEntregadas, 6);
    expect(arbol.comisionMes, 255);
    expect(arbol.personas, 7);
    expect(arbol.estaVacio, isFalse);
  });

  test('sin usuarios el árbol queda vacío', () {
    final vacio = ArbolEquipo.construir(usuarios: const [], ventas: const [], mes: mes);
    expect(vacio.estaVacio, isTrue);
    expect(vacio.personas, 0);
  });

  test('idsDelEquipo incluye a la persona y a todo su equipo', () {
    expect(nodo(11).idsDelEquipo, {11, 1, 2});
    expect(nodo(10).idsDelEquipo, {10, 11, 1, 2, 12, 3, 4});
  });

  group('buscar', () {
    test('ignora tildes y mayúsculas y entiende nombre y apellido juntos', () {
      expect(arbol.buscar('KATHERINE rios').map((n) => n.persona.id), [1]);
      expect(arbol.buscar('caceres').map((n) => n.persona.id), [12]);
    });

    test('encuentra por cargo', () {
      expect(arbol.buscar('supervisor').map((n) => n.persona.id), [11, 12]);
    });

    test('una consulta vacía o sin coincidencias no devuelve nada', () {
      expect(arbol.buscar('   '), isEmpty);
      expect(arbol.buscar('zzz'), isEmpty);
    });
  });

  group('repositorio', () {
    final repo = VentaRepository(DataSourceFalso(usuarios, ventas));

    test('arbolEquipo usa el mes de la fecha de referencia', () async {
      final resultado = await repo.arbolEquipo(referencia: DateTime(2026, 10, 15));
      expect(resultado.mes, mes);
      expect(resultado.ventasEntregadas, 6);
    });

    test('ventasDelEquipo trae solo las ventas del mes del equipo', () async {
      final delSupervisor = await repo.ventasDelEquipo(nodo(11), mes: mes);
      // Incluye la venta no entregada del vendedor 1; deja fuera septiembre.
      expect(delSupervisor.map((e) => e.venta.id), [4, 3, 2, 1]);
    });

    test('una persona sin equipo ve solo sus ventas', () async {
      final delVendedor = await repo.ventasDelEquipo(nodo(2), mes: mes);
      expect(delVendedor.map((e) => e.venta.id), [4]);
    });
  });
}
