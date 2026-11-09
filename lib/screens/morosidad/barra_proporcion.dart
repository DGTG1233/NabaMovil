import 'package:flutter/material.dart';

import '../../models/caso_morosidad.dart';
import '../../theme/app_theme.dart';
import 'estado_morosidad_visual.dart';

/// Barra dividida en tres tramos (al día, en gestión y penalizados) en
/// proporción a su cantidad. Con `animada` se revela de izquierda a derecha.
class BarraProporcion extends StatelessWidget {
  final int alDia;
  final int enGestion;
  final int penalizados;
  final double altura;
  final bool animada;

  const BarraProporcion({
    super.key,
    required this.alDia,
    required this.enGestion,
    required this.penalizados,
    this.altura = 4,
    this.animada = false,
  });

  @override
  Widget build(BuildContext context) {
    final tramos = [
      (alDia, EstadoMorosidad.alDia.color),
      (enGestion, EstadoMorosidad.enGestion.color),
      (penalizados, EstadoMorosidad.penalizado.color),
    ].where((t) => t.$1 > 0).toList();

    final barra = SizedBox(
      height: altura,
      child: tramos.isEmpty
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.borde,
                borderRadius: BorderRadius.circular(altura / 2),
              ),
            )
          : Row(
              children: [
                for (var i = 0; i < tramos.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: tramos[i].$1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tramos[i].$2,
                        borderRadius: BorderRadius.circular(altura / 2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );

    if (!animada) return barra;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      child: barra,
      builder: (_, avance, hijo) =>
          ClipRect(clipper: _RecorteHorizontal(avance), child: hijo),
    );
  }
}

class _RecorteHorizontal extends CustomClipper<Rect> {
  final double avance;

  const _RecorteHorizontal(this.avance);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * avance, size.height);

  @override
  bool shouldReclip(_RecorteHorizontal oldClipper) =>
      oldClipper.avance != avance;
}
