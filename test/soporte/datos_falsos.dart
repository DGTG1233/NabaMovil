import 'package:nabamemovil/data/datasource/data_source.dart';
import 'package:nabamemovil/models/caso_morosidad.dart';
import 'package:nabamemovil/models/pago.dart';
import 'package:nabamemovil/models/tipo_producto.dart';
import 'package:nabamemovil/models/tipo_trabajador.dart';
import 'package:nabamemovil/models/usuario.dart';
import 'package:nabamemovil/models/venta.dart';
import 'package:nabamemovil/models/venta_estado.dart';

/// Origen de datos en memoria para probar sin leer los JSON.
class DataSourceFalso implements DataSource {
  final List<Usuario> usuarios;
  final List<Venta> ventas;
  final List<CasoMorosidad> morosidad;

  DataSourceFalso(this.usuarios, this.ventas, [this.morosidad = const []]);

  @override
  Future<List<Usuario>> getUsuarios() async => usuarios;

  @override
  Future<List<Venta>> getVentas() async => ventas;

  @override
  Future<List<Pago>> getPagos() async => [];

  @override
  Future<List<CasoMorosidad>> getMorosidad() async => morosidad;
}

/// `tipo` usa el valor de intercambio del JSON ('supervisor', 'full_time').
Usuario usuarioPrueba({
  required int id,
  String nombre = 'Nombre',
  String apellido = 'Apellido',
  String tipo = 'freelance',
  int? supervisorId,
  bool activo = true,
  double? cuota,
}) =>
    Usuario(
      id: id,
      nombre: nombre,
      apellidoPaterno: apellido,
      apellidoMaterno: 'Test',
      dni: '7000000$id',
      email: '$id@test.pe',
      tipoTrabajador: TipoTrabajador.fromValor(tipo),
      supervisorId: supervisorId,
      activo: activo,
      cuotaMensual: cuota,
    );

/// El mes se deduce de la fecha.
Venta ventaPrueba({
  required int id,
  required int userId,
  required DateTime fecha,
  String cliente = 'Cliente',
  VentaEstado estado = VentaEstado.entregado,
  double? comision,
}) =>
    Venta(
      id: id,
      userId: userId,
      mes: '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}',
      fechaRegistro: fecha,
      canal: 'D2D',
      tipoProducto: TipoProducto.movil,
      origenVenta: 'ALTA',
      cargoFijo: 89.9,
      dniCliente: '4500000$id',
      nombreCliente: cliente,
      numeroContacto: '94000000$id',
      estado: estado,
      comisionCalculada: comision,
    );

/// Recibo número `numero`: se emite el día 10 de un mes que avanza con el
/// número y vence quince días después.
ReciboMorosidad reciboPrueba(
  int numero, {
  double facturado = 40,
  double pagado = 0,
  double ajuste = 0,
}) =>
    ReciboMorosidad(
      numero: numero,
      emision: DateTime(2026, 7 + numero, 10),
      vencimiento: DateTime(2026, 7 + numero, 25),
      facturado: facturado,
      ajuste: ajuste,
      pagado: pagado,
      fechaPago: pagado > 0 ? DateTime(2026, 7 + numero, 20) : null,
    );

CasoMorosidad casoPrueba({
  required int id,
  SegmentoMorosidad segmento = SegmentoMorosidad.movil,
  int userId = 1,
  String mesAlta = '2026-06',
  double cargoFijo = 40,
  List<ReciboMorosidad> recibos = const [],
}) =>
    CasoMorosidad(
      id: id,
      segmento: segmento,
      userId: userId,
      identificador: '9000000$id',
      mesAlta: mesAlta,
      fechaAlta: DateTime.parse('$mesAlta-10'),
      cargoFijo: cargoFijo,
      fechaProceso: DateTime(2026, 10, 16),
      recibos: recibos,
    );
