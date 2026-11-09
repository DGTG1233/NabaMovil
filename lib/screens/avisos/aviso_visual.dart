import 'package:flutter/material.dart';

import '../../data/repositories/avisos.dart';
import '../../theme/app_theme.dart';
import '../../theme/paleta_estado.dart';

extension TipoAvisoVisual on TipoAviso {
  IconData get icono => switch (this) {
        TipoAviso.cierreMorosidad => Icons.event_busy_outlined,
        TipoAviso.pagoPendiente => Icons.payments_outlined,
        TipoAviso.ventaNoEntregada => Icons.receipt_long_outlined,
      };

  /// Para el fondo suave del círculo.
  Color get color => switch (this) {
        TipoAviso.cierreMorosidad => PaletaEstado.rojo,
        TipoAviso.pagoPendiente => PaletaEstado.ambar,
        TipoAviso.ventaNoEntregada => AppColors.azulNabame,
      };

  /// Para el ícono, un tono que se lee bien sobre el fondo suave.
  Color get colorIcono => switch (this) {
        TipoAviso.cierreMorosidad => PaletaEstado.rojo,
        TipoAviso.pagoPendiente => PaletaEstado.ambarTexto,
        TipoAviso.ventaNoEntregada => AppColors.azulNabame,
      };
}
