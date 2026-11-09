import 'tipo_producto.dart';
import 'venta_estado.dart';

class Venta {
  final int id;
  final int userId;
  final String mes;
  final DateTime fechaRegistro;
  final String canal;
  final TipoProducto tipoProducto;
  final String origenVenta;
  final double cargoFijo;
  final String dniCliente;
  final String nombreCliente;
  final String numeroContacto;
  final String? numeroPorta;
  final String? operadorCedente;
  final VentaEstado estado;
  final String? motivoRechazo;
  final String? subMotivo;
  final String? direccionEntrega;
  final String? distritoEntrega;
  final double? comisionCalculada;

  Venta({
    required this.id,
    required this.userId,
    required this.mes,
    required this.fechaRegistro,
    required this.canal,
    required this.tipoProducto,
    required this.origenVenta,
    required this.cargoFijo,
    required this.dniCliente,
    required this.nombreCliente,
    required this.numeroContacto,
    this.numeroPorta,
    this.operadorCedente,
    required this.estado,
    this.motivoRechazo,
    this.subMotivo,
    this.direccionEntrega,
    this.distritoEntrega,
    this.comisionCalculada,
  });

  bool get puedeCambiarEstado => !estado.esFinal;

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      mes: json['mes'] as String,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
      canal: json['canal'] as String,
      tipoProducto: TipoProducto.fromValor(json['tipo_producto'] as String),
      origenVenta: json['origen_venta'] as String,
      cargoFijo: (json['cargo_fijo'] as num).toDouble(),
      dniCliente: json['dni_cliente'] as String,
      nombreCliente: json['nombre_cliente'] as String,
      numeroContacto: json['numero_contacto'] as String,
      numeroPorta: json['numero_porta'] as String?,
      operadorCedente: json['operador_cedente'] as String?,
      estado: VentaEstado.fromValor(json['estado'] as String),
      motivoRechazo: json['motivo_rechazo'] as String?,
      subMotivo: json['sub_motivo'] as String?,
      direccionEntrega: json['direccion_entrega'] as String?,
      distritoEntrega: json['distrito_entrega'] as String?,
      comisionCalculada: (json['comision_calculada'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'mes': mes,
        'fecha_registro': fechaRegistro.toIso8601String(),
        'canal': canal,
        'tipo_producto': tipoProducto.valor,
        'origen_venta': origenVenta,
        'cargo_fijo': cargoFijo,
        'dni_cliente': dniCliente,
        'nombre_cliente': nombreCliente,
        'numero_contacto': numeroContacto,
        'numero_porta': numeroPorta,
        'operador_cedente': operadorCedente,
        'estado': estado.valor,
        'motivo_rechazo': motivoRechazo,
        'sub_motivo': subMotivo,
        'direccion_entrega': direccionEntrega,
        'distrito_entrega': distritoEntrega,
        'comision_calculada': comisionCalculada,
      };
}