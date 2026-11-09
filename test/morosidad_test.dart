import 'package:flutter_test/flutter_test.dart';
import 'package:nabamemovil/data/repositories/morosidad_repository.dart';
import 'package:nabamemovil/data/repositories/resumen_morosidad.dart';
import 'package:nabamemovil/models/caso_morosidad.dart';

import 'soporte/datos_falsos.dart';

void main() {
  final corte = DateTime(2026, 10, 16);

  group('ReciboMorosidad', () {
    test('lo pendiente es facturado menos ajuste menos pagado', () {
      final recibo = reciboPrueba(1, facturado: 50, ajuste: 5, pagado: 15);
      expect(recibo.pendiente, 30);
      expect(recibo.tieneDeuda, isTrue);
    });

    test('lo pendiente nunca baja de cero', () {
      final recibo = reciboPrueba(1, facturado: 40, pagado: 45);
      expect(recibo.pendiente, 0);
      expect(recibo.tieneDeuda, isFalse);
    });
  });

  group('CasoMorosidad', () {
    test('penalizado si tiene el recibo 1 y falta el 2', () {
      final caso = casoPrueba(id: 1, recibos: [reciboPrueba(1)]);
      expect(caso.esPenalizado, isTrue);
      expect(caso.estado, EstadoMorosidad.penalizado);
    });

    test('penalizado si tiene el recibo 2 y falta el 3', () {
      final caso =
          casoPrueba(id: 1, recibos: [reciboPrueba(1), reciboPrueba(2)]);
      expect(caso.estado, EstadoMorosidad.penalizado);
    });

    test('penalizado pesa más que tener deuda', () {
      final caso = casoPrueba(id: 1, recibos: [reciboPrueba(1, pagado: 0)]);
      expect(caso.deudaTotal, 40);
      expect(caso.estado, EstadoMorosidad.penalizado);
    });

    test('en gestión si tiene los tres recibos y alguno con deuda', () {
      final caso = casoPrueba(id: 1, recibos: [
        reciboPrueba(1, pagado: 40),
        reciboPrueba(2, pagado: 40),
        reciboPrueba(3, pagado: 0),
      ]);
      expect(caso.estado, EstadoMorosidad.enGestion);
      expect(caso.deudaTotal, 40);
    });

    test('al día sin recibos o con los tres pagados', () {
      expect(casoPrueba(id: 1).estado, EstadoMorosidad.alDia);

      final pagado = casoPrueba(id: 2, recibos: [
        reciboPrueba(1, pagado: 40),
        reciboPrueba(2, pagado: 40),
        reciboPrueba(3, pagado: 40),
      ]);
      expect(pagado.estado, EstadoMorosidad.alDia);
    });

    test('la deuda suma solo lo pendiente de cada recibo', () {
      final caso = casoPrueba(id: 1, recibos: [
        reciboPrueba(1, facturado: 42.5),
        reciboPrueba(2, pagado: 40),
        reciboPrueba(3, facturado: 30, pagado: 10),
      ]);
      expect(caso.deudaTotal, closeTo(62.5, 0.0001));
    });

    test('la penalidad es el doble del cargo fijo y solo si está penalizado', () {
      final penalizado =
          casoPrueba(id: 1, cargoFijo: 39.9, recibos: [reciboPrueba(1)]);
      expect(penalizado.penalidad, closeTo(79.8, 0.0001));
      expect(casoPrueba(id: 2, cargoFijo: 39.9).penalidad, 0);
    });

    test('el cierre es el último día del cuarto mes siguiente al alta', () {
      expect(CasoMorosidad.cierreDe('2026-06'), DateTime(2026, 10, 31));
      expect(CasoMorosidad.cierreDe('2026-09'), DateTime(2027, 1, 31));
      expect(CasoMorosidad.cierreDe('2026-10'), DateTime(2027, 2, 28));
    });

    test('lee un caso desde su JSON', () {
      final caso = CasoMorosidad.fromJson({
        'id': 7,
        'segmento': 'fija',
        'user_id': 2,
        'identificador': 'P-1234567',
        'cliente': 'Bodega Vargas',
        'mes_alta': '2026-07',
        'fecha_alta': '2026-07-08',
        'cargo_fijo': 79.9,
        'fecha_proceso': '2026-10-16',
        'recibos': [
          {
            'numero': 1,
            'emision': '2026-08-08',
            'vencimiento': '2026-08-23',
            'facturado': 80.5,
            'ajuste': 0,
            'pagado': 0,
            'fecha_pago': null,
          },
        ],
      });
      expect(caso.segmento, SegmentoMorosidad.fija);
      expect(caso.titulo, 'Bodega Vargas');
      expect(caso.recibos.single.pendiente, closeTo(80.5, 0.0001));
      expect(caso.recibos.single.fechaPago, isNull);
    });

    test('un segmento desconocido en el JSON falla con un mensaje claro', () {
      expect(() => SegmentoMorosidad.fromValor('satelital'), throwsArgumentError);
    });
  });

  group('ResumenMorosidad', () {
    // Móvil: junio (3 casos), agosto (1) y mayo, que ya cerró (1). Fija: julio.
    final usuarios = [usuarioPrueba(id: 1, nombre: 'Katherine', apellido: 'Rios')];
    final casos = [
      casoPrueba(id: 1, recibos: [
        reciboPrueba(1, facturado: 42.5),
        reciboPrueba(2, pagado: 40),
        reciboPrueba(3, pagado: 40),
      ]),
      casoPrueba(id: 2, cargoFijo: 30, recibos: [reciboPrueba(1, facturado: 30)]),
      casoPrueba(id: 3),
      casoPrueba(id: 4, mesAlta: '2026-05', recibos: [
        reciboPrueba(1, pagado: 40),
        reciboPrueba(2, pagado: 30),
        reciboPrueba(3, pagado: 40),
      ]),
      casoPrueba(id: 5, mesAlta: '2026-08'),
      casoPrueba(id: 6, segmento: SegmentoMorosidad.fija, mesAlta: '2026-07', recibos: [
        reciboPrueba(1, pagado: 40),
        reciboPrueba(2, pagado: 40),
        reciboPrueba(3, pagado: 40),
      ]),
    ];

    late ResumenMorosidad movil;

    setUp(() {
      movil = ResumenMorosidad.construir(
        segmento: SegmentoMorosidad.movil,
        casos: casos,
        usuarios: usuarios,
        fechaCorte: corte,
      );
    });

    test('separa los casos por segmento', () {
      final fija = ResumenMorosidad.construir(
        segmento: SegmentoMorosidad.fija,
        casos: casos,
        usuarios: usuarios,
        fechaCorte: corte,
      );
      expect(fija.meses.map((m) => m.mesAlta), ['2026-07']);
      expect(movil.meses.expand((m) => m.casos).length, 5);
    });

    test('ordena los vigentes por cierre y deja los cerrados al final', () {
      expect(movil.meses.map((m) => m.mesAlta), ['2026-06', '2026-08', '2026-05']);
    });

    test('cuenta los estados y la deuda de cada mes', () {
      final junio = movil.meses.first;
      expect(junio.alDia, 1);
      expect(junio.enGestion, 1);
      expect(junio.penalizados, 1);
      expect(junio.deudaEnGestion, closeTo(42.5, 0.0001));
      expect(junio.penalidad, 60);
    });

    test('calcula los días para el cierre con la fecha de corte', () {
      expect(movil.meses[0].diasParaCierre, 15);
      expect(movil.meses[1].diasParaCierre, 76);
      expect(movil.meses[2].diasParaCierre, -16);
    });

    test('marca el cierre próximo y el mes cerrado', () {
      expect(movil.meses[0].cierreProximo, isTrue);
      expect(movil.meses[0].cerrado, isFalse);
      expect(movil.meses[1].cierreProximo, isFalse);
      expect(movil.meses[2].cerrado, isTrue);
      expect(movil.meses[2].cierreProximo, isFalse);
    });

    test('los totales generales dejan fuera los meses cerrados', () {
      // Mayo tiene un caso en gestión con S/ 10 de deuda, pero ya cerró.
      expect(movil.alDia, 2);
      expect(movil.enGestion, 1);
      expect(movil.penalizados, 1);
      expect(movil.deudaPorGestionar, closeTo(42.5, 0.0001));
      expect(movil.meses[2].deudaEnGestion, closeTo(10, 0.0001));
    });

    test('ordena los casos del mes: en gestión, penalizados y al día', () {
      final estados = movil.meses.first.casos.map((c) => c.estado);
      expect(estados, [
        EstadoMorosidad.enGestion,
        EstadoMorosidad.penalizado,
        EstadoMorosidad.alDia,
      ]);
    });

    test('conEstado filtra y sin estado devuelve todos', () {
      final junio = movil.meses.first;
      expect(junio.conEstado(null).length, 3);
      expect(junio.conEstado(EstadoMorosidad.penalizado).map((c) => c.id), [2]);
    });

    test('encuentra al vendedor de un caso', () {
      expect(movil.vendedorDe(casos.first)?.nombre, 'Katherine');
      expect(movil.vendedorDe(casoPrueba(id: 9, userId: 99)), isNull);
    });

    test('sin casos queda vacío', () {
      final vacio = ResumenMorosidad.construir(
        segmento: SegmentoMorosidad.movil,
        casos: const [],
        usuarios: usuarios,
        fechaCorte: corte,
      );
      expect(vacio.estaVacio, isTrue);
      expect(vacio.deudaPorGestionar, 0);
    });
  });

  group('MorosidadRepository', () {
    test('usa como fecha de corte la más reciente de los datos', () {
      final casos = [
        casoPrueba(id: 1),
        CasoMorosidad(
          id: 2,
          segmento: SegmentoMorosidad.movil,
          userId: 1,
          identificador: '900',
          mesAlta: '2026-06',
          fechaAlta: DateTime(2026, 6, 10),
          cargoFijo: 40,
          fechaProceso: DateTime(2026, 10, 20),
          recibos: const [],
        ),
      ];
      expect(MorosidadRepository.fechaCorteDe(casos), DateTime(2026, 10, 20));
    });

    test('carga ambos segmentos desde el origen de datos', () async {
      final repo = MorosidadRepository(DataSourceFalso(
        [usuarioPrueba(id: 1)],
        const [],
        [
          casoPrueba(id: 1),
          casoPrueba(id: 2, segmento: SegmentoMorosidad.fija, mesAlta: '2026-07'),
        ],
      ));
      final datos = await repo.cargar();
      expect(datos.movil.meses.length, 1);
      expect(datos.de(SegmentoMorosidad.fija).meses.single.mesAlta, '2026-07');
      expect(datos.movil.fechaCorte, DateTime(2026, 10, 16));
    });
  });
}
