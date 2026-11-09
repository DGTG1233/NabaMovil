import 'package:flutter/material.dart';

import '../../data/repositories/venta_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import 'estado_visual.dart';

/// Fila de una venta: ícono del estado, cliente, estado y monto. Se usa en
/// el listado de Ventas y en el detalle de una persona del equipo.
class FilaVenta extends StatelessWidget {
  final VentaConVendedor item;
  final VoidCallback onTap;

  /// Cuando la lista ya es de una sola persona, el vendedor sobra y se
  /// muestra el tipo de producto en su lugar.
  final bool mostrarVendedor;

  const FilaVenta({
    super.key,
    required this.item,
    required this.onTap,
    this.mostrarVendedor = true,
  });

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final v = item.venta;
    final color = v.estado.color;
    final complemento = mostrarVendedor
        ? (item.vendedor?.nombreCorto ?? 'Sin vendedor')
        : v.tipoProducto.label;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(v.estado.icono, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.nombreCliente,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: v.estado.label,
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: '  ·  $complemento'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  soles.format(v.cargoFijo),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  fechaCorta(v.fechaRegistro),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textoSecundario),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
