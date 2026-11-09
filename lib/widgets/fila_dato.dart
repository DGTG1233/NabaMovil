import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fila de datos: la etiqueta a la izquierda, el valor a la derecha y una
/// línea fina debajo.
class FilaDato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const FilaDato({super.key, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
                fontSize: 13.5, color: AppColors.textoSecundario),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
