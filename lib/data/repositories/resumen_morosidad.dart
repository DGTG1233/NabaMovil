import '../../models/caso_morosidad.dart';
import '../../models/usuario.dart';

/// Casos de un mes de alta con sus totales. El cierre de penalización marca
/// hasta cuándo se puede gestionar ese mes.
class ResumenMesMorosidad {
  /// Días antes del cierre desde los que se avisa que está por vencer.
  static const diasAvisoCierre = 15;

  final String mesAlta;
  final List<CasoMorosidad> casos;
  final DateTime cierre;
  final int diasParaCierre;
  final int alDia;
  final int enGestion;
  final int penalizados;
  final double deudaEnGestion;
  final double penalidad;

  const ResumenMesMorosidad({
    required this.mesAlta,
    required this.casos,
    required this.cierre,
    required this.diasParaCierre,
    required this.alDia,
    required this.enGestion,
    required this.penalizados,
    required this.deudaEnGestion,
    required this.penalidad,
  });

  bool get cerrado => diasParaCierre < 0;

  bool get cierreProximo =>
      diasParaCierre >= 0 && diasParaCierre <= diasAvisoCierre;

  /// Casos de un estado, o todos si `estado` es null.
  List<CasoMorosidad> conEstado(EstadoMorosidad? estado) => estado == null
      ? casos
      : casos.where((c) => c.estado == estado).toList();
}

/// Morosidad de un segmento (móvil o fija) a una fecha de corte. Los totales
/// generales cuentan solo los meses vigentes: los cerrados ya no se gestionan.
class ResumenMorosidad {
  final SegmentoMorosidad segmento;
  final DateTime fechaCorte;

  /// Primero los meses vigentes, el que cierra antes arriba; al final los
  /// cerrados, el más reciente primero.
  final List<ResumenMesMorosidad> meses;
  final Map<int, Usuario> vendedores;

  const ResumenMorosidad({
    required this.segmento,
    required this.fechaCorte,
    required this.meses,
    required this.vendedores,
  });

  bool get estaVacio => meses.isEmpty;

  Iterable<ResumenMesMorosidad> get _vigentes =>
      meses.where((m) => !m.cerrado);

  int get alDia => _vigentes.fold(0, (suma, m) => suma + m.alDia);

  int get enGestion => _vigentes.fold(0, (suma, m) => suma + m.enGestion);

  int get penalizados => _vigentes.fold(0, (suma, m) => suma + m.penalizados);

  double get deudaPorGestionar =>
      _vigentes.fold(0.0, (suma, m) => suma + m.deudaEnGestion);

  Usuario? vendedorDe(CasoMorosidad caso) => vendedores[caso.userId];

  /// Función pura: arma el resumen sin leer datos, por eso se prueba sola.
  static ResumenMorosidad construir({
    required SegmentoMorosidad segmento,
    required List<CasoMorosidad> casos,
    required List<Usuario> usuarios,
    required DateTime fechaCorte,
  }) {
    final porMes = <String, List<CasoMorosidad>>{};
    for (final caso in casos.where((c) => c.segmento == segmento)) {
      porMes.putIfAbsent(caso.mesAlta, () => []).add(caso);
    }

    final meses = [
      for (final entrada in porMes.entries)
        _armarMes(entrada.key, entrada.value, fechaCorte),
    ]..sort(_compararMeses);

    return ResumenMorosidad(
      segmento: segmento,
      fechaCorte: fechaCorte,
      meses: meses,
      vendedores: {for (final u in usuarios) u.id: u},
    );
  }
}

ResumenMesMorosidad _armarMes(
  String mesAlta,
  List<CasoMorosidad> casos,
  DateTime fechaCorte,
) {
  final cierre = CasoMorosidad.cierreDe(mesAlta);
  var alDia = 0;
  var enGestion = 0;
  var penalizados = 0;
  var deuda = 0.0;
  var penalidad = 0.0;

  for (final caso in casos) {
    penalidad += caso.penalidad;
    switch (caso.estado) {
      case EstadoMorosidad.alDia:
        alDia++;
      case EstadoMorosidad.enGestion:
        enGestion++;
        deuda += caso.deudaTotal;
      case EstadoMorosidad.penalizado:
        penalizados++;
    }
  }

  return ResumenMesMorosidad(
    mesAlta: mesAlta,
    casos: [...casos]..sort(_compararCasos),
    cierre: cierre,
    diasParaCierre: _diasEntre(fechaCorte, cierre),
    alDia: alDia,
    enGestion: enGestion,
    penalizados: penalizados,
    deudaEnGestion: deuda,
    penalidad: penalidad,
  );
}

/// Días de calendario entre dos fechas, sin que importen la hora ni el
/// horario de verano del dispositivo.
int _diasEntre(DateTime desde, DateTime hasta) {
  final a = DateTime.utc(desde.year, desde.month, desde.day);
  final b = DateTime.utc(hasta.year, hasta.month, hasta.day);
  return b.difference(a).inDays;
}

int _compararMeses(ResumenMesMorosidad a, ResumenMesMorosidad b) {
  if (a.cerrado != b.cerrado) return a.cerrado ? 1 : -1;
  return a.cerrado
      ? b.mesAlta.compareTo(a.mesAlta)
      : a.mesAlta.compareTo(b.mesAlta);
}

/// En gestión primero, luego penalizados y al final los al día; dentro de
/// cada grupo, la deuda más alta arriba.
int _compararCasos(CasoMorosidad a, CasoMorosidad b) {
  const orden = {
    EstadoMorosidad.enGestion: 0,
    EstadoMorosidad.penalizado: 1,
    EstadoMorosidad.alDia: 2,
  };
  final porEstado = orden[a.estado]!.compareTo(orden[b.estado]!);
  if (porEstado != 0) return porEstado;
  return b.deudaTotal.compareTo(a.deudaTotal);
}
