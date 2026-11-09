import 'package:flutter/material.dart';

import '../../models/perfil_administrador.dart';
import '../../theme/app_theme.dart';
import '../../theme/paleta_estado.dart';
import '../../widgets/fila_dato.dart';
import 'avatar_administrador.dart';
import 'cerrar_sesion.dart';

/// Pestaña de perfil: los datos de cuenta del Administrador y lo que puede
/// hacer en la aplicación.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Text('Perfil', style: AppTypography.titulo(size: 26)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
              child: Row(
                children: [
                  const AvatarAdministrador(tamano: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PerfilAdministrador.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titulo(size: 22),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          PerfilAdministrador.correo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const _Titulo('Cuenta'),
            const Divider(height: 1, thickness: 1, color: AppColors.borde),
            const FilaDato(
              etiqueta: 'Nombre',
              valor: PerfilAdministrador.nombre,
            ),
            const FilaDato(
              etiqueta: 'Correo',
              valor: PerfilAdministrador.correo,
            ),
            const FilaDato(etiqueta: 'Rol', valor: PerfilAdministrador.rol),
            const _Titulo('Acceso'),
            const Divider(height: 1, thickness: 1, color: AppColors.borde),
            const FilaDato(
              etiqueta: 'Permisos',
              valor: PerfilAdministrador.acceso,
            ),
            const FilaDato(
              etiqueta: 'Módulos',
              valor: PerfilAdministrador.modulos,
            ),
            const FilaDato(etiqueta: 'Datos', valor: 'Simulados'),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 0),
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => confirmarCerrarSesion(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PaletaEstado.rojo,
                    side: const BorderSide(color: PaletaEstado.rojo, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 8),
      child: Text(
        texto,
        style: AppTypography.titulo(
          size: 15,
          weight: FontWeight.w700,
          color: AppColors.texto,
        ),
      ),
    );
  }
}
