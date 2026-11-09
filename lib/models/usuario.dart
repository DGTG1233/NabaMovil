import 'tipo_trabajador.dart';

class Usuario {
  final int id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String dni;
  final String email;
  final TipoTrabajador tipoTrabajador;
  final int? supervisorId;
  final bool activo;
  final String? fotoPerfil;
  final double? cuotaMensual;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.dni,
    required this.email,
    required this.tipoTrabajador,
    this.supervisorId,
    this.activo = true,
    this.fotoPerfil,
    this.cuotaMensual,
  });

  String get nombreCompleto => '$apellidoPaterno $apellidoMaterno, $nombre';

  /// Nombre y primer apellido, para filas y encabezados.
  String get nombreCorto => '$nombre $apellidoPaterno';

  String get iniciales =>
      '${apellidoPaterno.isNotEmpty ? apellidoPaterno[0].toUpperCase() : ''}'
      '${nombre.isNotEmpty ? nombre[0].toUpperCase() : ''}';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      apellidoPaterno: json['apellido_paterno'] as String,
      apellidoMaterno: json['apellido_materno'] as String,
      dni: json['dni'] as String,
      email: json['email'] as String,
      tipoTrabajador: TipoTrabajador.fromValor(json['tipo_trabajador'] as String),
      supervisorId: json['supervisor_id'] as int?,
      activo: json['activo'] as bool? ?? true,
      fotoPerfil: json['foto_perfil'] as String?,
      cuotaMensual: (json['cuota_mensual'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'dni': dni,
        'email': email,
        'tipo_trabajador': tipoTrabajador.valor,
        'supervisor_id': supervisorId,
        'activo': activo,
        'foto_perfil': fotoPerfil,
        'cuota_mensual': cuotaMensual,
      };
}