import '../../models/caso_morosidad.dart';
import '../datasource/data_source.dart';
import 'resumen_morosidad.dart';

/// Los dos segmentos de morosidad, listos para alternar en pantalla.
class DatosMorosidad {
  final ResumenMorosidad movil;
  final ResumenMorosidad fija;

  const DatosMorosidad({required this.movil, required this.fija});

  ResumenMorosidad de(SegmentoMorosidad segmento) => switch (segmento) {
        SegmentoMorosidad.movil => movil,
        SegmentoMorosidad.fija => fija,
      };
}

class MorosidadRepository {
  final DataSource dataSource;

  MorosidadRepository(this.dataSource);

  /// La fecha de corte es la de los propios datos, no la del dispositivo,
  /// para que los días de cierre no cambien solos con el paso del tiempo.
  Future<DatosMorosidad> cargar() async {
    final casos = await dataSource.getMorosidad();
    final usuarios = await dataSource.getUsuarios();
    final fechaCorte = fechaCorteDe(casos);

    ResumenMorosidad resumen(SegmentoMorosidad segmento) =>
        ResumenMorosidad.construir(
          segmento: segmento,
          casos: casos,
          usuarios: usuarios,
          fechaCorte: fechaCorte,
        );

    return DatosMorosidad(
      movil: resumen(SegmentoMorosidad.movil),
      fija: resumen(SegmentoMorosidad.fija),
    );
  }

  static DateTime fechaCorteDe(List<CasoMorosidad> casos) {
    if (casos.isEmpty) return DateTime.now();
    return casos
        .map((c) => c.fechaProceso)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }
}
