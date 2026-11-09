import '../../models/usuario.dart';
import '../../models/venta.dart';
import '../../models/venta_estado.dart';
import '../../utils/texto.dart';
import '../datasource/data_source.dart';
import 'arbol_equipo.dart';
import 'reporte_comision.dart';

class ResumenDashboard {
  final int ventasDelDia;
  final int ventasDelMes;
  final double comisionDelMes;
  final Map<int, double> comisionAcumuladaPorDia;

  ResumenDashboard({
    required this.ventasDelDia,
    required this.ventasDelMes,
    required this.comisionDelMes,
    required this.comisionAcumuladaPorDia,
  });
}

class RankingVendedor {
  final Usuario vendedor;
  final int totalVentas;
  final double comisionGenerada;

  RankingVendedor({
    required this.vendedor,
    required this.totalVentas,
    required this.comisionGenerada,
  });
}

/// Una venta junto con el vendedor que la registró (puede faltar si el
/// usuario ya no existe en los datos).
class VentaConVendedor {
  final Venta venta;
  final Usuario? vendedor;

  const VentaConVendedor({required this.venta, required this.vendedor});
}

/// Capa de negocio sobre el DataSource: agrupa, filtra y calcula
/// lo que las pantallas necesitan.
class VentaRepository {
  final DataSource dataSource;

  VentaRepository(this.dataSource);

  Future<ResumenDashboard> resumenDashboard({DateTime? referencia}) async {
    final hoy = referencia ?? DateTime.now();
    final mesActual = _claveMes(hoy);

    final ventas = await dataSource.getVentas();
    final ventasEntregadas =
        ventas.where((v) => v.estado.generaComision).toList();

    final ventasDelMes =
        ventasEntregadas.where((v) => v.mes == mesActual).toList();

    final ventasDelDia = ventasDelMes.where((v) {
      final f = v.fechaRegistro;
      return f.year == hoy.year && f.month == hoy.month && f.day == hoy.day;
    }).length;

    final comisionDelMes = ventasDelMes.fold<double>(
      0,
      (acc, v) => acc + (v.comisionCalculada ?? 0),
    );

    final comisionPorDia = <int, double>{};
    for (final v in ventasDelMes) {
      final dia = v.fechaRegistro.day;
      comisionPorDia[dia] =
          (comisionPorDia[dia] ?? 0) + (v.comisionCalculada ?? 0);
    }

    final comisionAcumuladaPorDia = <int, double>{};
    double acumulado = 0;
    for (var dia = 1; dia <= hoy.day; dia++) {
      acumulado += comisionPorDia[dia] ?? 0;
      comisionAcumuladaPorDia[dia] = acumulado;
    }

    return ResumenDashboard(
      ventasDelDia: ventasDelDia,
      ventasDelMes: ventasDelMes.length,
      comisionDelMes: comisionDelMes,
      comisionAcumuladaPorDia: comisionAcumuladaPorDia,
    );
  }

  Future<double> comisionMesAnterior({DateTime? referencia}) async {
    final hoy = referencia ?? DateTime.now();
    final mesAnteriorFecha = DateTime(hoy.year, hoy.month - 1);
    final mesAnterior = _claveMes(mesAnteriorFecha);

    final ventas = await dataSource.getVentas();
    final ventasDelMesAnterior = ventas.where(
      (v) => v.mes == mesAnterior && v.estado.generaComision,
    );

    return ventasDelMesAnterior.fold<double>(
      0,
      (acc, v) => acc + (v.comisionCalculada ?? 0),
    );
  }

  /// Comisión total por mes, ordenada de más antiguo a más reciente.
  Future<Map<String, double>> comisionPorMes() async {
    final ventas = await dataSource.getVentas();
    final entregadas = ventas.where((v) => v.estado.generaComision);

    final porMes = <String, double>{};
    for (final v in entregadas) {
      porMes[v.mes] = (porMes[v.mes] ?? 0) + (v.comisionCalculada ?? 0);
    }

    final mesesOrdenados = porMes.keys.toList()..sort();
    return {for (final m in mesesOrdenados) m: porMes[m]!};
  }

  Future<List<Venta>> ventasPorVendedor(int userId) async {
    final ventas = await dataSource.getVentas();
    return ventas.where((v) => v.userId == userId).toList()
      ..sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
  }

  Future<List<Venta>> ventasFiltradas({
    VentaEstado? estado,
    String? mes,
  }) async {
    final ventas = await dataSource.getVentas();
    return ventas.where((v) {
      final coincideEstado = estado == null || v.estado == estado;
      final coincideMes = mes == null || v.mes == mes;
      return coincideEstado && coincideMes;
    }).toList()
      ..sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
  }

