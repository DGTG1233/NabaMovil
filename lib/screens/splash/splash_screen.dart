import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth/auth_service.dart';
import '../../theme/app_theme.dart';
import '../login/login_screen.dart';
import '../shell/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _waveController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.8, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _entryController.forward();

    final auth = context.read<AuthService>();
    Timer(const Duration(milliseconds: 2500), () => _continuar(auth));
  }

  /// Entra directo a la aplicación si hay una sesión guardada; si no, pasa
  /// por el Login. Si no se puede leer la sesión, también va al Login.
  Future<void> _continuar(AuthService auth) async {
    var hayConSesion = false;
    try {
      hayConSesion = await auth.sesionActiva();
    } catch (_) {
      // Sin acceso al almacén seguro se pide iniciar sesión de nuevo.
    }
    if (!mounted) return;

    final destino = hayConSesion ? const AppShell() : const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => destino,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.marinoNabame, AppColors.marinoOscuro],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 360,
            height: 360,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) => CustomPaint(
                    size: const Size(360, 360),
                    painter: _LogoWavePainter(_waveController.value),
                  ),
                ),
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Image.asset(
                      'assets/images/Logo1.png',
                      width: 290,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoWavePainter extends CustomPainter {
  _LogoWavePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.48;

    for (var index = 0; index < 3; index++) {
      final waveProgress = (progress + index / 3) % 1;
      final paint = Paint()
        ..color =
            AppColors.azulNabame.withValues(alpha: (1 - waveProgress) * 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(center, 46 + waveProgress * (maxRadius - 46), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}