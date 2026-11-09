import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/formato.dart';
import '../../data/repositories/avisos.dart';
import '../../data/repositories/venta_repository.dart';
import '../../models/perfil_administrador.dart';
import '../../models/usuario.dart';
import '../../theme/app_theme.dart';
import '../avisos/campana_avisos.dart';
import '../avisos/destino_aviso.dart';
import '../morosidad/morosidad_screen.dart';
import '../perfil/avatar_cuenta.dart';
import '../reportes/reporte_comision_screen.dart';
import '../shell/pestanas.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int indice)? onIrAPestana;

  const DashboardScreen({super.key, this.onIrAPestana});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum _VistaGrafico { mes, historico }

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DatosDashboard> _datosFuturos;
  _VistaGrafico _vista = _VistaGrafico.mes;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _datosFuturos = _cargarDatos();
  }

  Future<_DatosDashboard> _cargarDatos() async {
    final repo = context.read<VentaRepository>();
    final resultados = await Future.wait([
      repo.resumenDashboard(),
      repo.comisionMesAnterior(),
      repo.rankingVendedores(),
      repo.comisionPorMes(),
    ]);
    final datos = _DatosDashboard(
      resumen: resultados[0] as ResumenDashboard,
      comisionMesAnterior: resultados[1] as double,
      ranking: resultados[2] as List<RankingVendedor>,
      comisionPorMes: resultados[3] as Map<String, double>,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    return datos;
  }

  Future<void> _recargar() async {
    setState(() => _visible = false);
    final nuevo = _cargarDatos();
    setState(() {
      _datosFuturos = nuevo;
    });
    await nuevo;
  }

  void _irADestino(DestinoAviso destino) =>
      irADestinoAviso(context, destino, onIrAPestana: widget.onIrAPestana);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<_DatosDashboard>(
          future: _datosFuturos,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.azulNabame),
              );
            }
            if (snapshot.hasError) {
              return _ErrorCarga(onReintentar: _recargar);
            }

            final datos = snapshot.data!;
            return RefreshIndicator(
              color: AppColors.azulNabame,
              onRefresh: _recargar,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: _visible ? Offset.zero : const Offset(0, 0.03),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOut,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                    children: [
                      _Encabezado(
                        onVerPerfil: () => widget.onIrAPestana?.call(Pestanas.perfil),
                        onDestinoAviso: _irADestino,
                      ),
                      const SizedBox(height: 30),
                      _BloqueComision(datos: datos, vista: _vista),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: _Grafico(
                            key: ValueKey(_vista),
                            datos: datos,
                            vista: _vista,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 220,
                        child: _SelectorVista(
                          vista: _vista,
                          onCambiar: (v) => setState(() => _vista = v),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _AccionesRapidas(
                        onVentas: () => widget.onIrAPestana?.call(Pestanas.ventas),
                        onEquipo: () => widget.onIrAPestana?.call(Pestanas.equipo),
                        onMorosidad: () => MorosidadScreen.abrir(context),
                        onReportes: () => ReporteComisionScreen.abrir(context),
                        onMas: () => widget.onIrAPestana?.call(Pestanas.mas),
                      ),
                      const SizedBox(height: 34),
                      Text('Mejores vendedores',
                          style: AppTypography.titulo(size: 17)),
                      const SizedBox(height: 2),
                      const Text(
                        'Según comisión generada este mes',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 12),
                      if (datos.ranking.every((r) => r.totalVentas == 0))
                        const _SinVentasEsteMes()
                      else
                        ...datos.ranking
                            .take(5)
                            .map((r) => _FilaVendedor(ranking: r)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DatosDashboard {
  final ResumenDashboard resumen;
  final double comisionMesAnterior;
  final List<RankingVendedor> ranking;
  final Map<String, double> comisionPorMes;

  _DatosDashboard({
    required this.resumen,
    required this.comisionMesAnterior,
    required this.ranking,
    required this.comisionPorMes,
  });
}

class _Encabezado extends StatelessWidget {
  final VoidCallback onVerPerfil;
  final ValueChanged<DestinoAviso> onDestinoAviso;

  const _Encabezado({
    required this.onVerPerfil,
    required this.onDestinoAviso,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now());
    final fechaCapitalizada = fecha[0].toUpperCase() + fecha.substring(1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, ${PerfilAdministrador.nombre}',
                  style: AppTypography.titulo(size: 19)),
              const SizedBox(height: 2),
              Text(fechaCapitalizada,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textoSecundario)),
            ],
          ),
        ),
        CampanaAvisos(onDestino: onDestinoAviso),
        AvatarCuenta(onVerPerfil: onVerPerfil),
      ],
    );
  }
}

/// Número que cuenta desde 0 hasta su valor real al construirse, en vez
/// de aparecer de golpe.
class _NumeroAnimado extends StatelessWidget {
  final double valor;
  final String Function(double) formatear;
  final TextStyle? estilo;

  const _NumeroAnimado({
    required this.valor,
    required this.formatear,
    this.estilo,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(formatear(value), style: estilo),
    );
  }
}

class _BloqueComision extends StatelessWidget {
  final _DatosDashboard datos;
  final _VistaGrafico vista;

  const _BloqueComision({required this.datos, required this.vista});

