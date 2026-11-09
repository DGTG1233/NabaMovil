import '../../models/caso_morosidad.dart';
import '../../models/pago.dart';
import '../../models/venta.dart';
import '../../models/venta_estado.dart';
import '../../utils/formato.dart';
import 'morosidad_repository.dart';
import 'resumen_morosidad.dart';

enum TipoAviso { cierreMorosidad, pagoPendiente, ventaNoEntregada }

/// Pantalla a la que lleva un aviso.
enum DestinoAviso { morosidad, historial, ventas }

/// Un aviso para el Administrador. No se guarda: se calcula cada vez a
/// partir de los datos, así siempre coincide con las demás pantallas.
class Aviso {
  /// Estable entre cargas, para recordar si ya se leyó.
  final String id;
  final TipoAviso tipo;
  final String titulo;
  final String detalle;
  final DestinoAviso destino;

  const Aviso({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.detalle,
    required this.destino,
  });
}

class Avisos {
  Avisos._();

  /// Primero los cierres de penalización que vencen pronto, luego los pagos
  /// pendientes por periodo y al final las ventas no entregadas.
  static List<Aviso> construir({
    required List<CasoMorosidad> casos,
    required List<Pago> pagos,
    required List<Venta> ventas,
  }) {
    return [
      ..._cierresProximos(casos),
      ..._pagosPendientes(pagos),
      ..._ventasNoEntregadas(ventas),
    ];
  }

  static List<Aviso> _cierresProximos(List<CasoMorosidad> casos) {
    const soles = FormatoSoles();
    final fechaCorte = MorosidadRepository.fechaCorteDe(casos);
    final candidatos = <(ResumenMesMorosidad, SegmentoMorosidad)>[];

    for (final segmento in SegmentoMorosidad.values) {
      final resumen = ResumenMorosidad.construir(
        segmento: segmento,
        casos: casos,
        usuarios: const [],
        fechaCorte: fechaCorte,
      );
      for (final mes in resumen.meses) {
        if (mes.cierreProximo && mes.enGestion > 0) {
          candidatos.add((mes, segmento));
        }
      }
    }

    // El que cierra antes va primero; a igual fecha, móvil antes que fija.
    candidatos.sort((a, b) {
      final porDias = a.$1.diasParaCierre.compareTo(b.$1.diasParaCierre);
      return porDias != 0 ? porDias : a.$2.index.compareTo(b.$2.index);
    });

    return [
      for (final (mes, segmento) in candidatos)
        Aviso(
          id: 'cierre-${segmento.valor}-${mes.mesAlta}',
          tipo: TipoAviso.cierreMorosidad,
          titulo: 'Cierra la penalización de ${etiquetaMes(mes.mesAlta)}',
          detalle: '${segmento.label}: '
              '${cantidadDe(mes.enGestion, 'caso en gestión', 'casos en gestión')} '
              'por ${soles.format(mes.deudaEnGestion)}. '
              '${_textoCierre(mes.diasParaCierre)}.',
          destino: DestinoAviso.morosidad,
        ),
    ];
  }

  static String _textoCierre(int dias) => dias == 0
      ? 'Cierra hoy'
      : 'Cierra en ${cantidadDe(dias, 'día', 'días')}';

  static List<Aviso> _pagosPendientes(List<Pago> pagos) {
    const soles = FormatoSoles();
    final porPeriodo = <String, List<Pago>>{};
    for (final pago in pagos.where((p) => p.estado == EstadoPago.pendiente)) {
      porPeriodo.putIfAbsent(pago.periodo, () => []).add(pago);
    }
    final periodos = porPeriodo.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final periodo in periodos)
        Aviso(
          id: 'pago-$periodo',
          tipo: TipoAviso.pagoPendiente,
          titulo: '${cantidadDe(porPeriodo[periodo]!.length, 'pago pendiente', 'pagos pendientes')} '
              'de ${etiquetaMes(periodo)}',
          detalle: 'Suman ${soles.format(porPeriodo[periodo]!.fold(0.0, (suma, p) => suma + p.monto))}.',
          destino: DestinoAviso.historial,
        ),
    ];
  }

  /// Ventas no entregadas del mes más reciente que tenga ventas.
  static List<Aviso> _ventasNoEntregadas(List<Venta> ventas) {
    if (ventas.isEmpty) return const [];
    final mes =
        ventas.map((v) => v.mes).reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    final cantidad = ventas
        .where((v) => v.mes == mes && v.estado == VentaEstado.noEntregado)
        .length;
    if (cantidad == 0) return const [];

    return [
      Aviso(
        id: 'venta-$mes',
        tipo: TipoAviso.ventaNoEntregada,
        titulo: '${cantidadDe(cantidad, 'venta no entregada', 'ventas no entregadas')} '
            'en ${etiquetaMes(mes)}',
        detalle: 'Revisa qué pasó con ${cantidad == 1 ? 'esta venta' : 'estas ventas'}.',
        destino: DestinoAviso.ventas,
      ),
    ];
  }
}
