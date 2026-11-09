import 'package:flutter_test/flutter_test.dart';
import 'package:nabamemovil/data/auth/auth_service.dart';

import 'soporte/almacen_en_memoria.dart';

void main() {
  const correo = 'admin@nabame.pe';
  const clave = 'Nabame2026';

  late AlmacenEnMemoria almacen;
  late DateTime reloj;
  late AuthService servicio;

  AuthService crear() => AuthService(
        almacen: almacen,
        latencia: Duration.zero,
        ahora: () => reloj,
      );

  setUp(() {
    almacen = AlmacenEnMemoria();
    reloj = DateTime(2026, 10, 23, 10);
    servicio = crear();
  });

  Future<void> fallar(int veces) async {
    for (var i = 0; i < veces; i++) {
      await servicio.iniciarSesion(correo, 'incorrecta');
    }
  }

  group('iniciar sesión', () {
    test('con las credenciales correctas entra y guarda la sesión', () async {
      final resultado = await servicio.iniciarSesion(correo, clave);
      expect(resultado.exito, isTrue);
      expect(await servicio.sesionActiva(), isTrue);
    });

    test('acepta el correo con mayúsculas y espacios', () async {
      final resultado = await servicio.iniciarSesion('  ADMIN@Nabame.pe ', clave);
      expect(resultado.exito, isTrue);
    });

    test('con una contraseña incorrecta no entra y descuenta un intento', () async {
      final resultado = await servicio.iniciarSesion(correo, 'incorrecta');
      expect(resultado.exito, isFalse);
      expect(resultado.estado.intentosFallidos, 1);
      expect(resultado.estado.intentosRestantes, 4);
      expect(await servicio.sesionActiva(), isFalse);
    });

    test('un correo desconocido también cuenta como intento fallido', () async {
      final resultado = await servicio.iniciarSesion('otro@nabame.pe', clave);
      expect(resultado.exito, isFalse);
      expect(resultado.estado.intentosFallidos, 1);
    });
  });

  group('límite de intentos', () {
    test('el quinto fallo bloquea el acceso cinco minutos', () async {
      await fallar(4);
      final resultado = await servicio.iniciarSesion(correo, 'incorrecta');
      expect(resultado.exito, isFalse);
      expect(resultado.estado.estaBloqueado(reloj), isTrue);
      expect(resultado.estado.bloqueadoHasta, reloj.add(const Duration(minutes: 5)));
    });

    test('bloqueado, ni siquiera la contraseña correcta entra', () async {
      await fallar(5);
      final resultado = await servicio.iniciarSesion(correo, clave);
      expect(resultado.exito, isFalse);
      expect(await servicio.sesionActiva(), isFalse);
    });

    test('al terminar el bloqueo se puede entrar de nuevo', () async {
      await fallar(5);
      reloj = reloj.add(const Duration(minutes: 5, seconds: 1));
      final resultado = await servicio.iniciarSesion(correo, clave);
      expect(resultado.exito, isTrue);
    });

    test('un acceso correcto reinicia el contador', () async {
      await fallar(3);
      await servicio.iniciarSesion(correo, clave);
      final estado = await servicio.estadoAcceso();
      expect(estado.intentosFallidos, 0);
      expect(estado.bloqueadoHasta, isNull);
    });

    test('un fallo después de un bloqueo vencido empieza de cero', () async {
      await fallar(5);
      reloj = reloj.add(const Duration(minutes: 6));
      final resultado = await servicio.iniciarSesion(correo, 'incorrecta');
      expect(resultado.estado.intentosFallidos, 1);
      expect(resultado.estado.bloqueadoHasta, isNull);
    });

    test('el bloqueo sobrevive aunque se cree otro servicio', () async {
      await fallar(5);
      final otro = crear();
      final estado = await otro.estadoAcceso();
      expect(estado.estaBloqueado(reloj), isTrue);
    });

    test('un dato dañado en el almacén se ignora', () async {
      almacen.datos[AuthService.claveIntentos] = 'abc';
      almacen.datos[AuthService.claveBloqueo] = 'no es una fecha';
      final estado = await servicio.estadoAcceso();
      expect(estado.intentosFallidos, 0);
      expect(estado.estaBloqueado(reloj), isFalse);
    });
  });

  group('cerrar sesión', () {
    test('borra la sesión', () async {
      await servicio.iniciarSesion(correo, clave);
      await servicio.cerrarSesion();
      expect(await servicio.sesionActiva(), isFalse);
    });

    test('conserva el correo recordado', () async {
      await servicio.recordarEmail(' $correo ');
      await servicio.iniciarSesion(correo, clave);
      await servicio.cerrarSesion();
      expect(await servicio.obtenerEmailRecordado(), correo);
    });

    test('sin haber iniciado sesión no hay sesión activa', () async {
      expect(await servicio.sesionActiva(), isFalse);
    });
  });

  group('correo recordado', () {
    test('se guarda sin espacios y se puede olvidar', () async {
      await servicio.recordarEmail('  $correo ');
      expect(await servicio.obtenerEmailRecordado(), correo);
      await servicio.olvidarEmail();
      expect(await servicio.obtenerEmailRecordado(), isNull);
    });
  });
}