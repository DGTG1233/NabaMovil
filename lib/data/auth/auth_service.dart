import '../../models/perfil_administrador.dart';
import 'almacen_seguro.dart';
import 'limite_intentos.dart';

/// Resultado de un intento de acceso, con el estado del límite de intentos
/// para que la pantalla pueda avisar cuántos quedan o cuánto dura el bloqueo.
class ResultadoAcceso {
  final bool exito;
  final EstadoAcceso estado;

  const ResultadoAcceso({required this.exito, required this.estado});
}

class AuthService {
  static const claveSesion = 'nabame_sesion_activa';
  static const claveEmailRecordado = 'nabame_email_recordado';
  static const claveIntentos = 'nabame_intentos_fallidos';
  static const claveBloqueo = 'nabame_bloqueo_hasta';

  static const _passwordAdmin = 'Nabame2026';

  final AlmacenSeguro _almacen;
  final Duration _retardo;
  final DateTime Function() _ahora;

  /// `latencia` simula el tiempo de respuesta de un servidor; `ahora` permite
  /// controlar el reloj en las pruebas.
  AuthService({
    AlmacenSeguro? almacen,
    Duration latencia = const Duration(milliseconds: 600),
    DateTime Function()? ahora,
  })  : _almacen = almacen ?? AlmacenSeguroFlutter(),
        _retardo = latencia,
        _ahora = ahora ?? DateTime.now;

  /// Si el acceso está bloqueado no se revisan las credenciales, ni siquiera
  /// las correctas.
  Future<ResultadoAcceso> iniciarSesion(String email, String password) async {
    final estado = await estadoAcceso();
    if (estado.estaBloqueado(_ahora())) {
      return ResultadoAcceso(exito: false, estado: estado);
    }

    await Future.delayed(_retardo);
    final esValido = email.trim().toLowerCase() == PerfilAdministrador.correo &&
        password == _passwordAdmin;

    if (esValido) {
      await _almacen.escribir(claveSesion, 'true');
      await _guardarEstado(EstadoAcceso.limpio);
      return const ResultadoAcceso(exito: true, estado: EstadoAcceso.limpio);
    }

    final nuevo = LimiteIntentos.registrarFallo(estado, _ahora());
    await _guardarEstado(nuevo);
    return ResultadoAcceso(exito: false, estado: nuevo);
  }

  /// Intentos fallidos y bloqueo guardados. Un dato dañado se ignora.
  Future<EstadoAcceso> estadoAcceso() async {
    final intentos = int.tryParse(await _almacen.leer(claveIntentos) ?? '');
    final bloqueo = DateTime.tryParse(await _almacen.leer(claveBloqueo) ?? '');
    return EstadoAcceso(intentosFallidos: intentos ?? 0, bloqueadoHasta: bloqueo);
  }

  Future<void> _guardarEstado(EstadoAcceso estado) async {
    await _almacen.escribir(claveIntentos, '${estado.intentosFallidos}');
    final hasta = estado.bloqueadoHasta;
    if (hasta == null) {
      await _almacen.borrar(claveBloqueo);
    } else {
      await _almacen.escribir(claveBloqueo, hasta.toIso8601String());
    }
  }

  Future<bool> sesionActiva() async {
    final valor = await _almacen.leer(claveSesion);
    return valor == 'true';
  }

  /// Cierra la sesión pero conserva el correo recordado.
  Future<void> cerrarSesion() async {
    await _almacen.borrar(claveSesion);
  }

  Future<void> recordarEmail(String email) async {
    await _almacen.escribir(claveEmailRecordado, email.trim());
  }

  Future<String?> obtenerEmailRecordado() async {
    return _almacen.leer(claveEmailRecordado);
  }

  Future<void> olvidarEmail() async {
    await _almacen.borrar(claveEmailRecordado);
  }
}