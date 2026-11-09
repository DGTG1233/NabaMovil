import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/avisos.dart';
import '../../theme/app_theme.dart';
import '../../widgets/estados_vista.dart';
import 'aviso_visual.dart';
import 'avisos_controller.dart';

/// Ventana inferior con la lista de avisos. Al tocar uno se marca como
/// leído y la ventana se cierra devolviendo la pantalla a la que lleva.
class HojaAvisos extends StatelessWidget {
  final Future<List<Aviso>> avisos;

  const HojaAvisos({super.key, required this.avisos});

  static Future<DestinoAviso?> mostrar(
    BuildContext context,
    Future<List<Aviso>> avisos,
  ) {
    return showModalBottomSheet<DestinoAviso>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      builder: (_) => HojaAvisos(avisos: avisos),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Aviso>>(
      future: avisos,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 56),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.azulNabame),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: EstadoVacio(
              icono: Icons.error_outline_rounded,
              titulo: 'No se pudieron cargar',
              mensaje: 'Cierra esta ventana y vuelve a intentarlo.',
            ),
          );
        }
        return _Contenido(avisos: snapshot.data!);
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  final List<Aviso> avisos;

  const _Contenido({required this.avisos});

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<AvisosController>();
    final sinLeer = controlador.noLeidos(avisos);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notificaciones',
                        style: AppTypography.titulo(size: 20)),
                    const SizedBox(height: 2),
                    Text(
                      sinLeer == 0
                          ? 'Todo al día'
                          : sinLeer == 1
                              ? '1 sin leer'
                              : '$sinLeer sin leer',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textoSecundario),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: sinLeer == 0
                    ? null
                    : () => controlador.marcarTodos(avisos),
                child: const Text('Marcar todas'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.borde),
        if (avisos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: EstadoVacio(
              icono: Icons.notifications_none_rounded,
              titulo: 'Todo al día',
              mensaje: 'No hay avisos pendientes por ahora.',
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: avisos.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borde,
                indent: 22,
                endIndent: 22,
              ),
              itemBuilder: (context, i) {
                final aviso = avisos[i];
                return _FilaAviso(
                  aviso: aviso,
                  leido: controlador.estaLeido(aviso.id),
                  onTap: () {
                    controlador.marcarLeido(aviso.id);
                    Navigator.of(context).pop(aviso.destino);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FilaAviso extends StatelessWidget {
  final Aviso aviso;
  final bool leido;
  final VoidCallback onTap;

  const _FilaAviso({
    required this.aviso,
    required this.leido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: aviso.tipo.color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(aviso.tipo.icono, size: 21, color: aviso.tipo.colorIcono),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aviso.titulo,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: leido ? FontWeight.w500 : FontWeight.w700,
                      color: leido ? AppColors.textoSecundario : AppColors.texto,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    aviso.detalle,
                    style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 6),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: leido ? Colors.transparent : AppColors.azulNabame,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

