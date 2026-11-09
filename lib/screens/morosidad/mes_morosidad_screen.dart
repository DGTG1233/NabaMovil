import 'package:flutter/material.dart';

import '../../data/repositories/resumen_morosidad.dart';
import '../../models/caso_morosidad.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/texto.dart';
import '../../utils/transiciones.dart';
import '../../widgets/estados_vista.dart';
import '../../widgets/etiqueta_tinta.dart';
import '../../widgets/pildora_filtro.dart';
import 'barra_proporcion.dart';
import 'caso_morosidad_screen.dart';
import 'columnas_cifras.dart';
import 'estado_morosidad_visual.dart';

/// Casos de un mes de alta, con un filtro por estado.
class MesMorosidadScreen extends StatefulWidget {
  final ResumenMesMorosidad mes;
  final ResumenMorosidad resumen;

  const MesMorosidadScreen({
    super.key,
    required this.mes,
    required this.resumen,
  });

  @override
  State<MesMorosidadScreen> createState() => _MesMorosidadScreenState();
}

class _MesMorosidadScreenState extends State<MesMorosidadScreen> {
  EstadoMorosidad? _filtro;

  void _abrirCaso(CasoMorosidad caso) {
    Navigator.of(context).push(
      rutaSuave<void>(
        CasoMorosidadScreen(
          caso: caso,
          vendedor: widget.resumen.vendedorDe(caso),
        ),
      ),
    );
  }

  Widget? _etiquetaCierre() {
    final mes = widget.mes;
    if (mes.cerrado) {
      return const EtiquetaTinta(
        texto: 'Cerrado',
        color: AppColors.textoSecundario,
      );
    }
    if (!mes.cierreProximo) return null;
    return EtiquetaTinta(
      texto: mes.diasParaCierre == 0
          ? 'Cierra hoy'
          : 'Cierra en ${cantidadDe(mes.diasParaCierre, 'día', 'días')}',
      color: EstadoMorosidad.penalizado.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final mes = widget.mes;
    final casos = mes.conEstado(_filtro);
    final etiqueta = _etiquetaCierre();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
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
                    widget.resumen.segmento.label,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      capitalizar(etiquetaMes(mes.mesAlta)),
                      style: AppTypography.titulo(size: 26),
                    ),
                  ),
                  ?etiqueta,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              child: BarraProporcion(
                alDia: mes.alDia,
                enGestion: mes.enGestion,
                penalizados: mes.penalizados,
                altura: 8,
                animada: true,
              ),
            ),
            ColumnasCifras(
              cifras: [
                CifraResumen(
                  valor: '${mes.enGestion}',
                  etiqueta: EstadoMorosidad.enGestion.label,
                  punto: EstadoMorosidad.enGestion.color,
                ),
                CifraResumen(
                  valor: '${mes.penalizados}',
                  etiqueta: 'Penalizados',
                  punto: EstadoMorosidad.penalizado.color,
                ),
                CifraResumen(
                  valor: soles.format(mes.penalidad),
                  etiqueta: 'Penalidad',
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
              child: Row(
                children: [
                  PildoraFiltro(
                    texto: 'Todos',
                    activa: _filtro == null,
                    onTap: () => setState(() => _filtro = null),
                  ),
                  for (final estado in [
                    EstadoMorosidad.enGestion,
                    EstadoMorosidad.penalizado,
                    EstadoMorosidad.alDia,
                  ]) ...[
                    const SizedBox(width: 8),
                    PildoraFiltro(
                      texto: estado.label,
                      activa: _filtro == estado,
                      onTap: () => setState(() => _filtro = estado),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.borde),
            if (casos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EstadoVacio(
                  icono: Icons.search_off_rounded,
                  titulo: 'Sin casos',
                  mensaje: 'No hay casos con este estado en el mes.',
                ),
              )
            else
              for (final caso in casos)
                _FilaCaso(
                  caso: caso,
                  vendedor: widget.resumen.vendedorDe(caso)?.nombreCorto,
                  onTap: () => _abrirCaso(caso),
                ),
          ],
        ),
      ),
    );
  }
}

class _FilaCaso extends StatelessWidget {
  final CasoMorosidad caso;
  final String? vendedor;
  final VoidCallback onTap;

  const _FilaCaso({
    required this.caso,
    required this.vendedor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final estado = caso.estado;
    final esMovil = caso.segmento == SegmentoMorosidad.movil;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borde)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: estado.color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                esMovil ? Icons.smartphone_outlined : Icons.wifi_rounded,
                size: 21,
                color: estado.colorTexto,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caso.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vendedor ?? 'Sin vendedor'}  ·  Plan ${soles.format(caso.cargoFijo)}',
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
                  soles.format(caso.deudaTotal),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  estado.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: estado.colorTexto,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
