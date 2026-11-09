import 'package:flutter/material.dart';

import '../../models/caso_morosidad.dart';
import '../../theme/paleta_estado.dart';

/// Texto y colores de cada estado. `color` sirve para barras y fondos;
/// `colorTexto` es un tono más oscuro que se lee bien sobre blanco.
extension EstadoMorosidadVisual on EstadoMorosidad {
  String get label => switch (this) {
        EstadoMorosidad.alDia => 'Al día',
        EstadoMorosidad.enGestion => 'En gestión',
        EstadoMorosidad.penalizado => 'Penalizado',
      };

  Color get color => switch (this) {
        EstadoMorosidad.alDia => PaletaEstado.verde,
        EstadoMorosidad.enGestion => PaletaEstado.ambar,
        EstadoMorosidad.penalizado => PaletaEstado.rojo,
      };

  Color get colorTexto => switch (this) {
        EstadoMorosidad.alDia => PaletaEstado.verdeTexto,
        EstadoMorosidad.enGestion => PaletaEstado.ambarTexto,
        EstadoMorosidad.penalizado => PaletaEstado.rojo,
      };
}
