import 'package:flutter/material.dart';

import '../../data/repositories/historial_pagos.dart';
import '../../models/pago.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/texto.dart';
import '../../widgets/etiqueta_tinta.dart';
import '../../widgets/fila_dato.dart';
import '../morosidad/columnas_cifras.dart';
import 'estado_pago_visual.dart';

/// Detalle de un pago: monto, estado y los datos de la transferencia.
class PagoDetalleScreen extends StatelessWidget {
  final PagoConPersona item;

  const PagoDetalleScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final pago = item.pago;
    final persona = item.persona;
    final fechaPago = pago.fechaPago;
    final transferencia = pago.nroTransferencia;
    final observacion = pago.observacion;
    final pagado = pago.estado == EstadoPago.pagado;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Text(
                    pago.tipoPago.label,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona?.nombreCorto ?? 'Persona no disponible',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titulo(size: 22),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      EtiquetaTinta(
                        texto: pago.estado.label,
                        color: pago.estado.color,
                        colorTexto: pago.estado.colorTexto,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          capitalizar(etiquetaMes(pago.periodo)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textoSecundario),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pagado ? 'Monto pagado' : 'Monto por pagar',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textoSecundario),
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: pago.monto),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, valor, _) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        soles.format(valor),
                        style: AppTypography.titulo(size: 36),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ColumnasCifras(
              cifras: [
                CifraResumen(
                  valor: soles.format(pago.montoCalculado),
                  etiqueta: 'Calculado',
                ),
                CifraResumen(
                  valor: soles.format(pago.montoCalculado - pago.monto),
                  etiqueta: 'Diferencia',
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 26, 22, 8),
              child: _Titulo('Datos del pago'),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.borde),
            FilaDato(etiqueta: 'Tipo de pago', valor: pago.tipoPago.label),
            FilaDato(
              etiqueta: 'Periodo',
              valor: capitalizar(etiquetaMes(pago.periodo)),
            ),
            if (persona != null)
              FilaDato(
                etiqueta: 'Cargo',
                valor: persona.tipoTrabajador.label,
              ),
            if (fechaPago != null)
              FilaDato(etiqueta: 'Fecha de pago', valor: fechaMedia(fechaPago)),
            if (transferencia != null)
              FilaDato(etiqueta: 'N.º de transferencia', valor: transferencia),
            if (observacion != null)
              FilaDato(etiqueta: 'Observación', valor: observacion),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: AppTypography.titulo(
        size: 15,
        weight: FontWeight.w700,
        color: AppColors.texto,
      ),
    );
  }
}
