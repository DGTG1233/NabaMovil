import '../../models/pago.dart';
import '../../models/usuario.dart';
import '../../utils/texto.dart';

/// Un pago junto con la persona que lo recibe. `persona` es null si el
/// usuario ya no existe en los datos.
class PagoConPersona {
  final Pago pago;
  final Usuario? persona;

  const PagoConPersona({required this.pago, required this.persona});
}

/// Pagos de un mismo periodo.
class GrupoPagos {
  final String periodo;
  final List<PagoConPersona> pagos;

  const GrupoPagos({required this.periodo, required this.pagos});

  double get total => HistorialPagos.totalDe(pagos);

  int get pendientes =>
      pagos.where((p) => p.pago.estado == EstadoPago.pendiente).length;
}

/// Historial de pagos con sus filtros y totales. Los importes usan `monto`,
/// que es lo que se paga, y no `montoCalculado`.
class HistorialPagos {
  /// Del periodo más reciente al más antiguo; dentro de cada periodo, los
  /// pendientes primero.
  final List<PagoConPersona> pagos;

  const HistorialPagos(this.pagos);

  bool get estaVacio => pagos.isEmpty;

  /// Filtra por estado, por tipo y por texto. El texto busca en el nombre,
  /// los apellidos, el tipo de pago y el número de transferencia; cada
  /// palabra debe aparecer, sin importar tildes ni mayúsculas.
  List<PagoConPersona> filtrar({
    EstadoPago? estado,
    TipoPago? tipo,
    String consulta = '',
  }) {
    final palabras = normalizarTexto(consulta.trim())
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    return pagos.where((item) {
      if (estado != null && item.pago.estado != estado) return false;
      if (tipo != null && item.pago.tipoPago != tipo) return false;
      if (palabras.isEmpty) return true;
      final texto = _textoBuscable(item);
      return palabras.every(texto.contains);
    }).toList();
  }

  static double pagadoDe(List<PagoConPersona> pagos) =>
      _sumar(pagos, EstadoPago.pagado);

  static double pendienteDe(List<PagoConPersona> pagos) =>
      _sumar(pagos, EstadoPago.pendiente);

  static double totalDe(List<PagoConPersona> pagos) =>
      pagos.fold(0.0, (suma, p) => suma + p.pago.monto);

  /// Agrupa por periodo respetando el orden de la lista.
  static List<GrupoPagos> agrupar(List<PagoConPersona> pagos) {
    final porPeriodo = <String, List<PagoConPersona>>{};
    for (final item in pagos) {
      porPeriodo.putIfAbsent(item.pago.periodo, () => []).add(item);
    }
    return [
      for (final entrada in porPeriodo.entries)
        GrupoPagos(periodo: entrada.key, pagos: entrada.value),
    ];
  }

  /// Función pura: une cada pago con su persona y los ordena.
  static HistorialPagos construir({
    required List<Pago> pagos,
    required List<Usuario> usuarios,
  }) {
    final porId = {for (final u in usuarios) u.id: u};
    final lista = [
      for (final p in pagos) PagoConPersona(pago: p, persona: porId[p.userId]),
    ]..sort(_comparar);
    return HistorialPagos(lista);
  }

  static double _sumar(List<PagoConPersona> pagos, EstadoPago estado) => pagos
      .where((p) => p.pago.estado == estado)
      .fold(0.0, (suma, p) => suma + p.pago.monto);

  static String _textoBuscable(PagoConPersona item) {
    final persona = item.persona;
    final nombre = persona == null
        ? ''
        : '${persona.nombre} ${persona.apellidoPaterno} '
            '${persona.apellidoMaterno}';
    return normalizarTexto(
      '$nombre ${item.pago.tipoPago.label} ${item.pago.nroTransferencia ?? ''}',
    );
  }
}

int _comparar(PagoConPersona a, PagoConPersona b) {
  final porPeriodo = b.pago.periodo.compareTo(a.pago.periodo);
  if (porPeriodo != 0) return porPeriodo;

  if (a.pago.estado != b.pago.estado) {
    return a.pago.estado == EstadoPago.pendiente ? -1 : 1;
  }

  final fechaA = a.pago.fechaPago;
  final fechaB = b.pago.fechaPago;
  if (fechaA != null && fechaB != null) {
    final porFecha = fechaB.compareTo(fechaA);
    if (porFecha != 0) return porFecha;
  }

  final porNombre = (a.persona?.nombreCompleto ?? '')
      .compareTo(b.persona?.nombreCompleto ?? '');
  if (porNombre != 0) return porNombre;
  return a.pago.id.compareTo(b.pago.id);
}
