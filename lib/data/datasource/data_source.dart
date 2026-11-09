import '../../models/caso_morosidad.dart';
import '../../models/usuario.dart';
import '../../models/venta.dart';
import '../../models/pago.dart';

abstract class DataSource {
  Future<List<Usuario>> getUsuarios();
  Future<List<Venta>> getVentas();
  Future<List<Pago>> getPagos();
  Future<List<CasoMorosidad>> getMorosidad();
}
