import 'package:flutter/material.dart';

import '../../models/venta_estado.dart';

extension VentaEstadoVisual on VentaEstado {
  Color get color {
    final limpio = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$limpio', radix: 16));
  }

  IconData get icono => switch (this) {
        VentaEstado.registrado => Icons.assignment_outlined,
        VentaEstado.agendado => Icons.event_outlined,
        VentaEstado.cancelado => Icons.remove_circle_outline,
        VentaEstado.asignado => Icons.person_outline,
        VentaEstado.preparado => Icons.inventory_2_outlined,
        VentaEstado.despachado => Icons.local_shipping_outlined,
        VentaEstado.entregado => Icons.check_circle_outline,
        VentaEstado.noEntregado => Icons.cancel_outlined,
        VentaEstado.rechazado => Icons.block_outlined,
        VentaEstado.asignadoTec => Icons.engineering_outlined,
        VentaEstado.instalado => Icons.task_alt_outlined,
        VentaEstado.observado => Icons.visibility_outlined,
        VentaEstado.sinFftt => Icons.report_problem_outlined,
      };
}