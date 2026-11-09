import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/venta_repository.dart';
import '../../models/venta_estado.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/transiciones.dart';
import '../../widgets/campo_busqueda.dart';
import '../../widgets/estados_vista.dart';
import 'estado_visual.dart';
import 'fila_venta.dart';
import 'venta_detalle_screen.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  late Future<List<VentaConVendedor>> _datos;
  final _busquedaController = TextEditingController();

  String _consulta = '';
  VentaEstado? _estado;
  String? _mes;
  bool _masRecientesPrimero = true;

  bool get _hayFiltros =>
      _consulta.isNotEmpty || _estado != null || _mes != null;

  @override
  void initState() {
    super.initState();
    _datos = context.read<VentaRepository>().ventasConVendedor();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    final nuevo = context.read<VentaRepository>().ventasConVendedor();
    setState(() {
      _datos = nuevo;
    });
    await nuevo;
  }

  void _limpiarBusqueda() {
    _busquedaController.clear();
    setState(() => _consulta = '');
  }

  void _limpiarFiltros() {
    _busquedaController.clear();
    setState(() {
      _consulta = '';
      _estado = null;
      _mes = null;
    });
  }

  Future<void> _elegirEstado(List<VentaConVendedor> todas) async {
    final conteo = <VentaEstado, int>{};
    for (final item in todas) {
      conteo[item.venta.estado] = (conteo[item.venta.estado] ?? 0) + 1;
    }
    final estados = conteo.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final eleccion = await showModalBottomSheet<_Seleccion<VentaEstado>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _HojaOpciones<VentaEstado>(
        titulo: 'Filtrar por estado',
        seleccionado: _estado,
        opciones: [
          for (final e in estados)
            _OpcionHoja<VentaEstado>(
              valor: e,
              texto: e.label,
              detalle: '${conteo[e]}',
              inicio: _PuntoColor(e.color),
            ),
        ],
      ),
    );

    if (eleccion == null || !mounted) return;
    setState(() => _estado = eleccion.valor);
  }

  Future<void> _elegirMes(List<VentaConVendedor> todas) async {
    final conteo = <String, int>{};
    for (final item in todas) {
      conteo[item.venta.mes] = (conteo[item.venta.mes] ?? 0) + 1;
    }
    final meses = conteo.keys.toList()..sort((a, b) => b.compareTo(a));

    final eleccion = await showModalBottomSheet<_Seleccion<String>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _HojaOpciones<String>(
        titulo: 'Filtrar por mes',
        seleccionado: _mes,
        opciones: [
          for (final m in meses)
            _OpcionHoja<String>(
              valor: m,
              texto: etiquetaMes(m),
              detalle: '${conteo[m]}',
            ),
        ],
      ),
    );

    if (eleccion == null || !mounted) return;
    setState(() => _mes = eleccion.valor);
  }

  void _abrirDetalle(VentaConVendedor item) {
    Navigator.of(context).push(
      rutaSuave<void>(VentaDetalleScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<VentaConVendedor>>(
          future: _datos,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.azulNabame),
              );
            }
            if (snapshot.hasError) {
              return EstadoError(
                mensaje: 'No se pudieron cargar las ventas.',
                onReintentar: _recargar,
              );
            }

            final todas = snapshot.data!;
            final filtradas = VentaRepository.filtrar(
              todas,
              consulta: _consulta,
              estado: _estado,
              mes: _mes,
              masRecientesPrimero: _masRecientesPrimero,
            );
            final items = _agruparPorMes(filtradas);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                  child: Text('Ventas', style: AppTypography.titulo(size: 26)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: CampoBusqueda(
                    controller: _busquedaController,
                    sugerencia: 'Buscar por cliente, DNI o vendedor',
                    onChanged: (valor) => setState(() => _consulta = valor),
                    onLimpiar: _limpiarBusqueda,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    children: [
                      _Pastilla(
                        texto: _masRecientesPrimero
                            ? 'Más recientes primero'
                            : 'Más antiguas primero',
                        icono: Icons.swap_vert_rounded,
                        oscura: true,
                        onTap: () => setState(
                          () => _masRecientesPrimero = !_masRecientesPrimero,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Pastilla(
                        texto: _estado?.label ?? 'Estado',
                        punto: _estado?.color,
                        activa: _estado != null,
                        onTap: () => _elegirEstado(todas),
                        onLimpiar: () => setState(() => _estado = null),
                      ),
                      const SizedBox(width: 10),
                      _Pastilla(
                        texto: _mes != null ? etiquetaMes(_mes!) : 'Mes',
                        activa: _mes != null,
                        onTap: () => _elegirMes(todas),
                        onLimpiar: () => setState(() => _mes = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: filtradas.isEmpty
                      ? EstadoVacio(
                          icono: Icons.search_off_rounded,
                          titulo: _hayFiltros
                              ? 'Sin resultados'
                              : 'Aún no hay ventas',
                          mensaje: _hayFiltros
                              ? 'Prueba con otra búsqueda o quita algún filtro.'
                              : 'Cuando haya ventas cargadas aparecerán aquí.',
                          textoAccion: _hayFiltros ? 'Quitar filtros' : null,
                          onAccion: _hayFiltros ? _limpiarFiltros : null,
                        )
                      : RefreshIndicator(
                          color: AppColors.azulNabame,
                          onRefresh: _recargar,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final item = items[i];
                              if (item is _EncabezadoMes) {
                                return _EncabezadoMesFila(
                                  etiqueta: item.etiqueta,
                                  cantidad: item.cantidad,
                                );
                              }
                              final fila = item as VentaConVendedor;
                              return FilaVenta(
                                item: fila,
                                onTap: () => _abrirDetalle(fila),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EncabezadoMes {
  final String etiqueta;
  final int cantidad;
  const _EncabezadoMes(this.etiqueta, this.cantidad);
}

/// Intercala un encabezado cada vez que cambia el mes.
List<Object> _agruparPorMes(List<VentaConVendedor> ventas) {
  final items = <Object>[];
  String? mesActual;
  for (final item in ventas) {
    final mes = item.venta.mes;
    if (mes != mesActual) {
      mesActual = mes;
      final cantidad = ventas.where((e) => e.venta.mes == mes).length;
      items.add(_EncabezadoMes(etiquetaMes(mes), cantidad));
    }
    items.add(item);
  }
  return items;
}

class _Pastilla extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final Color? punto;
  final bool oscura;
  final bool activa;
  final VoidCallback onTap;
  final VoidCallback? onLimpiar;

  const _Pastilla({
    required this.texto,
    required this.onTap,
    this.icono,
    this.punto,
    this.oscura = false,
    this.activa = false,
    this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    final fondo = oscura
        ? AppColors.marinoNabame
        : (activa
            ? AppColors.azulNabame.withValues(alpha: 0.10)
            : AppColors.superficie);
    final colorTexto = oscura
        ? Colors.white
        : (activa ? AppColors.azulNabame : AppColors.texto);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (punto != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: punto, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorTexto,
              ),
            ),
            const SizedBox(width: 6),
            if (activa && onLimpiar != null)
              GestureDetector(
                onTap: onLimpiar,
                child: Icon(Icons.close_rounded, size: 16, color: colorTexto),
              )
            else
              Icon(
                icono ?? Icons.keyboard_arrow_down_rounded,
                size: icono == null ? 18 : 16,
                color: colorTexto,
              ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoMesFila extends StatelessWidget {
  final String etiqueta;
  final int cantidad;

  const _EncabezadoMesFila({required this.etiqueta, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: AppTypography.titulo(
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.texto,
              ),
            ),
          ),
          Text(
            cantidadDe(cantidad, 'venta', 'ventas'),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}

// Hoja inferior de opciones

class _Seleccion<T> {
  final T? valor;
  const _Seleccion(this.valor);
}

class _OpcionHoja<T> {
  final T? valor;
  final String texto;
  final String? detalle;
  final Widget? inicio;

  const _OpcionHoja({
    required this.valor,
    required this.texto,
    this.detalle,
    this.inicio,
  });
}

class _HojaOpciones<T> extends StatelessWidget {
  final String titulo;
  final T? seleccionado;
  final List<_OpcionHoja<T>> opciones;

  const _HojaOpciones({
    required this.titulo,
    required this.seleccionado,
    required this.opciones,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borde,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Text(titulo, style: AppTypography.titulo(size: 18)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  _FilaHoja(
                    texto: 'Todos',
                    activa: seleccionado == null,
                    onTap: () => Navigator.of(context).pop(_Seleccion<T>(null)),
                  ),
                  for (final o in opciones)
                    _FilaHoja(
                      texto: o.texto,
                      detalle: o.detalle,
                      inicio: o.inicio,
                      activa: seleccionado == o.valor,
                      onTap: () =>
                          Navigator.of(context).pop(_Seleccion<T>(o.valor)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaHoja extends StatelessWidget {
  final String texto;
  final String? detalle;
  final Widget? inicio;
  final bool activa;
  final VoidCallback onTap;

  const _FilaHoja({
    required this.texto,
    required this.activa,
    required this.onTap,
    this.detalle,
    this.inicio,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          children: [
            if (inicio != null) ?inicio,
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (detalle != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  detalle!,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textoSecundario),
                ),
              ),
            if (activa)
              const Icon(Icons.check_rounded,
                  size: 20, color: AppColors.azulNabame),
          ],
        ),
      ),
    );
  }
}

class _PuntoColor extends StatelessWidget {
  final Color color;
  const _PuntoColor(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
