enum TipoProducto {
  movil,
  fija,
  movistarTotal;

  String get valor => switch (this) {
        TipoProducto.movil => 'movil',
        TipoProducto.fija => 'fija',
        TipoProducto.movistarTotal => 'movistar_total',
      };

  String get label => switch (this) {
        TipoProducto.movil => 'Móvil Postpago',
        TipoProducto.fija => 'Hogar Fija',
        TipoProducto.movistarTotal => 'Movistar Total',
      };

  List<String> get origenes => switch (this) {
        TipoProducto.movil => const ['ALTA', 'PORTA_O_POST', 'PORTA_O_PRE'],
        TipoProducto.fija => const ['MONO', 'DUO', 'TRIO'],
        TipoProducto.movistarTotal => const [
            'PAQUETIZACION',
            'COMPLETA_MOVIL',
            'COMPLETA_FIJA'
          ],
      };

  static TipoProducto fromValor(String valor) {
    return TipoProducto.values.firstWhere(
      (t) => t.valor == valor,
      orElse: () => throw ArgumentError('tipo_producto desconocido: $valor'),
    );
  }
}