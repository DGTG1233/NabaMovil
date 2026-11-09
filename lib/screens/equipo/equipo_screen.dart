import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/arbol_equipo.dart';
import '../../data/repositories/venta_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/transiciones.dart';
import '../../widgets/campo_busqueda.dart';
import '../../widgets/estados_vista.dart';
import 'avatar_persona.dart';
import 'barra_rendimiento.dart';
import 'persona_detalle_screen.dart';

class EquipoScreen extends StatefulWidget {
  const EquipoScreen({super.key});

  @override
  State<EquipoScreen> createState() => _EquipoScreenState();
}

class _EquipoScreenState extends State<EquipoScreen> {
  late Future<ArbolEquipo> _datos;
  final _busquedaController = TextEditingController();
  String _consulta = '';

  @override
  void initState() {
    super.initState();
    _datos = context.read<VentaRepository>().arbolEquipo();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    final nuevo = context.read<VentaRepository>().arbolEquipo();
    setState(() {
      _datos = nuevo;
    });
    try {
      await nuevo;
    } catch (_) {
      // El FutureBuilder ya muestra el error con su botón de reintento.
    }
  }

  void _limpiarBusqueda() {
    _busquedaController.clear();
    setState(() => _consulta = '');
  }

  void _abrirPersona(NodoEquipo nodo, String mes) {
    Navigator.of(context).push(
      rutaSuave<void>(PersonaDetalleScreen(nodo: nodo, mes: mes)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Text('Equipo', style: AppTypography.titulo(size: 26)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<ArbolEquipo>(
                future: _datos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.azulNabame),
                    );
                  }
                  if (snapshot.hasError) {
                    return EstadoError(
                      mensaje: 'No se pudo cargar el equipo.',
                      onReintentar: _recargar,
                    );
                  }
                  return _contenido(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido(ArbolEquipo arbol) {
    if (arbol.estaVacio) {
      return const EstadoVacio(
        icono: Icons.groups_outlined,
        titulo: 'Aún no hay equipo',
        mensaje:
            'Cuando se carguen socios, supervisores y vendedores aparecerán aquí.',
      );
    }

    final buscando = _consulta.trim().isNotEmpty;
    final resultados = arbol.buscar(_consulta);

    void abrir(NodoEquipo nodo) => _abrirPersona(nodo, arbol.mes);

    final Widget cuerpo;
    if (buscando && resultados.isEmpty) {
      cuerpo = EstadoVacio(
        icono: Icons.search_off_rounded,
        titulo: 'Sin resultados',
        mensaje: 'Prueba con otro nombre o con un cargo.',
        textoAccion: 'Quitar búsqueda',
        onAccion: _limpiarBusqueda,
      );
    } else {
      cuerpo = RefreshIndicator(
        color: AppColors.azulNabame,
        onRefresh: _recargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 24),
          children: buscando
              ? [
                  for (final nodo in resultados)
                    _FilaPersona(
                      nodo: nodo,
                      tamanoAvatar: 40,
                      izquierda: 22,
                      mostrarSuperior: true,
                      onTap: () => abrir(nodo),
                    ),
                ]
              : [
                  _Aparicion(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _jerarquia(arbol, abrir),
                    ),
                  ),
                ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: CampoBusqueda(
            controller: _busquedaController,
            sugerencia: 'Buscar por nombre o cargo',
            onChanged: (valor) => setState(() => _consulta = valor),
            onLimpiar: _limpiarBusqueda,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: cuerpo),
      ],
    );
  }

  List<Widget> _jerarquia(ArbolEquipo arbol, ValueChanged<NodoEquipo> abrir) {
    final inactivosSueltos = arbol.sinSuperiorInactivos;

    return [
      _ResumenEquipo(arbol: arbol),
      for (var i = 0; i < arbol.raices.length; i++) ...[
        if (i > 0) const _Separador(),
        _SeccionNodo(
          nodo: arbol.raices[i],
          nivel: 0,
          izquierda: 22,
          onAbrir: abrir,
        ),
      ],
      if (arbol.sinSuperior.isNotEmpty) ...[
        if (arbol.raices.isNotEmpty) const _Separador(),
        _EncabezadoGrupo(
          titulo: 'Sin supervisor asignado',
          detalle: cantidadDe(arbol.sinSuperior.length, 'persona', 'personas'),
        ),
        for (final nodo in arbol.sinSuperiorEnLista)
          _SeccionNodo(nodo: nodo, nivel: 1, izquierda: 22, onAbrir: abrir),
        if (inactivosSueltos.isNotEmpty)
          _GrupoInactivos(
            nodos: inactivosSueltos,
            izquierda: 22,
            onAbrir: abrir,
          ),
      ],
    ];
  }
}

/// Entrada de la lista: aparece con desvanecimiento y un leve ascenso.
class _Aparicion extends StatelessWidget {
  final Widget child;

  const _Aparicion({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, valor, hijo) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - valor)),
          child: hijo,
        ),
      ),
    );
  }
}

class _ResumenEquipo extends StatelessWidget {
  final ArbolEquipo arbol;

