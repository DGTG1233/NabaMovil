import 'package:intl/intl.dart';

/// Formato de soles con la convención peruana: S/ 1,234.50
class FormatoSoles {
  final int decimales;
  const FormatoSoles({this.decimales = 2});

  String format(num valor) {
    final patron = decimales == 0 ? '#,##0' : '#,##0.${'0' * decimales}';
    final numero = NumberFormat(patron, 'en_US').format(valor.abs());
    return '${valor < 0 ? '-' : ''}S/ $numero';
  }
}

/// 'YYYY-MM' a 'octubre 2026'.
String etiquetaMes(String mes) {
  final partes = mes.split('-');
  final fecha = DateTime(int.parse(partes[0]), int.parse(partes[1]));
  return DateFormat('MMMM yyyy', 'es_PE').format(fecha);
}

String fechaCorta(DateTime fecha) =>
    DateFormat('d MMM', 'es_PE').format(fecha).replaceAll('.', '');

/// '16 oct 2026'.
String fechaMedia(DateTime fecha) =>
    DateFormat('d MMM yyyy', 'es_PE').format(fecha).replaceAll('.', '');

String fechaLarga(DateTime fecha) =>
    DateFormat("d 'de' MMMM 'de' yyyy, HH:mm", 'es_PE').format(fecha);

/// '1 venta', '3 ventas'.
String cantidadDe(int cantidad, String singular, String plural) =>
    '$cantidad ${cantidad == 1 ? singular : plural}';

String etiquetaOrigen(String origen) => switch (origen) {
      'ALTA' => 'Alta',
      'PORTA_O_POST' => 'Portabilidad postpago',
      'PORTA_O_PRE' => 'Portabilidad prepago',
      'MONO' => 'Mono',
      'DUO' => 'Dúo',
      'TRIO' => 'Trío',
      'PAQUETIZACION' => 'Paquetización',
      'COMPLETA_MOVIL' => 'Completa móvil',
      'COMPLETA_FIJA' => 'Completa fija',
      _ => origen,
    };
