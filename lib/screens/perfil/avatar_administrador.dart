import 'package:flutter/material.dart';

import '../../models/perfil_administrador.dart';
import '../../theme/app_theme.dart';

/// Círculo marino con la inicial del Administrador.
class AvatarAdministrador extends StatelessWidget {
  final double tamano;

  const AvatarAdministrador({super.key, this.tamano = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.marinoNabame,
        shape: BoxShape.circle,
      ),
      child: Text(
        PerfilAdministrador.inicial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: tamano * 0.375,
        ),
      ),
    );
  }
}
