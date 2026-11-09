import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../models/usuario_jerarquia.dart';
import '../../theme/app_theme.dart';

/// Iniciales en un círculo. El color distingue el cargo: marino para el
/// Socio Comercial, azul suave para el Supervisor y gris para el resto.
class AvatarPersona extends StatelessWidget {
  final Usuario persona;
  final double tamano;

  const AvatarPersona({super.key, required this.persona, this.tamano = 44});

  @override
  Widget build(BuildContext context) {
    final (fondo, letra) = _colores();

    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
      child: Text(
        persona.iniciales,
        style: TextStyle(
          color: letra,
          fontSize: tamano * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (Color, Color) _colores() {
    if (!persona.activo) {
      return (AppColors.superficie, AppColors.textoSecundario);
    }
    if (persona.esSocioComercial) {
      return (AppColors.marinoNabame, Colors.white);
    }
    if (persona.esSupervisor) {
      return (
        AppColors.azulNabame.withValues(alpha: 0.12),
        AppColors.azulNabame,
      );
    }
    return (AppColors.superficie, AppColors.marinoNabame);
  }
}
