enum TipoPago {
  comision,
  bono,
  sueldo;

  String get valor => switch (this) {
        TipoPago.comision => 'comision',
        TipoPago.bono => 'bono',
        TipoPago.sueldo => 'sueldo',
      };

  String get label => switch (this) {
        TipoPago.comision => 'Comisión',
        TipoPago.bono => 'Bono',
        TipoPago.sueldo => 'Sueldo',
      };

  static TipoPago fromValor(String valor) =>
      TipoPago.values.firstWhere((t) => t.valor == valor);
}

enum EstadoPago {
  pendiente,
  pagado;

  String get valor => name;

  static EstadoPago fromValor(String valor) =>
      EstadoPago.values.firstWhere((e) => e.valor == valor);
}

class Pago {
  final int id;
  final int userId;
  final String periodo;
  final TipoPago tipoPago;
  final double monto;
  final double montoCalculado;
  final EstadoPago estado;
  final DateTime? fechaPago;
  final String? nroTransferencia;
  final String? observacion;

  Pago({
    required this.id,
    required this.userId,
    required this.periodo,
    required this.tipoPago,
    required this.monto,
    required this.montoCalculado,
    required this.estado,
    this.fechaPago,
    this.nroTransferencia,
    this.observacion,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      periodo: json['periodo'] as String,
      tipoPago: TipoPago.fromValor(json['tipo_pago'] as String),
      monto: (json['monto'] as num).toDouble(),
      montoCalculado: (json['monto_calculado'] as num).toDouble(),
      estado: EstadoPago.fromValor(json['estado'] as String),
      fechaPago: json['fecha_pago'] != null
          ? DateTime.parse(json['fecha_pago'] as String)
          : null,
      nroTransferencia: json['nro_transferencia'] as String?,
      observacion: json['observacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'periodo': periodo,
        'tipo_pago': tipoPago.valor,
        'monto': monto,
        'monto_calculado': montoCalculado,
        'estado': estado.valor,
        'fecha_pago': fechaPago?.toIso8601String(),
        'nro_transferencia': nroTransferencia,
        'observacion': observacion,
      };
}