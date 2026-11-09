import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EnConstruccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;

  const EnConstruccion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.azulNabame.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, color: AppColors.azulNabame, size: 32),
                ),
                const SizedBox(height: 20),
                Text(titulo, style: AppTypography.titulo(size: 20)),
                const SizedBox(height: 8),
                Text(
                  descripcion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}