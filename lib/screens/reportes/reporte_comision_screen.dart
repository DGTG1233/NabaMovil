import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/arbol_equipo.dart';
import '../../data/repositories/reporte_comision.dart';
import '../../data/repositories/venta_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/texto.dart';
import '../../utils/transiciones.dart';
import '../../widgets/estados_vista.dart';
import '../../widgets/pildora_filtro.dart';
import '../equipo/avatar_persona.dart';
import '../equipo/persona_detalle_screen.dart';
import '../morosidad/columnas_cifras.dart';
import 'reporte_socio_screen.dart';

/// Comisión generada por mes, agrupada por Socio Comercial.
class ReporteComisionScreen extends StatefulWidget {
  const ReporteComisionScreen({super.key});

  static Future<void> abrir(BuildContext context) {
    return Navigator.of(context).push(
      rutaSuave<void>(const ReporteComisionScreen()),
    );
  }

  @override
  State<ReporteComisionScreen> createState() => _ReporteComisionScreenState();
}

class _ReporteComisionScreenState extends State<ReporteComisionScreen> {
  late Future<ReporteComision> _datos;
  String? _mes;

  @override
  void initState() {
    super.initState();
    _datos = _cargar();
  }

  Future<ReporteComision> _cargar() {
    return context.read<VentaRepository>().reporteComision(mes: _mes);
  }

  void _elegirMes(String mes) {
    setState(() {
      _mes = mes;
      _datos = _cargar();
    });
  }

  Future<void> _recargar() async {
    final nuevo = _cargar();
    setState(() {
      _datos = nuevo;
    });
    try {
      await nuevo;
    } catch (_) {
      // El FutureBuilder ya muestra el error con su botón de reintento.
    }
  }

  void _abrirSocio(ReporteComision reporte, NodoEquipo socio) {
    Navigator.of(context).push(
      rutaSuave<void>(ReporteSocioScreen(reporte: reporte, socio: socio)),
    );
  }

  void _abrirPersona(ReporteComision reporte, NodoEquipo nodo) {
    Navigator.of(context).push(
      rutaSuave<void>(PersonaDetalleScreen(nodo: nodo, mes: reporte.mes)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reportes', style: AppTypography.titulo(size: 26)),
                  const SizedBox(height: 4),
                  const Text(
                    'Comisión generada por Socio Comercial',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<ReporteComision>(
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
                      mensaje: 'No se pudo cargar el reporte.',
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

  Widget _contenido(ReporteComision reporte) {
    if (reporte.mesesDisponibles.isEmpty) {
      return const EstadoVacio(
        icono: Icons.insights_outlined,
        titulo: 'Sin comisiones',
        mensaje: 'Todavía no hay ventas entregadas que generen comisión.',
      );
    }

    const soles = FormatoSoles();

    return RefreshIndicator(
      color: AppColors.azulNabame,
      onRefresh: _recargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                for (var i = 0; i < reporte.mesesDisponibles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  PildoraFiltro(
                    texto: capitalizar(etiquetaMes(reporte.mesesDisponibles[i])),
                    activa: reporte.mesesDisponibles[i] == reporte.mes,
                    onTap: () => _elegirMes(reporte.mesesDisponibles[i]),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comisión generada en ${etiquetaMes(reporte.mes)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  key: ValueKey(reporte.mes),
                  tween: Tween<double>(begin: 0, end: reporte.comisionTotal),
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
                valor: '${reporte.socios.length}',
                etiqueta: 'Socios',
              ),
              CifraResumen(
                valor: '${reporte.ventasEntregadas}',
                etiqueta: 'Ventas entregadas',
              ),
              CifraResumen(
                valor: '${reporte.personas}',
                etiqueta: 'Personas',
              ),
            ],
          ),
          if (reporte.socios.isNotEmpty) ...[
            const _EncabezadoLista(
              titulo: 'Por Socio Comercial',
              detalle: 'Comisión generada',
            ),
            for (final socio in reporte.socios) ...[
              _FilaSocio(
                nodo: socio,
                participacion: reporte.participacionDe(socio),
                onTap: () => _abrirSocio(reporte, socio),
              ),
              const _Linea(),
            ],
          ],
          if (reporte.sinSocio.isNotEmpty) ...[
            const _EncabezadoLista(
              titulo: 'Sin Socio Comercial',
              detalle: 'Comisión generada',
            ),
            for (final nodo in reporte.sinSocio) ...[
              _FilaSuelta(
                nodo: nodo,
                onTap: () => _abrirPersona(reporte, nodo),
              ),
              const _Linea(),
            ],
          ],
        ],
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borde,
      indent: 22,
      endIndent: 22,
    );
  }
}

class _EncabezadoLista extends StatelessWidget {
  final String titulo;
  final String detalle;

  const _EncabezadoLista({required this.titulo, required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: AppTypography.titulo(
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.texto,
              ),
            ),
          ),
          Text(
            detalle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _FilaSocio extends StatelessWidget {
  final NodoEquipo nodo;
  final double participacion;
  final VoidCallback onTap;

  const _FilaSocio({
    required this.nodo,
    required this.participacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final persona = nodo.persona;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          children: [
            AvatarPersona(persona: persona, tamano: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.nombreCorto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titulo(
                      size: 15,
                      weight: FontWeight.w700,
                      color: AppColors.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cantidadDe(nodo.personasACargo, 'persona a cargo', 'personas a cargo'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  soles.format(nodo.comisionMes),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(participacion * 100).round()} % del total',
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

class _FilaSuelta extends StatelessWidget {
  final NodoEquipo nodo;
  final VoidCallback onTap;

  const _FilaSuelta({required this.nodo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final persona = nodo.persona;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Row(
          children: [
            AvatarPersona(persona: persona, tamano: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.nombreCorto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    persona.tipoTrabajador.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  soles.format(nodo.comisionMes),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  cantidadDe(nodo.ventasEntregadas, 'venta', 'ventas'),
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