  @override
  Widget build(BuildContext context) {
    const formato = FormatoSoles(); 

    final valorPrincipal = vista == _VistaGrafico.mes
        ? datos.resumen.comisionDelMes
        : datos.comisionPorMes.values.fold<double>(0, (a, b) => a + b);

    double? variacion;
    if (vista == _VistaGrafico.mes && datos.comisionMesAnterior > 0) {
      variacion = ((datos.resumen.comisionDelMes - datos.comisionMesAnterior) /
              datos.comisionMesAnterior) *
          100;
    }
    final esPositivo = (variacion ?? 0) >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COMISIÓN',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textoSecundario)),
        const SizedBox(height: 4),
        _NumeroAnimado(
          valor: valorPrincipal,
          formatear: (v) => formato.format(v),
          estilo: AppTypography.titulo(size: 36),
        ),
        const SizedBox(height: 8),
        if (variacion != null)
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (esPositivo ? AppColors.positivo : AppColors.negativo)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      esPositivo
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 13,
                      color: esPositivo
                          ? AppColors.positivo
                          : AppColors.negativo,
                    ),
                    Text(
                      '${variacion.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: esPositivo
                            ? AppColors.positivo
                            : AppColors.negativo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('vs. mes anterior',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textoSecundario)),
            ],
          )
        else
          const Text('Acumulado histórico',
              style:
                  TextStyle(fontSize: 12.5, color: AppColors.textoSecundario)),
      ],
    );
  }
}

class _Grafico extends StatelessWidget {
  final _DatosDashboard datos;
  final _VistaGrafico vista;

  const _Grafico({super.key, required this.datos, required this.vista});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots;
    if (vista == _VistaGrafico.mes) {
      spots = datos.resumen.comisionAcumuladaPorDia.entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList()
        ..sort((a, b) => a.x.compareTo(b.x));
    } else {
      final entradas = datos.comisionPorMes.entries.toList();
      spots = List.generate(
        entradas.length,
        (i) => FlSpot(i.toDouble(), entradas[i].value),
      );
    }

    if (spots.length < 2) {
      return const Center(
        child: Text(
          'Aún no hay suficientes datos para el gráfico.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textoSecundario),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.azulNabame,
            barWidth: 2.6,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.azulNabame.withValues(alpha: 0.16),
                  AppColors.azulNabame.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Control segmentado con un indicador que se desliza, en vez de dos
/// píldoras sueltas que solo cambian de color.
class _SelectorVista extends StatelessWidget {
  final _VistaGrafico vista;
  final ValueChanged<_VistaGrafico> onCambiar;

  const _SelectorVista({required this.vista, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: vista == _VistaGrafico.mes
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.marinoNabame,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _opcion('Este mes', _VistaGrafico.mes)),
              Expanded(child: _opcion('Histórico', _VistaGrafico.historico)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcion(String texto, _VistaGrafico valor) {
    final activo = vista == valor;
    return GestureDetector(
      onTap: () => onCambiar(valor),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: activo ? Colors.white : AppColors.textoSecundario,
          ),
        ),
      ),
    );
  }
}

class _AccionesRapidas extends StatelessWidget {
  final VoidCallback onVentas;
  final VoidCallback onEquipo;
  final VoidCallback onMorosidad;
  final VoidCallback onReportes;
  final VoidCallback onMas;

  const _AccionesRapidas({
    required this.onVentas,
    required this.onEquipo,
    required this.onMorosidad,
    required this.onReportes,
    required this.onMas,
  });

  @override
  Widget build(BuildContext context) {
    final acciones = [
      (Icons.receipt_long_outlined, 'Ventas', onVentas),
      (Icons.group_outlined, 'Equipo', onEquipo),
      (Icons.event_busy_outlined, 'Morosidad', onMorosidad),
      (Icons.insights_outlined, 'Reportes', onReportes),
      (Icons.apps_outlined, 'Más', onMas),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: acciones
          .map((a) => _BotonAccion(icono: a.$1, etiqueta: a.$2, onTap: a.$3))
          .toList(),
    );
  }
}

/// Botón de acceso rápido que se "hunde" levemente al presionarlo,
/// en vez de quedarse estático hasta que ocurre la navegación.
class _BotonAccion extends StatefulWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  @override
  State<_BotonAccion> createState() => _BotonAccionState();
}

class _BotonAccionState extends State<_BotonAccion> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _presionado = true),
      onTapUp: (_) => setState(() => _presionado = false),
      onTapCancel: () => setState(() => _presionado = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _presionado ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.azulNabame.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(widget.icono, color: AppColors.azulNabame, size: 21),
            ),
            const SizedBox(height: 7),
            Text(widget.etiqueta,
                style: const TextStyle(fontSize: 11, color: AppColors.texto)),
          ],
        ),
      ),
    );
  }
}

class _FilaVendedor extends StatelessWidget {
  final RankingVendedor ranking;
  const _FilaVendedor({required this.ranking});

  @override
  Widget build(BuildContext context) {
    final Usuario vendedor = ranking.vendedor;
    
    const formato = FormatoSoles(decimales: 0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.azulNabame.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(vendedor.iniciales,
                style: const TextStyle(
                    color: AppColors.azulNabame,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${vendedor.nombre} ${vendedor.apellidoPaterno}',
                    style:
                        const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text('${ranking.totalVentas} ventas',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textoSecundario)),
              ],
            ),
          ),
          Text(formato.format(ranking.comisionGenerada),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.positivo)),
        ],
      ),
    );
  }
}

class _SinVentasEsteMes extends StatelessWidget {
  const _SinVentasEsteMes();
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Todavía no hay ventas entregadas este mes para armar el ranking.',
      style: TextStyle(fontSize: 13, color: AppColors.textoSecundario),
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  final VoidCallback onReintentar;
  const _ErrorCarga({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.negativo, size: 36),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el dashboard.',
                style: TextStyle(fontSize: 14, color: AppColors.textoSecundario)),
            const SizedBox(height: 16),
            TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}