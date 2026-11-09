import 'package:flutter/material.dart';

import '../../data/repositories/avisos.dart';
import '../morosidad/morosidad_screen.dart';
import '../shell/pestanas.dart';

/// Lleva a la pantalla a la que apunta un aviso: Morosidad se abre encima y
/// las demás son pestañas de la barra inferior.
void irADestinoAviso(
  BuildContext context,
  DestinoAviso destino, {
  ValueChanged<int>? onIrAPestana,
}) {
  switch (destino) {
    case DestinoAviso.morosidad:
      MorosidadScreen.abrir(context);
    case DestinoAviso.historial:
      onIrAPestana?.call(Pestanas.historial);
    case DestinoAviso.ventas:
      onIrAPestana?.call(Pestanas.ventas);
  }
}
