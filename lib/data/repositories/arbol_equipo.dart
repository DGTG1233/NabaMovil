import '../../models/usuario.dart';
import '../../models/usuario_jerarquia.dart';
import '../../models/venta.dart';
import '../../utils/texto.dart';

/// Una persona de la cadena de ventas con su equipo y los totales del mes
/// calculados sobre ese equipo completo.
///
/// Las ventas y la comisión cuentan a todos los miembros, también a los
/// inactivos, porque ese dinero ya se generó. La cuota y las personas a
/// cargo cuentan solo a los activos.
class NodoEquipo {
  final Usuario persona;

  /// Superior directo. Es null en las raíces y en quien no tiene superior.
  final Usuario? superior;
  final List<NodoEquipo> miembros;
  final int ventasEntregadas;
  final double comisionMes;
  final int personasACargo;

  /// Suma de las cuotas de los miembros activos que tienen cuota.
  final double? cuotaMes;

  /// Ventas entregadas de quienes entran en la cuota, para que numerador y
  /// denominador midan lo mismo.
  final int ventasParaCuota;

  NodoEquipo({
    required this.persona,
    required this.superior,
    required this.miembros,
    required this.ventasEntregadas,
    required this.comisionMes,
    required this.personasACargo,
    required this.cuotaMes,
    required this.ventasParaCuota,
  });

  /// Avance sobre la cuota: 1.0 es el 100 %. Null si no hay cuota.
  double? get rendimiento {
    final cuota = cuotaMes;
    if (cuota == null || cuota <= 0) return null;
    return ventasParaCuota / cuota;
  }

  /// Ids de la persona y de todo su equipo, a cualquier profundidad.
  Set<int> get idsDelEquipo => {
        persona.id,
        for (final m in miembros) ...m.idsDelEquipo,
      };

  bool get esInactivoSinEquipo => !persona.activo && miembros.isEmpty;

  /// Miembros que van en la lista principal. Un inactivo con gente a su
  /// cargo se queda aquí para no esconder a su equipo.
  List<NodoEquipo> get miembrosEnLista =>
      miembros.where((m) => !m.esInactivoSinEquipo).toList();

  /// Miembros inactivos sin nadie a cargo, para la lista compacta.
  List<NodoEquipo> get miembrosInactivos =>
      miembros.where((m) => m.esInactivoSinEquipo).toList();
}

/// Jerarquía completa de un mes: Socio Comercial, Supervisores y Vendedores.
class ArbolEquipo {
  final String mes;

  /// Socios Comerciales y, si alguno no tiene socio, sus Supervisores.
  final List<NodoEquipo> raices;

  /// Vendedores sin superior válido.
  final List<NodoEquipo> sinSuperior;

  const ArbolEquipo({
    required this.mes,
    required this.raices,
    required this.sinSuperior,
  });

  bool get estaVacio => raices.isEmpty && sinSuperior.isEmpty;

  /// Raíces que son Socios Comerciales.
  List<NodoEquipo> get socios =>
      raices.where((n) => n.persona.esSocioComercial).toList();

  /// Quienes no cuelgan de ningún Socio Comercial: supervisores sin socio y
  /// vendedores sin superior.
  List<NodoEquipo> get sinSocio => [
        ...raices.where((n) => !n.persona.esSocioComercial),
        ...sinSuperior,
      ];

  List<NodoEquipo> get sinSuperiorEnLista =>
      sinSuperior.where((n) => !n.esInactivoSinEquipo).toList();

  List<NodoEquipo> get sinSuperiorInactivos =>
      sinSuperior.where((n) => n.esInactivoSinEquipo).toList();

  Iterable<NodoEquipo> get _nivelSuperior => [...raices, ...sinSuperior];

  int get ventasEntregadas =>
      _nivelSuperior.fold(0, (suma, n) => suma + n.ventasEntregadas);

  double get comisionMes =>
      _nivelSuperior.fold(0.0, (suma, n) => suma + n.comisionMes);

  /// Personas activas de la cadena de ventas.
  int get personas => _nivelSuperior.fold(
        0,
        (suma, n) => suma + (n.persona.activo ? 1 : 0) + n.personasACargo,
      );

  /// Todos los nodos, recorridos en profundidad.
  List<NodoEquipo> get todos {
    final resultado = <NodoEquipo>[];
    void recorrer(NodoEquipo nodo) {
      resultado.add(nodo);
      nodo.miembros.forEach(recorrer);
    }

    _nivelSuperior.forEach(recorrer);
    return resultado;
  }

