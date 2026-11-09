import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/arbol_equipo.dart';
import '../../data/repositories/venta_repository.dart';
import '../../models/usuario_jerarquia.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/transiciones.dart';
import '../../widgets/estados_vista.dart';
import '../ventas/fila_venta.dart';
import '../ventas/venta_detalle_screen.dart';
import 'avatar_persona.dart';
import 'barra_rendimiento.dart';

/// Detalle de una persona del equipo: totales del mes, cuota, datos y sus
/// ventas. Para un Supervisor o un Socio Comercial las ventas son las de
/// todo su equipo.
class PersonaDetalleScreen extends StatefulWidget {
  final NodoEquipo nodo;
  final String mes;

  const PersonaDetalleScreen({
    super.key,
    required this.nodo,
    required this.mes,
  });

  @override
  State<PersonaDetalleScreen> createState() => _PersonaDetalleScreenState();
}

class _PersonaDetalleScreenState extends State<PersonaDetalleScreen> {
  late Future<List<VentaConVendedor>> _ventas;

  @override
  void initState() {
    super.initState();
    _ventas = _cargar();
  }

  Future<List<VentaConVendedor>> _cargar() {
    return context
        .read<VentaRepository>()
        .ventasDelEquipo(widget.nodo, mes: widget.mes);
  }

  void _reintentar() {
    setState(() {
      _ventas = _cargar();
    });
  }

  void _abrirVenta(VentaConVendedor item) {
    Navigator.of(context).push(
      rutaSuave<void>(VentaDetalleScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodo = widget.nodo;
    final persona = nodo.persona;

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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _Cabecera(nodo: nodo),
                  _Totales(nodo: nodo),
                  if (nodo.rendimiento != null)
                    _Cuota(nodo: nodo, mes: widget.mes),
                  _Datos(nodo: nodo),
                  _TituloSeccion(
                    titulo: 'Ventas de ${etiquetaMes(widget.mes)}',
                    nota: persona.puedeTenerEquipo
                        ? 'Incluye a todo su equipo.'
                        : null,
                  ),
                  FutureBuilder<List<VentaConVendedor>>(
                    future: _ventas,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.azulNabame,
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return EstadoError(
                          mensaje: 'No se pudieron cargar las ventas.',
                          onReintentar: _reintentar,
                        );
                      }
                      final ventas = snapshot.data!;
                      if (ventas.isEmpty) {
                        return EstadoVacio(
                          icono: Icons.receipt_long_outlined,
                          titulo: 'Sin ventas este mes',
                          mensaje: persona.puedeTenerEquipo
                              ? 'Su equipo no registró ventas en ${etiquetaMes(widget.mes)}.'
                              : 'No registró ventas en ${etiquetaMes(widget.mes)}.',
                        );
                      }
                      return Column(
                        children: [
                          for (final item in ventas)
                            FilaVenta(
                              item: item,
                              mostrarVendedor: persona.puedeTenerEquipo,
                              onTap: () => _abrirVenta(item),
                            ),
                        ],
                      );
                    },
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

class _Cabecera extends StatelessWidget {
  final NodoEquipo nodo;

  const _Cabecera({required this.nodo});

  @override
  Widget build(BuildContext context) {
    final persona = nodo.persona;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: Row(
        children: [
          AvatarPersona(persona: persona, tamano: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  persona.nombreCorto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titulo(size: 22),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      persona.tipoTrabajador.label,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textoSecundario),
                    ),
                    if (!persona.activo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.superficie,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Inactivo',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Totales extends StatelessWidget {
  final NodoEquipo nodo;

  const _Totales({required this.nodo});

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final conEquipo = nodo.persona.puedeTenerEquipo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Total(
              valor: '${nodo.ventasEntregadas}',
              etiqueta: 'Ventas entregadas',
            ),
            const _DivisorVertical(),
            _Total(
              valor: soles.format(nodo.comisionMes),
              etiqueta: 'Comisión generada',
              conMargen: true,
            ),
            if (conEquipo) ...[
              const _DivisorVertical(),
              _Total(
                valor: '${nodo.personasACargo}',
                etiqueta: 'A cargo',
                conMargen: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final bool conMargen;

  const _Total({
    required this.valor,
    required this.etiqueta,
    this.conMargen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: conMargen ? 16 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: AppTypography.titulo(size: 20)),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

class _DivisorVertical extends StatelessWidget {
  const _DivisorVertical();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      child: ColoredBox(color: AppColors.borde),
    );
  }
}

class _Cuota extends StatelessWidget {
  final NodoEquipo nodo;
  final String mes;

  const _Cuota({required this.nodo, required this.mes});

  String _formatoCuota(double valor) =>
      valor.toStringAsFixed(valor % 1 == 0 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final rendimiento = nodo.rendimiento!;
    final cuota = nodo.cuotaMes!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cuota de ${etiquetaMes(mes)}',
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${nodo.ventasParaCuota} de ${_formatoCuota(cuota)} ventas',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textoSecundario),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BarraRendimiento(proporcion: rendimiento, altura: 6),
              ),
              const SizedBox(width: 10),
              Text(
                '${(rendimiento * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: rendimiento >= 1
                      ? AppColors.positivo
                      : AppColors.texto,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Datos extends StatelessWidget {
  final NodoEquipo nodo;

  const _Datos({required this.nodo});

  @override
  Widget build(BuildContext context) {
    final persona = nodo.persona;
    final filas = <(String, String)>[
      ('Correo', persona.email),
      if (!persona.esSocioComercial)
        ('Reporta a', nodo.superior?.nombreCorto ?? 'Sin superior asignado'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TituloSeccion(titulo: 'Datos'),
        for (final (etiqueta, valor) in filas)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    etiqueta,
                    style: const TextStyle(
                        fontSize: 13.5, color: AppColors.textoSecundario),
                  ),
                ),
                Expanded(
                  child: Text(
                    valor,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String titulo;
  final String? nota;

  const _TituloSeccion({required this.titulo, this.nota});

  @override
  Widget build(BuildContext context) {
    final texto = nota;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: AppTypography.titulo(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.texto,
            ),
          ),
          if (texto != null) ...[
            const SizedBox(height: 2),
            Text(
              texto,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}
