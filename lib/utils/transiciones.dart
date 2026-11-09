import 'package:flutter/material.dart';

/// Ruta para entrar a una pantalla de detalle: aparece con un
/// desvanecimiento y sube un poco desde abajo.
Route<T> rutaSuave<T>(Widget destino) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => destino,
    transitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (_, animation, _, child) {
      final curva =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curva,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curva),
          child: child,
        ),
      );
    },
  );
}
