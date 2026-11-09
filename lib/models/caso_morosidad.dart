enum SegmentoMorosidad {
  movil('movil', 'Móvil'),
  fija('fija', 'Fija');

  final String valor;
  final String label;
  const SegmentoMorosidad(this.valor, this.label);

  static SegmentoMorosidad fromValor(String valor) {
    return SegmentoMorosidad.values.firstWhere(
      (s) => s.valor == valor,
      orElse: () =>
          throw ArgumentError('Segmento de morosidad desconocido: $valor'),
    );
  }
}

enum EstadoMorosidad { alDia, enGestion, penalizado }

/// Un recibo emitido al cliente. Solo existen los recibos que ya se
/// emitieron: si falta el 2 o el 3, simplemente no está en la lista.
class ReciboMorosidad {
  final int numero;
  final DateTime emision;
  final DateTime vencimiento;
  final double facturado;
  final double ajuste;
  final double pagado;
  final DateTime? fechaPago;

  const ReciboMorosidad({
    required this.numero,
    required this.emision,
    required this.vencimiento,
    required this.facturado,
    required this.ajuste,
    required this.pagado,
    this.fechaPago,
  });

  /// Facturado menos ajuste menos pagado, sin bajar de cero.
  double get pendiente {
    final valor = facturado - ajuste - pagado;
    return valor > 0.005 ? valor : 0;
  }

  bool get tieneDeuda => pendiente > 0;

  factory ReciboMorosidad.fromJson(Map<String, dynamic> json) {
    final fechaPago = json['fecha_pago'] as String?;
    return ReciboMorosidad(
      numero: json['numero'] as int,
      emision: DateTime.parse(json['emision'] as String),
      vencimiento: DateTime.parse(json['vencimiento'] as String),
      facturado: (json['facturado'] as num).toDouble(),
      ajuste: (json['ajuste'] as num?)?.toDouble() ?? 0,
      pagado: (json['pagado'] as num?)?.toDouble() ?? 0,
      fechaPago: fechaPago == null ? null : DateTime.parse(fechaPago),
    );
  }
}

/// Caso de morosidad de un cliente, con hasta tres recibos. El estado, la
/// deuda y la penalidad se calculan; no se guardan.
class CasoMorosidad {
  final int id;
  final SegmentoMorosidad segmento;

  /// Vendedor que hizo el alta.
  final int userId;

  /// Teléfono en móvil y número de petición en fija.
  final String identificador;

  /// Razón social del cliente. Solo se usa en fija.
  final String? cliente;

  /// Mes del alta, como 'YYYY-MM'.
  final String mesAlta;
  final DateTime fechaAlta;
  final double cargoFijo;

  /// Fecha en que se cargaron los datos.
  final DateTime fechaProceso;
  final List<ReciboMorosidad> recibos;

  const CasoMorosidad({
    required this.id,
    required this.segmento,
    required this.userId,
    required this.identificador,
    required this.mesAlta,
    required this.fechaAlta,
    required this.cargoFijo,
    required this.fechaProceso,
    required this.recibos,
    this.cliente,
  });

  String get titulo => cliente ?? identificador;

  ReciboMorosidad? recibo(int numero) {
    for (final r in recibos) {
      if (r.numero == numero) return r;
    }
    return null;
  }

  bool tieneRecibo(int numero) => recibo(numero) != null;

  double get deudaTotal => recibos.fold(0.0, (suma, r) => suma + r.pendiente);

  /// Hay un recibo emitido pero falta el siguiente: tiene el 1 sin el 2, o
  /// el 2 sin el 3.
  bool get esPenalizado =>
      (tieneRecibo(1) && !tieneRecibo(2)) || (tieneRecibo(2) && !tieneRecibo(3));

  /// Penalizado pesa más que En gestión, y este más que Al día.
  EstadoMorosidad get estado {
    if (esPenalizado) return EstadoMorosidad.penalizado;
    if (deudaTotal > 0) return EstadoMorosidad.enGestion;
    return EstadoMorosidad.alDia;
  }

  /// Dos veces el cargo fijo, solo en casos penalizados.
  double get penalidad => esPenalizado ? cargoFijo * 2 : 0;

  DateTime get cierrePenalizacion => cierreDe(mesAlta);

  /// Último día del cuarto mes después del mes de alta.
  static DateTime cierreDe(String mesAlta) {
    final partes = mesAlta.split('-');
    final anio = int.parse(partes[0]);
    final mes = int.parse(partes[1]);
    return DateTime(anio, mes + 5, 0);
  }

  factory CasoMorosidad.fromJson(Map<String, dynamic> json) {
    return CasoMorosidad(
      id: json['id'] as int,
      segmento: SegmentoMorosidad.fromValor(json['segmento'] as String),
      userId: json['user_id'] as int,
      identificador: json['identificador'] as String,
      cliente: json['cliente'] as String?,
      mesAlta: json['mes_alta'] as String,
      fechaAlta: DateTime.parse(json['fecha_alta'] as String),
      cargoFijo: (json['cargo_fijo'] as num).toDouble(),
      fechaProceso: DateTime.parse(json['fecha_proceso'] as String),
      recibos: (json['recibos'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ReciboMorosidad.fromJson)
          .toList(),
    );
  }
}
