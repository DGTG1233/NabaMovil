import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../equipo/equipo_screen.dart';
import '../historial/historial_screen.dart';
import '../mas/mas_screen.dart';
import '../perfil/avatar_administrador.dart';
import '../perfil/perfil_screen.dart';
import '../ventas/ventas_screen.dart';
import 'pestanas.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indiceActivo = 0;

  List<Widget> get _pantallas {
    void irA(int indice) => setState(() => _indiceActivo = indice);

    return [
      DashboardScreen(onIrAPestana: irA),
      const VentasScreen(),
      const EquipoScreen(),
      const HistorialScreen(),
      MasScreen(onIrAPestana: irA),
      const PerfilScreen(),
    ];
  }

  static const _iconos = [
    Icons.space_dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.groups_outlined,
    Icons.history_outlined,
    Icons.widgets_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indiceActivo, children: _pantallas),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borde, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(Pestanas.perfil + 1, (indice) {
                final activo = indice == _indiceActivo;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _indiceActivo = indice),
                    child: Center(
                      child: indice == Pestanas.perfil
                          ? _ItemPerfil(activo: activo)
                          : _ItemIcono(icono: _iconos[indice], activo: activo),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemIcono extends StatelessWidget {
  final IconData icono;
  final bool activo;

  const _ItemIcono({required this.icono, required this.activo});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 34,
      decoration: BoxDecoration(
        color: activo
            ? AppColors.azulNabame.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(
        icono,
        color: activo ? AppColors.azulNabame : AppColors.textoSecundario,
        size: 23,
      ),
    );
  }
}

/// Avatar del Administrador como último botón de la barra. Al estar activo
/// se rodea de un aro azul; en reposo el aro es transparente para que no se
/// mueva nada al cambiar.
class _ItemPerfil extends StatelessWidget {
  final bool activo;

  const _ItemPerfil({required this.activo});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: activo ? AppColors.azulNabame : Colors.transparent,
          width: 2,
        ),
      ),
      child: const AvatarAdministrador(tamano: 26),
    );
  }
}
