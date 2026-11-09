import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Píldora de selección simple: gris en reposo, azul suave cuando está
/// activa.
class PildoraFiltro extends StatelessWidget {
  final String texto;
  final bool activa;
  final VoidCallback onTap;

  const PildoraFiltro({
    super.key,
    required this.texto,
    required this.activa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: activa
              ? AppColors.azulNabame.withValues(alpha: 0.10)
              : AppColors.superficie,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: activa ? AppColors.azulNabame : AppColors.textoSecundario,
          ),
        ),
      ),
    );
  }
}
