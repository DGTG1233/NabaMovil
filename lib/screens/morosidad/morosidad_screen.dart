import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/morosidad_repository.dart';
import '../../data/repositories/resumen_morosidad.dart';
import '../../models/caso_morosidad.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/texto.dart';
import '../../utils/transiciones.dart';
import '../../widgets/estados_vista.dart';
import 'barra_proporcion.dart';
import 'columnas_cifras.dart';
import 'estado_morosidad_visual.dart';
import 'mes_morosidad_screen.dart';

class MorosidadScreen extends StatefulWidget {
  const MorosidadScreen({super.key});

  static Future<void> abrir(BuildContext context) {
    return Navigator.of(context).push(
      rutaSuave<void>(const MorosidadScreen()),
    );
  }

  @override
  State<MorosidadScreen> createState() => _MorosidadScreenState();
}

class _MorosidadScreenState extends State<MorosidadScreen> {
  late Future<DatosMorosidad> _datos;
  SegmentoMorosidad _segmento = SegmentoMorosidad.movil;

  @override
  void initState() {
    super.initState();
    _datos = context.read<MorosidadRepository>().cargar();
  }

  Future<void> _recargar() async {
    final nuevo = context.read<MorosidadRepository>().cargar();
    setState(() {
      _datos = nuevo;
    });
    try {
      await nuevo;
    } catch (_) {
      // El FutureBuilder ya muestra el error con su botón de reintento.
    }
  }

  void _abrirMes(ResumenMorosidad resumen, ResumenMesMorosidad mes) {
    Navigator.of(context).push(
      rutaSuave<void>(MesMorosidadScreen(mes: mes, resumen: resumen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Morosidad', style: AppTypography.titulo(size: 26)),
              ),
            ),
            Expanded(
              child: FutureBuilder<DatosMorosidad>(
                future: _datos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.azulNabame),
                    );
                  }
                  if (snapshot.hasError) {
                    return EstadoError(
                      mensaje: 'No se pudo cargar la morosidad.',
                      onReintentar: _recargar,
                    );
                  }
                  return _contenido(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido(DatosMorosidad datos) {
    final resumen = datos.de(_segmento);

    return RefreshIndicator(
      color: AppColors.azulNabame,
      onRefresh: _recargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _SelectorSegmento(
              segmento: _segmento,
              onCambiar: (s) => setState(() => _segmento = s),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: KeyedSubtree(
              key: ValueKey(_segmento),
              child: _ContenidoSegmento(
                resumen: resumen,
                onAbrirMes: (mes) => _abrirMes(resumen, mes),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de dos opciones del mismo ancho. El fondo oscuro se desliza
/// de una a otra.
class _SelectorSegmento extends StatelessWidget {
  final SegmentoMorosidad segmento;
  final ValueChanged<SegmentoMorosidad> onCambiar;

  const _SelectorSegmento({required this.segmento, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    final enMovil = segmento == SegmentoMorosidad.movil;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: enMovil ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.marinoNabame,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                for (final s in SegmentoMorosidad.values)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onCambiar(s),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 240),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: s == segmento
                                ? Colors.white
                                : AppColors.textoSecundario,
                          ),
                          child: Text(s.label),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContenidoSegmento extends StatelessWidget {
  final ResumenMorosidad resumen;
  final ValueChanged<ResumenMesMorosidad> onAbrirMes;

  const _ContenidoSegmento({required this.resumen, required this.onAbrirMes});

  @override
  Widget build(BuildContext context) {
    if (resumen.estaVacio) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: EstadoVacio(
          icono: Icons.event_available_outlined,
          titulo: 'Sin casos de morosidad',
          mensaje:
              'No hay casos de ${resumen.segmento.label.toLowerCase()} cargados.',
        ),
      );
    }

    const soles = FormatoSoles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deuda por gestionar',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: resumen.deudaPorGestionar),
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
              const SizedBox(height: 4),
              Text(
                'Datos al ${fechaMedia(resumen.fechaCorte)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textoSecundario),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: BarraProporcion(
            alDia: resumen.alDia,
            enGestion: resumen.enGestion,
            penalizados: resumen.penalizados,
            altura: 8,
            animada: true,
          ),
        ),
        ColumnasCifras(
          cifras: [
            CifraResumen(
              valor: '${resumen.alDia}',
              etiqueta: EstadoMorosidad.alDia.label,
              punto: EstadoMorosidad.alDia.color,
            ),
            CifraResumen(
              valor: '${resumen.enGestion}',
              etiqueta: EstadoMorosidad.enGestion.label,
              punto: EstadoMorosidad.enGestion.color,
            ),
            CifraResumen(
              valor: '${resumen.penalizados}',
              etiqueta: 'Penalizados',
              punto: EstadoMorosidad.penalizado.color,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Por mes de alta',
                  style: AppTypography.titulo(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.texto,
                  ),
                ),
              ),
              const Text(
                'Deuda en gestión',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textoSecundario),
              ),
            ],
          ),
        ),
        for (final mes in resumen.meses) ...[
          _FilaMes(mes: mes, onTap: () => onAbrirMes(mes)),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borde,
            indent: 22,
            endIndent: 22,
          ),
        ],
      ],
    );
  }
}

class _FilaMes extends StatelessWidget {
  final ResumenMesMorosidad mes;
  final VoidCallback onTap;

  const _FilaMes({required this.mes, required this.onTap});

  String get _textoCierre {
    if (mes.cerrado) return 'Cerrado el ${fechaCorta(mes.cierre)}';
    final base = 'Cierra el ${fechaCorta(mes.cierre)}';
    if (!mes.cierreProximo) return base;
    return mes.diasParaCierre == 0
        ? '$base, hoy'
        : '$base, en ${cantidadDe(mes.diasParaCierre, 'día', 'días')}';
  }

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: mes.cerrado ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 13, 22, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      capitalizar(etiquetaMes(mes.mesAlta)),
                      style: AppTypography.titulo(
                        size: 15,
                        weight: FontWeight.w700,
                        color: AppColors.texto,
                      ),
                    ),
                  ),
                  Text(
                    soles.format(mes.deudaEnGestion),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _textoCierre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            mes.cierreProximo ? FontWeight.w600 : FontWeight.w400,
                        color: mes.cierreProximo
                            ? EstadoMorosidad.penalizado.colorTexto
                            : AppColors.textoSecundario,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${mes.enGestion} en gestión',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textoSecundario),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              BarraProporcion(
                alDia: mes.alDia,
                enGestion: mes.enGestion,
                penalizados: mes.penalizados,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
