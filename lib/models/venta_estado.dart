import 'tipo_producto.dart';

enum VentaEstado {
  registrado,
  agendado,
  cancelado,
  asignado,
  preparado,
  despachado,
  entregado,
  noEntregado,
  rechazado,
  asignadoTec,
  instalado,
  observado,
  sinFftt;

  String get valor => switch (this) {
        VentaEstado.registrado => 'registrado',
        VentaEstado.agendado => 'agendado',
        VentaEstado.cancelado => 'cancelado',
        VentaEstado.asignado => 'asignado',
        VentaEstado.preparado => 'preparado',
        VentaEstado.despachado => 'despachado',
        VentaEstado.entregado => 'entregado',
        VentaEstado.noEntregado => 'no_entregado',
        VentaEstado.rechazado => 'rechazado',
        VentaEstado.asignadoTec => 'asignado_tec',
        VentaEstado.instalado => 'instalado',
        VentaEstado.observado => 'observado',
        VentaEstado.sinFftt => 'sin_fftt',
      };

  String get label => switch (this) {
        VentaEstado.registrado => 'Registrado',
        VentaEstado.agendado => 'Agendado',
        VentaEstado.cancelado => 'Cancelado',
        VentaEstado.asignado => 'Asignado',
        VentaEstado.preparado => 'Preparado',
        VentaEstado.despachado => 'Despachado',
        VentaEstado.entregado => 'Entregado',
        VentaEstado.noEntregado => 'No Entregado',
        VentaEstado.rechazado => 'Rechazado',
        VentaEstado.asignadoTec => 'Asignado Téc.',
        VentaEstado.instalado => 'Instalado ALTA',
        VentaEstado.observado => 'Observado',
        VentaEstado.sinFftt => 'Sin FFTT',
      };

  String get colorHex => switch (this) {
        VentaEstado.registrado => '#F28D15',
        VentaEstado.agendado => '#019DF4',
        VentaEstado.asignado => '#019DF4',
        VentaEstado.preparado => '#F28D15',
        VentaEstado.despachado => '#019DF4',
        VentaEstado.entregado => '#5CB615',
        VentaEstado.noEntregado => '#983230',
        VentaEstado.rechazado => '#983230',
        VentaEstado.cancelado => '#B6B7B7',
        VentaEstado.asignadoTec => '#019DF4',
        VentaEstado.instalado => '#5CB615',
        VentaEstado.observado => '#642A72',
        VentaEstado.sinFftt => '#F28D15',
      };

  bool get esFinal => switch (this) {
        VentaEstado.entregado || VentaEstado.instalado || VentaEstado.cancelado => true,
        _ => false,
      };

  bool get generaComision => switch (this) {
        VentaEstado.entregado || VentaEstado.instalado => true,
        _ => false,
      };

  static VentaEstado fromValor(String valor) {
    return VentaEstado.values.firstWhere(
      (e) => e.valor == valor,
      orElse: () => throw ArgumentError('estado desconocido: $valor'),
    );
  }

  static List<VentaEstado> paraTipoProducto(TipoProducto tipo) {
    return switch (tipo) {
      TipoProducto.movil || TipoProducto.movistarTotal => const [
          VentaEstado.registrado,
          VentaEstado.agendado,
          VentaEstado.asignado,
          VentaEstado.preparado,
          VentaEstado.despachado,
          VentaEstado.entregado,
          VentaEstado.noEntregado,
          VentaEstado.rechazado,
          VentaEstado.cancelado,
        ],
      TipoProducto.fija => const [
          VentaEstado.registrado,
          VentaEstado.agendado,
          VentaEstado.asignadoTec,
          VentaEstado.observado,
          VentaEstado.sinFftt,
          VentaEstado.instalado,
          VentaEstado.cancelado,
        ],
    };
  }
}