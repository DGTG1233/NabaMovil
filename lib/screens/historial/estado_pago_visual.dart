import 'package:flutter/material.dart';

import '../../models/pago.dart';
import '../../theme/paleta_estado.dart';

extension EstadoPagoVisual on EstadoPago {
  String get label => switch (this) {
        EstadoPago.pagado => 'Pagado',
        EstadoPago.pendiente => 'Pendiente',
      };

  /// Para fondos y barras.
  Color get color => switch (this) {
        EstadoPago.pagado => PaletaEstado.verde,
        EstadoPago.pendiente => PaletaEstado.ambar,
      };

  /// Tono más oscuro para texto sobre blanco.
  Color get colorTexto => switch (this) {
        EstadoPago.pagado => PaletaEstado.verdeTexto,
        EstadoPago.pendiente => PaletaEstado.ambarTexto,
      };
}

extension TipoPagoVisual on TipoPago {
  IconData get icono => switch (this) {
        TipoPago.comision => Icons.percent_rounded,
        TipoPago.bono => Icons.star_outline_rounded,
        TipoPago.sueldo => Icons.account_balance_wallet_outlined,
      };
}
