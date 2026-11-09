import 'package:flutter/material.dart';

/// Colores de estado compartidos por las pantallas: verde para lo
/// resuelto, ámbar para lo pendiente y rojo para lo crítico. Los tonos
/// "texto" son más oscuros y se leen bien sobre blanco.
class PaletaEstado {
  PaletaEstado._();

  static const verde = Color(0xFF5CB615);
  static const verdeTexto = Color(0xFF3F8A0B);
  static const ambar = Color(0xFFF28D15);
  static const ambarTexto = Color(0xFFB8650A);
  static const rojo = Color(0xFF983230);
}
