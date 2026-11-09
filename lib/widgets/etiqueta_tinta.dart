import 'package:flutter/material.dart';

/// Etiqueta pequeña de estado: texto de color sobre un fondo del mismo
/// color muy suave.
class EtiquetaTinta extends StatelessWidget {
  final String texto;
  final Color color;
  final Color? colorTexto;

  const EtiquetaTinta({
    super.key,
    required this.texto,
    required this.color,
    this.colorTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorTexto ?? color,
        ),
      ),
    );
  }
}