  /// Busca por nombre, apellidos o cargo. Cada palabra de la consulta debe
  /// aparecer, sin importar tildes, mayúsculas ni el orden.
  List<NodoEquipo> buscar(String consulta) {
    final q = normalizarTexto(consulta.trim());
    if (q.isEmpty) return const [];
    final palabras = q.split(RegExp(r'\s+'));

    return todos.where((nodo) {
      final p = nodo.persona;
      final texto = normalizarTexto(
        '${p.nombre} ${p.apellidoPaterno} ${p.apellidoMaterno} '
        '${p.tipoTrabajador.label}',
      );
      return palabras.every(texto.contains);
    }).toList();
  }

  /// Arma la jerarquía a partir de `supervisor_id`. Es una función pura:
  /// no toca datos, por eso se prueba sin pantallas ni servidor.
  ///
  /// Un `supervisor_id` que no existe, que apunta a un vendedor o a uno
  /// mismo deja a la persona sin superior.
  static ArbolEquipo construir({
    required List<Usuario> usuarios,
    required List<Venta> ventas,
    required String mes,
  }) {
    final enCadena =
        usuarios.where((u) => u.perteneceALaCadenaDeVentas).toList();
    final porId = {for (final u in enCadena) u.id: u};

    final ventasPorUsuario = <int, int>{};
    final comisionPorUsuario = <int, double>{};
    for (final v in ventas) {
      if (v.mes != mes || !v.estado.generaComision) continue;
      ventasPorUsuario[v.userId] = (ventasPorUsuario[v.userId] ?? 0) + 1;
      comisionPorUsuario[v.userId] =
          (comisionPorUsuario[v.userId] ?? 0) + (v.comisionCalculada ?? 0);
    }

    final miembrosDe = <int, List<Usuario>>{};
    final sueltos = <Usuario>[];
    for (final u in enCadena) {
      final superior = porId[u.supervisorId];
      if (superior != null && superior.id != u.id && superior.puedeTenerEquipo) {
        miembrosDe.putIfAbsent(superior.id, () => []).add(u);
      } else {
        sueltos.add(u);
      }
    }

    NodoEquipo armar(Usuario persona, Usuario? superior) {
      final miembros = [
        for (final m in miembrosDe[persona.id] ?? const <Usuario>[])
          armar(m, persona),
      ]..sort(_comparar);

      final propiasEntregadas = ventasPorUsuario[persona.id] ?? 0;
      final cuotaPropia = persona.activo ? persona.cuotaMensual : null;

      var ventasEquipo = propiasEntregadas;
      var comision = comisionPorUsuario[persona.id] ?? 0.0;
      var aCargo = 0;
      var paraCuota = cuotaPropia == null ? 0 : propiasEntregadas;
      var cuota = cuotaPropia;

      for (final m in miembros) {
        ventasEquipo += m.ventasEntregadas;
        comision += m.comisionMes;
        aCargo += (m.persona.activo ? 1 : 0) + m.personasACargo;
        paraCuota += m.ventasParaCuota;
        final cuotaMiembro = m.cuotaMes;
        if (cuotaMiembro != null) cuota = (cuota ?? 0) + cuotaMiembro;
      }

      return NodoEquipo(
        persona: persona,
        superior: superior,
        miembros: miembros,
        ventasEntregadas: ventasEquipo,
        comisionMes: comision,
        personasACargo: aCargo,
        cuotaMes: cuota,
        ventasParaCuota: paraCuota,
      );
    }

    final raices = [
      for (final u in sueltos)
        if (u.puedeTenerEquipo) armar(u, null),
    ]..sort(_compararRaices);

    final sinSuperior = [
      for (final u in sueltos)
        if (!u.puedeTenerEquipo) armar(u, null),
    ]..sort(_comparar);

    return ArbolEquipo(mes: mes, raices: raices, sinSuperior: sinSuperior);
  }
}

/// Activos primero, luego más ventas entregadas y por último alfabético.
int _comparar(NodoEquipo a, NodoEquipo b) {
  if (a.persona.activo != b.persona.activo) return a.persona.activo ? -1 : 1;
  final porVentas = b.ventasEntregadas.compareTo(a.ventasEntregadas);
  if (porVentas != 0) return porVentas;
  return a.persona.nombreCompleto.compareTo(b.persona.nombreCompleto);
}

int _compararRaices(NodoEquipo a, NodoEquipo b) {
  final aEsSocio = a.persona.esSocioComercial;
  if (aEsSocio != b.persona.esSocioComercial) return aEsSocio ? -1 : 1;
  return _comparar(a, b);
}