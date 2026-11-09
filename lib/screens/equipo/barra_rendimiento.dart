import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Barra delgada de avance sobre la cuota. Se llena al aparecer y cambia a
/// verde cuando se llega al 100 %. Pasar de 100 % no alarga la barra.
class BarraRendimiento extends StatelessWidget {
  /// 1.0 equivale al 100 % de la cuota.
  final double proporcion;
  final double altura;

  const BarraRendimiento({
    super.key,
    required this.proporcion,
    this.altura = 4,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        proporcion >= 1 ? AppColors.positivo : AppColors.azulNabame;
    final llenado = proporcion > 1 ? 1.0 : (proporcion < 0 ? 0.0 : proporcion);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: llenado),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, valor, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(altura / 2),
          child: SizedBox(
            height: altura,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.borde),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: valor,
                  heightFactor: 1,
                  child: ColoredBox(color: color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