  const _ResumenEquipo({required this.arbol});

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comisión generada por el equipo en ${etiquetaMes(arbol.mes)}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: arbol.comisionMes),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, valor, _) =>
                Text(soles.format(valor), style: AppTypography.titulo(size: 34)),
          ),
          const SizedBox(height: 6),
          Text(
            '${cantidadDe(arbol.personas, 'persona', 'personas')}  ·  '
            '${cantidadDe(arbol.ventasEntregadas, 'venta entregada', 'ventas entregadas')}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.borde,
        indent: 22,
        endIndent: 22,
      ),
    );
  }
}

class _EncabezadoGrupo extends StatelessWidget {
  final String titulo;
  final String detalle;

  const _EncabezadoGrupo({required this.titulo, required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: AppTypography.titulo(
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.texto,
              ),
            ),
          ),
          Text(
            detalle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}

/// Una persona y, debajo, su equipo con sangría. La línea vertical nace bajo
/// el centro del avatar de quien encabeza el grupo.
class _SeccionNodo extends StatelessWidget {
  final NodoEquipo nodo;
  final int nivel;
  final double izquierda;
  final ValueChanged<NodoEquipo> onAbrir;

  const _SeccionNodo({
    required this.nodo,
    required this.nivel,
    required this.izquierda,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final tamano = nivel == 0 ? 44.0 : 38.0;
    final inactivos = nodo.miembrosInactivos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilaPersona(
          nodo: nodo,
          tamanoAvatar: tamano,
          izquierda: izquierda,
          destacada: nivel == 0,
          onTap: () => onAbrir(nodo),
        ),
        if (nodo.miembros.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: izquierda + tamano / 2),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.borde, width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final miembro in nodo.miembrosEnLista)
                    _SeccionNodo(
                      nodo: miembro,
                      nivel: nivel + 1,
                      izquierda: 14,
                      onAbrir: onAbrir,
                    ),
                  if (inactivos.isNotEmpty)
                    _GrupoInactivos(
                      nodos: inactivos,
                      izquierda: 14,
                      onAbrir: onAbrir,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FilaPersona extends StatelessWidget {
  final NodoEquipo nodo;
  final double tamanoAvatar;
  final double izquierda;
  final bool destacada;
  final bool mostrarSuperior;
  final VoidCallback onTap;

  /// Ancho disponible por debajo del cual los montos pasan bajo el nombre.
  static const _anchoDosColumnas = 200.0;

  const _FilaPersona({
    required this.nodo,
    required this.tamanoAvatar,
    required this.izquierda,
    required this.onTap,
    this.destacada = false,
    this.mostrarSuperior = false,
  });

  String get _subtitulo {
    final persona = nodo.persona;
    final superior = nodo.superior;
    final partes = <String>[persona.tipoTrabajador.label];
    if (mostrarSuperior && superior != null) {
      partes.add(superior.nombreCorto);
    } else if (nodo.personasACargo > 0) {
      partes.add('${nodo.personasACargo} a cargo');
    }
    return partes.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    const soles = FormatoSoles();
    final persona = nodo.persona;
    final rendimiento = nodo.rendimiento;
    final comision = soles.format(nodo.comisionMes);
    final ventas = cantidadDe(nodo.ventasEntregadas, 'venta', 'ventas');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(izquierda, 12, 22, 12),
        child: LayoutBuilder(
          builder: (context, restriccion) {
            // Si no caben dos columnas, los montos bajan debajo del nombre.
            final compacta = restriccion.maxWidth < _anchoDosColumnas;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarPersona(persona: persona, tamano: tamanoAvatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        persona.nombreCorto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: destacada
                            ? AppTypography.titulo(
                                size: 16,
                                weight: FontWeight.w700,
                                color: AppColors.texto,
                              )
                            : const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textoSecundario),
                      ),
                      if (compacta) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$comision  ·  $ventas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (rendimiento != null) ...[
                        const SizedBox(height: 8),
                        if (compacta)
                          BarraRendimiento(proporcion: rendimiento)
                        else
                          Row(
                            children: [
                              Expanded(
                                child:
                                    BarraRendimiento(proporcion: rendimiento),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(rendimiento * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: rendimiento >= 1
                                      ? AppColors.positivo
                                      : AppColors.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
                if (!compacta) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        comision,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ventas,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textoSecundario),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Lista compacta de personas inactivas al final de un grupo.
class _GrupoInactivos extends StatelessWidget {
  final List<NodoEquipo> nodos;
  final double izquierda;
  final ValueChanged<NodoEquipo> onAbrir;

  const _GrupoInactivos({
    required this.nodos,
    required this.izquierda,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(izquierda, 10, 22, 2),
          child: const Text(
            'Inactivos',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textoSecundario,
            ),
          ),
        ),
        for (final nodo in nodos)
          InkWell(
            onTap: () => onAbrir(nodo),
            child: Padding(
              padding: EdgeInsets.fromLTRB(izquierda, 8, 22, 8),
              child: Row(
                children: [
                  AvatarPersona(persona: nodo.persona, tamano: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: nodo.persona.nombreCorto,
                        children: [
                          TextSpan(
                            text: '  ·  ${nodo.persona.tipoTrabajador.label}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textoSecundario),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
