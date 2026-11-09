import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Campo de búsqueda gris con lupa y botón para limpiar. Quien lo usa debe
/// reconstruirlo cuando cambia el texto para que el botón aparezca.
class CampoBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final String sugerencia;
  final ValueChanged<String> onChanged;
  final VoidCallback onLimpiar;

  const CampoBusqueda({
    super.key,
    required this.controller,
    required this.sugerencia,
    required this.onChanged,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: sugerencia,
        hintStyle:
            const TextStyle(color: AppColors.textoSecundario, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded,
            size: 21, color: AppColors.textoSecundario),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                splashRadius: 18,
                icon: const Icon(Icons.close_rounded,
                    size: 19, color: AppColors.textoSecundario),
                onPressed: onLimpiar,
              ),
      ),
    );
  }
}
