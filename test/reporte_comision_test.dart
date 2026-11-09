import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nabamemovil/data/repositories/arbol_equipo.dart';
import 'package:nabamemovil/data/repositories/reporte_comision.dart';
import 'package:nabamemovil/data/repositories/venta_repository.dart';
import 'package:nabamemovil/models/venta_estado.dart';

import 'soporte/datos_falsos.dart';

void main() {
  const mes = '2026-10';

  // Socio 10 con los supervisores 11 y 12. El 11 tiene a Katherine (2 ventas)
  // y a Jhonatan (1). El 12 tiene a Milagros (1), a Renzo, que está inactivo
  // (1), y a Brandon, que no vendió. Yesenia no tiene superior.
  final usuarios = [
    usuarioPrueba(id: 10, nombre: 'Ricardo', apellido: 'Mori', tipo: 'socio_comercial'),
    usuarioPrueba(id: 11, nombre: 'Luciana', apellido: 'Grandez', tipo: 'supervisor', supervisorId: 10),
    usuarioPrueba(id: 12, nombre: 'Marco', apellido: 'Caceres', tipo: 'supervisor', supervisorId: 10),
    usuarioPrueba(id: 1, nombre: 'Katherine', apellido: 'Rios', supervisorId: 11),
    usuarioPrueba(id: 2, nombre: 'Jhonatan', apellido: 'Paredes', supervisorId: 11),
    usuarioPrueba(id: 3, nombre: 'Milagros', apellido: 'Tuesta', supervisorId: 12),
    usuarioPrueba(id: 4, nombre: 'Renzo', apellido: 'Vasquez', supervisorId: 12, activo: false),
    usuarioPrueba(id: 5, nombre: 'Brandon', apellido: 'Chota', supervisorId: 12),
    usuarioPrueba(id: 6, nombre: 'Yesenia', apellido: 'Del Aguila'),
  ];
  final ventas = [
    ventaPrueba(id: 1, userId: 1, fecha: DateTime(2026, 10, 2), comision: 50),
    ventaPrueba(id: 2, userId: 1, fecha: DateTime(2026, 10, 3), comision: 30),
    ventaPrueba(id: 3, userId: 2, fecha: DateTime(2026, 10, 5), comision: 40),
    ventaPrueba(id: 4, userId: 3, fecha: DateTime(2026, 10, 6), comision: 100),
    ventaPrueba(id: 5, userId: 4, fecha: DateTime(2026, 10, 7), comision: 20),
    ventaPrueba(id: 6, userId: 6, fecha: DateTime(2026, 10, 8), comision: 15),
    ventaPrueba(id: 7, userId: 1, fecha: DateTime(2026, 9, 20), comision: 60),
    ventaPrueba(id: 8, userId: 2, fecha: DateTime(2026, 10, 9), estado: VentaEstado.noEntregado),
  ];

  late ArbolEquipo arbol;
  late ReporteComision reporte;

  setUpAll(() async {
    await initializeDateFormatting('es_PE', null);
  });

  setUp(() {
    arbol = ArbolEquipo.construir(usuarios: usuarios, ventas: ventas, mes: mes);
    reporte = ReporteComision(arbol: arbol, mesesDisponibles: const ['2026-10', '2026-09']);
  });

  group('socios y sin socio', () {
    test('los socios son las raíces que tienen ese cargo', () {
      expect(arbol.socios.map((n) => n.persona.id), [10]);
    });

    test('sin socio reúne a los vendedores sin superior', () {
      expect(arbol.sinSocio.map((n) => n.persona.id), [6]);
    });

    test('un supervisor sin socio también queda en sin socio', () {
      final suelto = ArbolEquipo.construir(
        usuarios: [
          usuarioPrueba(id: 20, tipo: 'supervisor'),
          usuarioPrueba(id: 21, supervisorId: 20),
        ],
        ventas: const [],
        mes: mes,
      );
      expect(suelto.socios, isEmpty);
      expect(suelto.sinSocio.map((n) => n.persona.id), [20]);
    });
  });

  group('totales y participación', () {
    test('el total suma la comisión generada por socios y por sueltos', () {
      // Socio: 80 + 40 + 100 + 20 = 240. Sin socio: 15.
      expect(reporte.socios.single.comisionMes, 240);
      expect(reporte.comisionTotal, 255);
      expect(reporte.ventasEntregadas, 6);
    });

    test('la participación es la parte del total que genera cada nodo', () {
      expect(reporte.participacionDe(reporte.socios.single), closeTo(240 / 255, 0.0001));
    });

    test('con total cero la participación es cero', () {
      final vacio = ReporteComision(
        arbol: ArbolEquipo.construir(usuarios: usuarios, ventas: const [], mes: mes),
        mesesDisponibles: const [],
      );
      expect(vacio.participacionDe(vacio.socios.single), 0);
    });
  });

  group('resumen para enviar', () {
    test('lista total, supervisores y vendedores con ventas', () {
      expect(
        reporte.resumenDe(reporte.socios.single),
        'Comisión generada en octubre 2026\n'
        'Socio Comercial: Ricardo Mori\n'
        'Total: S/ 240.00 (5 ventas entregadas)\n'
        '\n'
        'Luciana Grandez (Supervisor): S/ 120.00, 3 ventas\n'
        '  Katherine Rios: S/ 80.00, 2 ventas\n'
        '  Jhonatan Paredes: S/ 40.00, 1 venta\n'
        'Marco Caceres (Supervisor): S/ 120.00, 2 ventas\n'
        '  Milagros Tuesta: S/ 100.00, 1 venta\n'
        '  Renzo Vasquez (inactivo): S/ 20.00, 1 venta',
      );
    });

    test('deja fuera a los vendedores sin ventas', () {
      expect(reporte.resumenDe(reporte.socios.single), isNot(contains('Brandon')));
    });
  });

  group('repositorio', () {
    final repo = VentaRepository(DataSourceFalso(usuarios, ventas));

    test('lista los meses con comisión, del más reciente al más antiguo', () {
      expect(VentaRepository.mesesConComisionDe(ventas), ['2026-10', '2026-09']);
    });

    test('un mes solo con ventas sin comisión no aparece', () {
      final soloRechazadas = [
        ventaPrueba(id: 1, userId: 1, fecha: DateTime(2026, 8, 1), estado: VentaEstado.noEntregado),
      ];
      expect(VentaRepository.mesesConComisionDe(soloRechazadas), isEmpty);
    });

    test('sin mes pedido usa el más reciente', () async {
      final resultado = await repo.reporteComision();
      expect(resultado.mes, '2026-10');
      expect(resultado.mesesDisponibles, ['2026-10', '2026-09']);
    });

    test('con un mes pedido calcula ese mes', () async {
      final resultado = await repo.reporteComision(mes: '2026-09');
      expect(resultado.mes, '2026-09');
      expect(resultado.comisionTotal, 60);
    });
  });
}
