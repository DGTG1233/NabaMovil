/// Datos del Administrador. Con datos simulados son fijos; cuando haya un
/// servidor vendrán de la sesión. El correo también es el que acepta el
/// acceso, por eso `AuthService` lo toma de aquí.
class PerfilAdministrador {
  PerfilAdministrador._();

  static const nombre = 'Administrador';
  static const correo = 'admin@nabame.pe';
  static const rol = 'Administrador';
  static const acceso = 'Consulta y control';
  static const modulos = 'Ventas, Equipo, Morosidad, Reportes e Historial';

  /// Letra que va dentro del avatar.
  static String get inicial => nombre.substring(0, 1);
}
