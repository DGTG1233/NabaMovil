import 'usuario.dart';

/// Lectura de la cadena de ventas (Socio Comercial, Supervisor, Vendedor).
/// Los valores de texto viven solo aquí para no repetirlos en pantallas.
extension JerarquiaDeUsuario on Usuario {
  bool get esSocioComercial => tipoTrabajador.valor == 'socio_comercial';

  bool get esSupervisor => tipoTrabajador.valor == 'supervisor';

  bool get esVendedor => tipoTrabajador.esVendedor;

  /// Quien puede tener gente a su cargo.
  bool get puedeTenerEquipo => esSocioComercial || esSupervisor;

  /// Visor, Back Office y Administrador quedan fuera de la vista Equipo.
  bool get perteneceALaCadenaDeVentas => puedeTenerEquipo || esVendedor;
}
