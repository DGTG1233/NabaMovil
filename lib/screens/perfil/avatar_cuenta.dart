import 'package:flutter/material.dart';

import '../../models/perfil_administrador.dart';
import '../../theme/app_theme.dart';
import '../../theme/paleta_estado.dart';
import 'avatar_administrador.dart';
import 'cerrar_sesion.dart';

enum _Accion { perfil, cerrarSesion }

/// Avatar del encabezado. Al tocarlo abre un menú pequeño bajo el círculo,
/// con los datos de la cuenta, el acceso a la pestaña de perfil y el cierre
/// de sesión.
class AvatarCuenta extends StatelessWidget {
  /// Se llama cuando la persona elige "Ver perfil".
  final VoidCallback onVerPerfil;

  const AvatarCuenta({super.key, required this.onVerPerfil});

  Future<void> _abrirMenu(BuildContext context) async {
    final boton = context.findRenderObject()! as RenderBox;
    final capa =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;

    // Rectángulo sin altura justo debajo del botón: el menú se alinea a su
    // borde derecho porque el avatar está pegado a ese lado.
    final debajo = boton.size.height + 4;
    final posicion = RelativeRect.fromRect(
      Rect.fromPoints(
        boton.localToGlobal(Offset(0, debajo), ancestor: capa),
        boton.localToGlobal(Offset(boton.size.width, debajo), ancestor: capa),
      ),
      Offset.zero & capa.size,
    );

    final accion = await showMenu<_Accion>(
      context: context,
      position: posicion,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(minWidth: 240),
      items: [
        const PopupMenuItem<_Accion>(
          enabled: false,
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _CabeceraMenu(),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<_Accion>(
          value: _Accion.perfil,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 20, color: AppColors.marinoNabame),
              SizedBox(width: 12),
              Text(
                'Ver perfil',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.texto,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<_Accion>(
          value: _Accion.cerrarSesion,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: PaletaEstado.rojo),
              SizedBox(width: 12),
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PaletaEstado.rojo,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted) return;
    switch (accion) {
      case _Accion.perfil:
        onVerPerfil();
      case _Accion.cerrarSesion:
        confirmarCerrarSesion(context);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cuenta',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _abrirMenu(context),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: AvatarAdministrador(),
        ),
      ),
    );
  }
}

class _CabeceraMenu extends StatelessWidget {
  const _CabeceraMenu();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AvatarAdministrador(tamano: 36),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                PerfilAdministrador.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texto,
                ),
              ),
              SizedBox(height: 2),
              Text(
                PerfilAdministrador.correo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
