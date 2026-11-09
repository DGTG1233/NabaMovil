import '../../models/usuario_jerarquia.dart';
import '../../utils/formato.dart';
import 'arbol_equipo.dart';

/// Comisión generada en un mes, agrupada por Socio Comercial.
///
/// Es lo que generan las ventas entregadas de cada cadena, no lo que cobra
/// cada persona: cada Socio reparte la comisión entre su equipo.
class ReporteComision {
  final ArbolEquipo arbol;

  /// Meses que se pueden consultar, del más reciente al más antiguo.
  final List<String> mesesDisponibles;

  const ReporteComision({required this.arbol, required this.mesesDisponibles});

  String get mes => arbol.mes;

  List<NodoEquipo> get socios => arbol.socios;

  List<NodoEquipo> get sinSocio => arbol.sinSocio;

  double get comisionTotal => arbol.comisionMes;

  int get ventasEntregadas => arbol.ventasEntregadas;

  int get personas => arbol.personas;

  bool get estaVacio => arbol.estaVacio;

  /// Parte de la comisión total que genera un nodo, de 0 a 1.
  double participacionDe(NodoEquipo nodo) =>
      comisionTotal <= 0 ? 0 : nodo.comisionMes / comisionTotal;

  /// Texto listo para copiar y enviar al Socio: total, supervisores y
  /// vendedores con ventas.
  String resumenDe(NodoEquipo socio) {
    const soles = FormatoSoles();

    String linea(NodoEquipo nodo, {String sufijo = '', String sangria = ''}) {
      final persona = nodo.persona;
      final inactivo = persona.activo ? '' : ' (inactivo)';
      final cantidad = cantidadDe(nodo.ventasEntregadas, 'venta', 'ventas');
      return '$sangria${persona.nombreCorto}$sufijo$inactivo: '
          '${soles.format(nodo.comisionMes)}, $cantidad';
    }

    final lineas = <String>[
      'Comisión generada en ${etiquetaMes(mes)}',
      'Socio Comercial: ${socio.persona.nombreCorto}',
      'Total: ${soles.format(socio.comisionMes)} '
          '(${cantidadDe(socio.ventasEntregadas, 'venta entregada', 'ventas entregadas')})',
      '',
    ];

    for (final miembro in socio.miembros) {
      if (miembro.persona.esSupervisor) {
        lineas.add(linea(miembro, sufijo: ' (Supervisor)'));
        for (final vendedor in miembro.miembros) {
          if (vendedor.ventasEntregadas == 0) continue;
          lineas.add(linea(vendedor, sangria: '  '));
        }
      } else if (miembro.ventasEntregadas > 0) {
        lineas.add(linea(miembro));
      }
    }

    return lineas.join('\n');
  }
}