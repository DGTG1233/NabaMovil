import 'package:flutter/material.dart';

import '../../models/caso_morosidad.dart';
import '../../models/usuario.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../widgets/etiqueta_tinta.dart';
import '../../widgets/fila_dato.dart';
import 'columnas_cifras.dart';
import 'estado_morosidad_visual.dart';

/// Detalle de un caso: deuda, penalidad y el estado de sus tres recibos.
class CasoMorosidadScreen extends StatelessWidget {
  final CasoMorosidad caso;
  final Usuario? vendedor;

  const CasoMorosidadScreen({
    super.key,
    required this.caso,
    required this.vendedor,
  });

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final estado = caso.estado;
    final esMovil = caso.segmento == SegmentoMorosidad.movil;

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
                    caso.segmento.label,
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
                    caso.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titulo(size: 26),
                  ),
                  if (caso.cliente != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Petición ${caso.identificador}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textoSecundario),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      EtiquetaTinta(
                        texto: estado.label,
                        color: estado.color,
                        colorTexto: estado.colorTexto,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Alta el ${fechaCorta(caso.fechaAlta)}',
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
            const SizedBox(height: 22),
            ColumnasCifras(
              cifras: [
                CifraResumen(
                  valor: soles.format(caso.deudaTotal),
                  etiqueta: 'Deuda',
                  punto: caso.deudaTotal > 0
                      ? EstadoMorosidad.penalizado.color
                      : null,
                ),
                CifraResumen(
                  valor: soles.format(caso.penalidad),
                  etiqueta: 'Penalidad (x2)',
                ),
              ],
            ),
            const _TituloSeccion('Recibos'),
            const Divider(height: 1, thickness: 1, color: AppColors.borde),
            for (var n = 1; n <= 3; n++) _FilaRecibo(caso: caso, numero: n),
            const _TituloSeccion('Caso'),
            const Divider(height: 1, thickness: 1, color: AppColors.borde),
            FilaDato(
              etiqueta: 'Vendedor',
              valor: vendedor?.nombreCompleto ?? 'Sin vendedor',
            ),
            FilaDato(
              etiqueta: esMovil ? 'Plan' : 'Cargo fijo',
              valor: soles.format(caso.cargoFijo),
            ),
            FilaDato(
              etiqueta: 'Datos al',
              valor: fechaMedia(caso.fechaProceso),
            ),
            FilaDato(
              etiqueta: 'Cierre de penalización',
              valor: fechaMedia(caso.cierrePenalizacion),
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String texto;

  const _TituloSeccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 8),
      child: Text(
        texto,
        style: AppTypography.titulo(
          size: 15,
          weight: FontWeight.w700,
          color: AppColors.texto,
        ),
      ),
    );
  }
}

class _FilaRecibo extends StatelessWidget {
  final CasoMorosidad caso;
  final int numero;

  const _FilaRecibo({required this.caso, required this.numero});

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final recibo = caso.recibo(numero);

    final String titulo;
    final String detalle;
    final String monto;
    final Color color;
    final Color colorTexto;

    if (recibo == null) {
      final faltaSiguiente = caso.esPenalizado && caso.tieneRecibo(numero - 1);
      titulo = 'No emitido';
      detalle = faltaSiguiente ? 'No se emitió a tiempo' : 'Sin emisión';
      monto = '-';
      color = AppColors.textoSecundario;
      colorTexto = AppColors.textoSecundario;
    } else if (recibo.tieneDeuda) {
      titulo = 'Pendiente';
      detalle = 'Vence el ${fechaCorta(recibo.vencimiento)}';
      monto = soles.format(recibo.pendiente);
      color = EstadoMorosidad.enGestion.color;
      colorTexto = EstadoMorosidad.enGestion.colorTexto;
    } else {
      final fechaPago = recibo.fechaPago;
      titulo = 'Pagado';
      detalle = fechaPago == null
          ? 'Sin fecha de pago'
          : 'Pagó el ${fechaCorta(fechaPago)}';
      monto = soles.format(recibo.pagado);
      color = EstadoMorosidad.alDia.color;
      colorTexto = EstadoMorosidad.alDia.colorTexto;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: AppTypography.titulo(
                size: 15,
                weight: FontWeight.w700,
                color: colorTexto,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textoSecundario),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            monto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: recibo == null ? AppColors.textoSecundario : colorTexto,
            ),
          ),
        ],
      ),
    );
  }
}
