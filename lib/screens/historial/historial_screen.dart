import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/historial_pagos.dart';
import '../../data/repositories/pago_repository.dart';
import '../../models/pago.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/texto.dart';
import '../../utils/transiciones.dart';
import '../../widgets/campo_busqueda.dart';
import '../../widgets/estados_vista.dart';
import '../../widgets/pildora_filtro.dart';
import '../morosidad/columnas_cifras.dart';
import 'estado_pago_visual.dart';
import 'pago_detalle_screen.dart';

/// Historial de pagos: lo pagado y lo pendiente, con filtros por estado y
/// tipo, y la lista agrupada por periodo.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<HistorialPagos> _datos;
  final _busquedaController = TextEditingController();
  String _consulta = '';
  EstadoPago? _estado;
  TipoPago? _tipo;

  bool get _hayFiltros =>
      _estado != null || _tipo != null || _consulta.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _datos = context.read<PagoRepository>().cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    final nuevo = context.read<PagoRepository>().cargar();
    setState(() {
      _datos = nuevo;
    });
    try {
      await nuevo;
    } catch (_) {
      // El FutureBuilder ya muestra el error con su botón de reintento.
    }
  }

  void _limpiarFiltros() {
    _busquedaController.clear();
    setState(() {
      _consulta = '';
      _estado = null;
      _tipo = null;
    });
  }

  void _abrirPago(PagoConPersona item) {
    Navigator.of(context).push(
      rutaSuave<void>(PagoDetalleScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Text('Historial', style: AppTypography.titulo(size: 26)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<HistorialPagos>(
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
                      mensaje: 'No se pudo cargar el historial.',
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

  Widget _contenido(HistorialPagos historial) {
    if (historial.estaVacio) {
      return const EstadoVacio(
        icono: Icons.history_rounded,
        titulo: 'Aún no hay pagos',
        mensaje: 'Cuando se registren pagos aparecerán aquí.',
      );
    }

    final filtrados = historial.filtrar(
      estado: _estado,
      tipo: _tipo,
      consulta: _consulta,
    );
    final grupos = HistorialPagos.agrupar(filtrados);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: CampoBusqueda(
            controller: _busquedaController,
            sugerencia: 'Buscar por persona o transferencia',
            onChanged: (valor) {
              setState(() {
                _consulta = valor;
              });
            },
            onLimpiar: _limpiarFiltros,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
          child: _Filtros(
            estado: _estado,
            tipo: _tipo,
            onEstado: (e) {
              setState(() {
                _estado = e;
              });
            },
            onTipo: (t) {
              setState(() {
                _tipo = t;
              });
            },
          ),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? EstadoVacio(
                  icono: Icons.search_off_rounded,
                  titulo: 'Sin resultados',
                  mensaje: 'Prueba con otra búsqueda o quita algún filtro.',
                  textoAccion: _hayFiltros ? 'Quitar filtros' : null,
                  onAccion: _hayFiltros ? _limpiarFiltros : null,
                )
              : RefreshIndicator(
                  color: AppColors.azulNabame,
                  onRefresh: _recargar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _CifrasPagos(pagos: filtrados),
                      for (final grupo in grupos) ...[
                        _EncabezadoPeriodo(grupo: grupo),
                        for (final item in grupo.pagos)
                          _FilaPago(item: item, onTap: () => _abrirPago(item)),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Estado (excluyente) y tipo (se activa y se desactiva) en una sola fila.
class _Filtros extends StatelessWidget {
  final EstadoPago? estado;
  final TipoPago? tipo;
  final ValueChanged<EstadoPago?> onEstado;
  final ValueChanged<TipoPago?> onTipo;

  const _Filtros({
    required this.estado,
    required this.tipo,
    required this.onEstado,
    required this.onTipo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PildoraFiltro(
          texto: 'Todos',
          activa: estado == null,
          onTap: () => onEstado(null),
        ),
        const SizedBox(width: 8),
        PildoraFiltro(
          texto: 'Pagados',
          activa: estado == EstadoPago.pagado,
          onTap: () => onEstado(EstadoPago.pagado),
        ),
        const SizedBox(width: 8),
        PildoraFiltro(
          texto: 'Pendientes',
          activa: estado == EstadoPago.pendiente,
          onTap: () => onEstado(EstadoPago.pendiente),
        ),
        Container(
          width: 1,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: AppColors.borde,
        ),
        for (final t in TipoPago.values) ...[
          if (t != TipoPago.values.first) const SizedBox(width: 8),
          PildoraFiltro(
            texto: t.label,
            activa: tipo == t,
            onTap: () => onTipo(tipo == t ? null : t),
          ),
        ],
      ],
    );
  }
}

class _CifrasPagos extends StatelessWidget {
  final List<PagoConPersona> pagos;

  const _CifrasPagos({required this.pagos});

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: ColumnasCifras(
        cifras: [
          CifraResumen(
            valor: soles.format(HistorialPagos.pagadoDe(pagos)),
            etiqueta: EstadoPago.pagado.label,
            punto: EstadoPago.pagado.color,
          ),
          CifraResumen(
            valor: soles.format(HistorialPagos.pendienteDe(pagos)),
            etiqueta: EstadoPago.pendiente.label,
            punto: EstadoPago.pendiente.color,
          ),
        ],
      ),
    );
  }
}

class _EncabezadoPeriodo extends StatelessWidget {
  final GrupoPagos grupo;

  const _EncabezadoPeriodo({required this.grupo});

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              capitalizar(etiquetaMes(grupo.periodo)),
              style: AppTypography.titulo(
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.texto,
              ),
            ),
          ),
          Text(
            soles.format(grupo.total),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _FilaPago extends StatelessWidget {
  final PagoConPersona item;
  final VoidCallback onTap;

  const _FilaPago({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final pago = item.pago;
    final estado = pago.estado;
    final fechaPago = pago.fechaPago;
    final detalle = fechaPago == null
        ? pago.tipoPago.label
        : '${pago.tipoPago.label}  ·  ${fechaCorta(fechaPago)}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
                pago.tipoPago.icono,
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
                    item.persona?.nombreCorto ?? 'Persona no disponible',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detalle,
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
                  soles.format(pago.monto),
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
