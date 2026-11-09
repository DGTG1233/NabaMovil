import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth/auth_service.dart';
import '../../theme/app_theme.dart';
import '../shell/app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;
  final _botonIngresarKey = GlobalKey<_BotonIngresarState>();

  bool _passwordVisible = false;
  bool _recordarme = false;
  String? _errorGeneral;

  /// Si no es null, el acceso está bloqueado hasta ese instante.
  DateTime? _bloqueadoHasta;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _authService = context.read<AuthService>();
    _cargarEmailRecordado();
    _revisarBloqueo();
  }

  Future<void> _cargarEmailRecordado() async {
    final email = await _authService.obtenerEmailRecordado();
    if (email != null && mounted) {
      setState(() {
        _emailController.text = email;
        _recordarme = true;
      });
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Si la app se cerró durante un bloqueo, al volver sigue bloqueada.
  Future<void> _revisarBloqueo() async {
    final estado = await _authService.estadoAcceso();
    if (!mounted || !estado.estaBloqueado(DateTime.now())) return;
    _iniciarCuentaRegresiva(estado.bloqueadoHasta!);
  }

  void _iniciarCuentaRegresiva(DateTime hasta) {
    _reloj?.cancel();
    setState(() {
      _bloqueadoHasta = hasta;
      _errorGeneral = null;
    });
    _reloj = Timer.periodic(const Duration(seconds: 1), (temporizador) {
      if (!mounted) {
        temporizador.cancel();
        return;
      }
      setState(() {
        if (!DateTime.now().isBefore(hasta)) {
          temporizador.cancel();
          _bloqueadoHasta = null;
        }
      });
    });
  }

  Future<bool> _realizarLogin() async {
    final resultado = await _authService.iniciarSesion(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return resultado.exito;

    if (resultado.exito) {
      if (_recordarme) {
        await _authService.recordarEmail(_emailController.text);
      } else {
        await _authService.olvidarEmail();
      }
      return true;
    }

    final bloqueo = resultado.estado.bloqueadoHasta;
    if (bloqueo != null && resultado.estado.estaBloqueado(DateTime.now())) {
      _iniciarCuentaRegresiva(bloqueo);
    } else {
      final restantes = resultado.estado.intentosRestantes;
      setState(() {
        _errorGeneral = 'El correo o la contraseña no son correctos. '
            '${restantes == 1 ? 'Te queda 1 intento.' : 'Te quedan $restantes intentos.'}';
      });
    }
    return false;
  }

  /// Mensaje de error que se muestra bajo el formulario: el bloqueo, con su
  /// cuenta regresiva, o el último intento fallido.
  String? get _mensajeError {
    final hasta = _bloqueadoHasta;
    if (hasta == null) return _errorGeneral;
    final restante = hasta.difference(DateTime.now());
    final segundos =
        restante.isNegative ? 0 : (restante.inMilliseconds / 1000).ceil();
    final minutos = segundos ~/ 60;
    final resto = (segundos % 60).toString().padLeft(2, '0');
    return 'Demasiados intentos. Vuelve a intentarlo en $minutos:$resto.';
  }

  void _intentarIngresar() {
    _botonIngresarKey.currentState?._manejarTap();
  }

  void _irADashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  void _recuperarClave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Escríbele a soporte@nabame.pe para restablecerla.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -60,
            child: _Blob(
              color: AppColors.azulNabame.withValues(alpha: 0.14),
              size: 230,
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: _Blob(
              color: AppColors.marinoNabame.withValues(alpha: 0.10),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 140,
            right: -50,
            child: _Blob(
              color: AppColors.azulNabame.withValues(alpha: 0.08),
              size: 140,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/images/Logo1.png',
                            height: 148,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('Bienvenido', style: AppTypography.titulo()),
                        const SizedBox(height: 6),
                        const Text(
                          'Ingresa tus credenciales para continuar',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 36),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Correo corporativo',
                            filled: false,
                            prefixIcon: Icon(
                              Icons.person_outline,
                              size: 20,
                              color: AppColors.textoSecundario,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.borde),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.borde),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.azulNabame,
                                width: 1.6,
                              ),
                            ),
                          ),
                          validator: (valor) {
                            final texto = valor?.trim() ?? '';
                            if (texto.isEmpty) {
                              return 'Ingresa tu correo corporativo.';
                            }
                            final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                            if (!regex.hasMatch(texto)) {
                              return 'Ese correo no tiene un formato válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _intentarIngresar(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            filled: false,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: AppColors.textoSecundario,
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 44,
                            ),
                            suffixIcon: IconButton(
                              splashRadius: 20,
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textoSecundario,
                                size: 19,
                              ),
                              onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible,
                              ),
                            ),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.borde),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.borde),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.azulNabame,
                                width: 1.6,
                              ),
                            ),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.isEmpty) {
                              return 'Ingresa tu contraseña.';
                            }
                            if (valor.length < 6) {
                              return 'Debe tener al menos 6 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _recordarme = !_recordarme),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _recordarme,
                                          onChanged: (valor) => setState(
                                            () => _recordarme = valor ?? false,
                                          ),
                                          activeColor: AppColors.azulNabame,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          'Recordarme',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textoSecundario,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _recuperarClave,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.azulNabame,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '¿Olvidaste tu clave?',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_mensajeError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _mensajeError!,
                            style: const TextStyle(
                              color: AppColors.negativo,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 26),
                        _BotonIngresar(
                          key: _botonIngresarKey,
                          validar: () {
                            if (_bloqueadoHasta != null) return false;
                            setState(() => _errorGeneral = null);
                            return _formKey.currentState?.validate() ?? false;
                          },
                          onIngresar: _realizarLogin,
                          onExito: _irADashboard,
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Text(
                            'Acceso exclusivo para administradores de NABAME',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textoSecundario.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Forma orgánica (tipo "nube") usada como acento decorativo de fondo.
class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(size: Size(size, size), painter: _BlobPainter(color)),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;
  _BlobPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.85, h * 0.02, w * 1.02, h * 0.32, w * 0.95, h * 0.55)
      ..cubicTo(w * 0.90, h * 0.80, w * 0.65, h * 1.02, w * 0.40, h * 0.98)
      ..cubicTo(w * 0.12, h * 0.94, -h * 0.02, h * 0.68, 0.04 * w, h * 0.40)
      ..cubicTo(w * 0.08, h * 0.15, w * 0.22, -h * 0.02, w * 0.5, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BotonIngresar extends StatefulWidget {
  final bool Function() validar;
  final Future<bool> Function() onIngresar;
  final VoidCallback onExito;

  const _BotonIngresar({
    super.key,
    required this.validar,
    required this.onIngresar,
    required this.onExito,
  });

  @override
  State<_BotonIngresar> createState() => _BotonIngresarState();
}

class _BotonIngresarState extends State<_BotonIngresar>
    with TickerProviderStateMixin {
  late final AnimationController _relleno;
  late final AnimationController _sacudida;
  late final AnimationController _rellenoHover;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _relleno = AnimationController(vsync: this);
    _sacudida = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _rellenoHover = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _relleno.dispose();
    _sacudida.dispose();
    _rellenoHover.dispose();
    super.dispose();
  }

  Future<void> _manejarTap() async {
    if (_cargando) return;

    final esValido = widget.validar();
    if (!esValido) {
      _sacudida.forward(from: 0);
      return;
    }

    setState(() => _cargando = true);

    // El llenado dura 900ms; si el login real demora más, el agua
    // se queda llena esperando en vez de completarse antes de tiempo.
    _relleno.duration = const Duration(milliseconds: 900);
    final animacionLlenado = _relleno.forward(from: 0);
    final exito = await widget.onIngresar();
    await animacionLlenado;

    if (!mounted) return;

    if (exito) {
      widget.onExito();
    } else {
      setState(() => _cargando = false);
      await _relleno.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_cargando) _rellenoHover.forward();
      },
      onExit: (_) => _rellenoHover.reverse(),
      child: GestureDetector(
        onTap: _manejarTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_relleno, _sacudida, _rellenoHover]),
          builder: (context, child) {
            final progreso = _relleno.value > _rellenoHover.value
                ? _relleno.value
                : _rellenoHover.value;
            final colorTexto = Color.lerp(
              AppColors.azulNabame,
              Colors.white,
              progreso,
            )!;
            final desplazamiento =
                (16 *
                        (1 - (2 * (_sacudida.value - 0.5)).abs()) *
                        (_sacudida.value == 0
                            ? 0
                            : (_sacudida.value * 10).floor().isEven
                            ? 1
                            : -1))
                    .toDouble();
            const bordeWidth = 1.6;

            return Transform.translate(
              offset: Offset(
                _sacudida.value == 0 ? 0 : desplazamiento * 0.25,
                0,
              ),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(
                    color: _sacudida.value > 0
                        ? AppColors.negativo
                        : _rellenoHover.value > 0
                        ? AppColors.marinoNabame
                        : AppColors.azulNabame,
                    width: bordeWidth,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(bordeWidth),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(27 - bordeWidth),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progreso,
                              heightFactor: 1,
                              child: ColoredBox(color: AppColors.azulNabame),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _cargando ? 'Cargando...' : 'Ingresar',
                          style: TextStyle(
                            color: colorTexto,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (!_cargando) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: colorTexto,
                            size: 19,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
