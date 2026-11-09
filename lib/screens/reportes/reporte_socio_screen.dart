import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/arbol_equipo.dart';
import '../../data/repositories/reporte_comision.dart';
import '../../models/usuario_jerarquia.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/texto.dart';
import '../../utils/transiciones.dart';
import '../equipo/avatar_persona.dart';
import '../equipo/persona_detalle_screen.dart';
import '../morosidad/columnas_cifras.dart';

/// Comisión generada por la cadena de un Socio Comercial, con el desglose
/// por supervisor y vendedor y un botón para copiar el resumen.
class ReporteSocioScreen extends StatelessWidget {
  final ReporteComision reporte;
  final NodoEquipo socio;

  const ReporteSocioScreen({
    super.key,
    required this.reporte,
    required this.socio,
  });

  void _abrirPersona(BuildContext context, NodoEquipo nodo) {
    Navigator.of(context).push(
      rutaSuave<void>(PersonaDetalleScreen(nodo: nodo, mes: reporte.mes)),
    );
  }

  Future<void> _copiar(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: reporte.resumenDe(socio)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resumen copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final supervisores = socio.miembros.where((m) => m.persona.esSupervisor);
    final directos = socio.miembros.where((m) => !m.persona.esSupervisor);

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
                    capitalizar(etiquetaMes(reporte.mes)),
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
                  AvatarPersona(persona: socio.persona, tamano: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          socio.persona.nombreCorto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titulo(size: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          socio.persona.tipoTrabajador.label,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comisión generada',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textoSecundario),
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: socio.comisionMes),
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
                  valor: '${socio.ventasEntregadas}',
                  etiqueta: 'Ventas entregadas',
                ),
                CifraResumen(
                  valor: '${supervisores.length}',
                  etiqueta: 'Supervisores',
                ),
                CifraResumen(
                  valor: '${socio.personasACargo}',
                  etiqueta: 'A cargo',
                ),
              ],
            ),
            const _Encabezado(),
            for (final supervisor in supervisores)
              _BloqueSupervisor(
                nodo: supervisor,
                onAbrir: (n) => _abrirPersona(context, n),
              ),
            for (final nodo in directos.where((n) => n.ventasEntregadas > 0))
              _FilaMiembro(
                nodo: nodo,
                tamano: 38,
                izquierda: 22,
                onTap: () => _abrirPersona(context, nodo),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _copiar(context),
                  icon: const Icon(Icons.content_copy_outlined, size: 18),
                  label: const Text('Copiar resumen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.marinoNabame,
                    side: const BorderSide(
                        color: AppColors.marinoNabame, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 10, 22, 0),
              child: Text(
                'Es la comisión que generan las ventas entregadas de su equipo. '
                'El reparto entre sus integrantes lo define el Socio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textoSecundario),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Desglose del equipo',
              style: AppTypography.titulo(
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.texto,
              ),
            ),
          ),
          const Text(
            'Comisión generada',
            style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}

/// Un supervisor y, debajo, sus vendedores con ventas, unidos por la línea
/// lateral que nace bajo el avatar.
class _BloqueSupervisor extends StatelessWidget {
  final NodoEquipo nodo;
  final ValueChanged<NodoEquipo> onAbrir;

  const _BloqueSupervisor({required this.nodo, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final vendedores = nodo.miembros
        .where((m) => m.ventasEntregadas > 0 || m.persona.activo)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilaMiembro(
          nodo: nodo,
          tamano: 38,
          izquierda: 22,
          destacada: true,
          onTap: () => onAbrir(nodo),
        ),
        if (vendedores.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 22 + 19),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.borde, width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  for (final vendedor in vendedores)
                    _FilaMiembro(
                      nodo: vendedor,
                      tamano: 30,
                      izquierda: 14,
                      onTap: () => onAbrir(vendedor),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FilaMiembro extends StatelessWidget {
  final NodoEquipo nodo;
  final double tamano;
  final double izquierda;
  final bool destacada;
  final VoidCallback onTap;

  const _FilaMiembro({
    required this.nodo,
    required this.tamano,
    required this.izquierda,
    required this.onTap,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final persona = nodo.persona;
    final ventas = cantidadDe(nodo.ventasEntregadas, 'venta', 'ventas');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(izquierda, 10, 22, 10),
        child: Row(
          children: [
            AvatarPersona(persona: persona, tamano: tamano),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.nombreCorto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: destacada ? 14.5 : 13.5,
                      fontWeight:
                          destacada ? FontWeight.w700 : FontWeight.w500,
                      color: persona.activo
                          ? AppColors.texto
                          : AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destacada
                        ? '${persona.tipoTrabajador.label}  ·  $ventas'
                        : ventas,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              soles.format(nodo.comisionMes),
              style: TextStyle(
                fontSize: destacada ? 14 : 13.5,
                fontWeight: destacada ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
