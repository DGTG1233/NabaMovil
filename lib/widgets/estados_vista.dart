import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado vacío o sin resultados: ícono tintado, título, explicación y,
/// si hace falta, una acción.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoAccion;
  final VoidCallback? onAccion;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoAccion,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    final texto = textoAccion;
    final alAccionar = onAccion;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.azulNabame.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: AppColors.azulNabame, size: 28),
            ),
            const SizedBox(height: 16),
            Text(titulo, style: AppTypography.titulo(size: 18)),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textoSecundario,
              ),
            ),
            if (texto != null && alAccionar != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: alAccionar, child: Text(texto)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error de carga con botón para reintentar.
class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const EstadoError({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.negativo, size: 36),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
