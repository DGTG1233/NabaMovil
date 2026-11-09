import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/avisos.dart';
import '../../data/repositories/notificaciones_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/paleta_estado.dart';
import 'avisos_controller.dart';
import 'hoja_avisos.dart';

/// Campana del encabezado: muestra cuántos avisos faltan por leer y abre la
/// lista en una ventana inferior. Si el aviso elegido lleva a otra pantalla,
/// lo informa en `onDestino`.
class CampanaAvisos extends StatefulWidget {
  final ValueChanged<DestinoAviso> onDestino;

  const CampanaAvisos({super.key, required this.onDestino});

  @override
  State<CampanaAvisos> createState() => _CampanaAvisosState();
}

class _CampanaAvisosState extends State<CampanaAvisos> {
  late final Future<List<Aviso>> _avisos;

  @override
  void initState() {
    super.initState();
    _avisos = context.read<NotificacionesRepository>().cargar();
  }

  Future<void> _abrir() async {
    final destino = await HojaAvisos.mostrar(context, _avisos);
    if (destino != null && mounted) widget.onDestino(destino);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Aviso>>(
      future: _avisos,
      builder: (context, snapshot) {
        final avisos = snapshot.data ?? const <Aviso>[];
        final sinLeer = context.watch<AvisosController>().noLeidos(avisos);

        return Semantics(
          button: true,
          label: sinLeer == 0
              ? 'Notificaciones'
              : 'Notificaciones, $sinLeer sin leer',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _abrir,
            child: SizedBox(
              width: 44,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 25,
                    color: AppColors.marinoNabame,
                  ),
                  if (sinLeer > 0)
                    Positioned(top: 7, right: 4, child: _Insignia(sinLeer)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Insignia extends StatelessWidget {
  final int cantidad;

  const _Insignia(this.cantidad);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 17),
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PaletaEstado.rojo,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        cantidad > 9 ? '9+' : '$cantidad',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
