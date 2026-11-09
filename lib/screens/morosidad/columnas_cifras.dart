import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CifraResumen {
  final String valor;
  final String etiqueta;

  /// Punto de color junto a la etiqueta. Opcional.
  final Color? punto;

  const CifraResumen({
    required this.valor,
    required this.etiqueta,
    this.punto,
  });
}

/// Cifras en columnas del mismo ancho, separadas por una línea fina.
class ColumnasCifras extends StatelessWidget {
  final List<CifraResumen> cifras;

  const ColumnasCifras({super.key, required this.cifras});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cifras.length; i++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            left: BorderSide(color: AppColors.borde),
                          ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 14),
                    child: _Cifra(cifra: cifras[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  final CifraResumen cifra;

  const _Cifra({required this.cifra});

  @override
  Widget build(BuildContext context) {
    final punto = cifra.punto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(cifra.valor, style: AppTypography.titulo(size: 22)),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            if (punto != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: punto, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                cifra.etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textoSecundario),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
