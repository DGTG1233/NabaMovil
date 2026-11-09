import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/paleta_estado.dart';
import '../../utils/transiciones.dart';
import '../login/login_screen.dart';

/// Pide confirmación y, si se acepta, cierra la sesión y vuelve al Login
/// quitando todas las pantallas anteriores, para que el botón Atrás no
/// regrese a la aplicación. El correo recordado se conserva.
Future<void> confirmarCerrarSesion(BuildContext context) async {
  final auth = context.read<AuthService>();

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (_) => const _DialogoCerrarSesion(),
  );
  if (confirmado != true || !context.mounted) return;

  await auth.cerrarSesion();
  if (!context.mounted) return;

  await Navigator.of(context).pushAndRemoveUntil<void>(
    rutaSuave<void>(const LoginScreen()),
    (_) => false,
  );
}

class _DialogoCerrarSesion extends StatelessWidget {
  const _DialogoCerrarSesion();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        '¿Cerrar sesión?',
        style: AppTypography.titulo(
          size: 18,
          weight: FontWeight.w700,
          color: AppColors.texto,
        ),
      ),
      content: const Text(
        'Volverás a la pantalla de acceso y tendrás que ingresar tu '
        'contraseña para entrar de nuevo.',
        style: TextStyle(
          fontSize: 13.5,
          height: 1.4,
          color: AppColors.textoSecundario,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textoSecundario),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Cerrar sesión',
            style: TextStyle(
              color: PaletaEstado.rojo,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