  /// Todas las ventas con su vendedor, de la más reciente a la más antigua.
  Future<List<VentaConVendedor>> ventasConVendedor() async {
    final ventas = await dataSource.getVentas();
    final usuarios = await dataSource.getUsuarios();
    final porId = {for (final u in usuarios) u.id: u};

    return ventas
        .map((v) => VentaConVendedor(venta: v, vendedor: porId[v.userId]))
        .toList()
      ..sort((a, b) => b.venta.fechaRegistro.compareTo(a.venta.fechaRegistro));
  }

  /// Búsqueda y filtros en memoria. Es una función pura (no toca datos),
  /// por eso se puede probar sin pantallas ni servidor.
  static List<VentaConVendedor> filtrar(
    List<VentaConVendedor> origen, {
    String consulta = '',
    VentaEstado? estado,
    String? mes,
    bool masRecientesPrimero = true,
  }) {
    final q = normalizarTexto(consulta.trim());

    final filtradas = origen.where((item) {
      final v = item.venta;
      if (estado != null && v.estado != estado) return false;
      if (mes != null && v.mes != mes) return false;
      if (q.isEmpty) return true;

      final vendedor = item.vendedor;
      final campos = [
        v.nombreCliente,
        v.dniCliente,
        v.numeroContacto,
        if (vendedor != null) vendedor.nombreCompleto,
      ];
      return campos.any((c) => normalizarTexto(c).contains(q));
    }).toList();

    filtradas.sort(
      (a, b) => masRecientesPrimero
          ? b.venta.fechaRegistro.compareTo(a.venta.fechaRegistro)
          : a.venta.fechaRegistro.compareTo(b.venta.fechaRegistro),
    );
    return filtradas;
  }

  /// Jerarquía del mes: Socio Comercial, Supervisores y Vendedores con sus
  /// totales. Sin `referencia` usa el mes de la fecha del dispositivo.
  Future<ArbolEquipo> arbolEquipo({DateTime? referencia}) async {
    final mes = _claveMes(referencia ?? DateTime.now());
    final usuarios = await dataSource.getUsuarios();
    final ventas = await dataSource.getVentas();
    return ArbolEquipo.construir(usuarios: usuarios, ventas: ventas, mes: mes);
  }

  /// Comisión generada del mes por Socio Comercial. Sin `mes` usa el más
  /// reciente que tenga ventas con comisión.
  Future<ReporteComision> reporteComision({String? mes}) async {
    final usuarios = await dataSource.getUsuarios();
    final ventas = await dataSource.getVentas();
    final disponibles = mesesConComisionDe(ventas);
    final elegido = mes ??
        (disponibles.isEmpty ? _claveMes(DateTime.now()) : disponibles.first);

    return ReporteComision(
      arbol: ArbolEquipo.construir(
        usuarios: usuarios,
        ventas: ventas,
        mes: elegido,
      ),
      mesesDisponibles: disponibles,
    );
  }

  /// Meses con al menos una venta que genera comisión, del más reciente al
  /// más antiguo.
  static List<String> mesesConComisionDe(List<Venta> ventas) {
    final meses = {
      for (final v in ventas)
        if (v.estado.generaComision) v.mes,
    }.toList();
    return meses..sort((a, b) => b.compareTo(a));
  }

  /// Ventas del mes de una persona y de todo su equipo, de la más reciente
  /// a la más antigua.
  Future<List<VentaConVendedor>> ventasDelEquipo(
    NodoEquipo nodo, {
    required String mes,
  }) async {
    final todas = await ventasConVendedor();
    return filtrarPorEquipo(todas, ids: nodo.idsDelEquipo, mes: mes);
  }

  static List<VentaConVendedor> filtrarPorEquipo(
    List<VentaConVendedor> origen, {
    required Set<int> ids,
    required String mes,
  }) {
    return origen
        .where((i) => i.venta.mes == mes && ids.contains(i.venta.userId))
        .toList();
  }

  static String _claveMes(DateTime fecha) =>
      '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';

  Future<List<RankingVendedor>> rankingVendedores({String? mes}) async {
    final usuarios = await dataSource.getUsuarios();
    final ventas = await dataSource.getVentas();
    final vendedores =
        usuarios.where((u) => u.tipoTrabajador.esVendedor).toList();

    final resultado = <RankingVendedor>[];
    for (final v in vendedores) {
      final ventasDeEste = ventas.where((venta) {
        final esDeEsteVendedor = venta.userId == v.id;
        final coincideMes = mes == null || venta.mes == mes;
        return esDeEsteVendedor && coincideMes && venta.estado.generaComision;
      });
      resultado.add(RankingVendedor(
        vendedor: v,
        totalVentas: ventasDeEste.length,
        comisionGenerada: ventasDeEste.fold(
          0.0,
          (acc, venta) => acc + (venta.comisionCalculada ?? 0),
        ),
      ));
    }

    resultado.sort((a, b) => b.totalVentas.compareTo(a.totalVentas));
    return resultado;
  }
}