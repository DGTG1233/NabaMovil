import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/avisos.dart';
import '../../data/repositories/notificaciones_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/paleta_estado.dart';
import '../avisos/avisos_controller.dart';
import '../avisos/destino_aviso.dart';
import '../avisos/hoja_avisos.dart';
import '../morosidad/morosidad_screen.dart';
import '../reportes/reporte_comision_screen.dart';

/// Pestaña "Más": los módulos que no tienen un lugar en la barra inferior.
class MasScreen extends StatefulWidget {
  final ValueChanged<int> onIrAPestana;

  const MasScreen({super.key, required this.onIrAPestana});

  @override
  State<MasScreen> createState() => _MasScreenState();
}

class _MasScreenState extends State<MasScreen> {
  late final Future<List<Aviso>> _avisos;

  @override
  void initState() {
    super.initState();
    _avisos = context.read<NotificacionesRepository>().cargar();
  }

  Future<void> _abrirAvisos() async {
    final destino = await HojaAvisos.mostrar(context, _avisos);
    if (destino != null && mounted) {
      irADestinoAviso(context, destino, onIrAPestana: widget.onIrAPestana);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Text('Más', style: AppTypography.titulo(size: 26)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 4, 22, 16),
              child: Text(
                'Módulos que no están en la barra',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textoSecundario),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.borde),
            _FilaModulo(
              icono: Icons.event_busy_outlined,
              titulo: 'Morosidad',
              descripcion: 'Casos por mes de alta y su cierre de penalización',
              onTap: () => MorosidadScreen.abrir(context),
            ),
            _FilaModulo(
              icono: Icons.insights_outlined,
              titulo: 'Reportes',
              descripcion: 'Comisión generada por Socio Comercial',
              onTap: () => ReporteComisionScreen.abrir(context),
            ),
            _FilaModulo(
              icono: Icons.notifications_none_rounded,
              titulo: 'Notificaciones',
              descripcion: 'Cierres, pagos pendientes y ventas por revisar',
              onTap: _abrirAvisos,
              detalle: _ContadorAvisos(avisos: _avisos),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avisos sin leer, o una flecha si ya se leyeron todos.
class _ContadorAvisos extends StatelessWidget {
  final Future<List<Aviso>> avisos;

  const _ContadorAvisos({required this.avisos});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Aviso>>(
      future: avisos,
      builder: (context, snapshot) {
        final lista = snapshot.data ?? const <Aviso>[];
        final sinLeer = context.watch<AvisosController>().noLeidos(lista);
        if (sinLeer == 0) return const _Flecha();

        return Container(
          constraints: const BoxConstraints(minWidth: 22),
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PaletaEstado.rojo,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            '$sinLeer',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        );
      },
    );
  }
}

class _Flecha extends StatelessWidget {
  const _Flecha();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_right_rounded,
      size: 22,
      color: AppColors.textoSecundario,
    );
  }
}

class _FilaModulo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;
  final Widget detalle;

  const _FilaModulo({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
    this.detalle = const _Flecha(),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.azulNabame.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, size: 23, color: AppColors.azulNabame),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: AppTypography.titulo(
                          size: 15.5,
                          weight: FontWeight.w700,
                          color: AppColors.texto,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        descripcion,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                detalle,
              ],
            ),
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.borde,
          indent: 22,
          endIndent: 22,
        ),
      ],
    );
  }
}
