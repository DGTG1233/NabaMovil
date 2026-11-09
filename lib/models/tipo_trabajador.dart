enum TipoTrabajador {
  admin,
  supervisor,
  fullTime,
  partTime,
  freelance,
  backOffice,
  visor,
  socioComercial;

  String get valor => switch (this) {
        TipoTrabajador.admin => 'admin',
        TipoTrabajador.supervisor => 'supervisor',
        TipoTrabajador.fullTime => 'full_time',
        TipoTrabajador.partTime => 'part_time',
        TipoTrabajador.freelance => 'freelance',
        TipoTrabajador.backOffice => 'back_office',
        TipoTrabajador.visor => 'visor',
        TipoTrabajador.socioComercial => 'socio_comercial',
      };

  String get label => switch (this) {
        TipoTrabajador.admin => 'Administrador',
        TipoTrabajador.supervisor => 'Supervisor',
        TipoTrabajador.fullTime => 'Full-Time',
        TipoTrabajador.partTime => 'Part-Time',
        TipoTrabajador.freelance => 'Freelance',
        TipoTrabajador.backOffice => 'Back Office',
        TipoTrabajador.visor => 'Visor',
        TipoTrabajador.socioComercial => 'Socio Comercial',
      };

  bool get esVendedor => switch (this) {
        TipoTrabajador.freelance ||
        TipoTrabajador.partTime ||
        TipoTrabajador.fullTime =>
          true,
        _ => false,
      };

  static TipoTrabajador fromValor(String valor) {
    return TipoTrabajador.values.firstWhere(
      (t) => t.valor == valor,
      orElse: () => throw ArgumentError('tipo_trabajador desconocido: $valor'),
    );
  }
}