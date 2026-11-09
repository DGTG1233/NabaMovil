import '../datasource/data_source.dart';
import 'avisos.dart';

class NotificacionesRepository {
  final DataSource dataSource;

  NotificacionesRepository(this.dataSource);

  Future<List<Aviso>> cargar() async {
    final casos = await dataSource.getMorosidad();
    final pagos = await dataSource.getPagos();
    final ventas = await dataSource.getVentas();
    return Avisos.construir(casos: casos, pagos: pagos, ventas: ventas);
  }
}
