import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/auth/auth_service.dart';
import 'data/datasource/data_source.dart';
import 'data/datasource/mock_data_source.dart';
import 'data/repositories/morosidad_repository.dart';
import 'data/repositories/notificaciones_repository.dart';
import 'data/repositories/pago_repository.dart';
import 'data/repositories/venta_repository.dart';
import 'screens/avisos/avisos_controller.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_PE', null);
  runApp(const NabameApp());
}

class NabameApp extends StatelessWidget {
  const NabameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DataSource>(create: (_) => MockDataSource()),
        ProxyProvider<DataSource, VentaRepository>(
          update: (_, dataSource, _) => VentaRepository(dataSource),
        ),
        ProxyProvider<DataSource, MorosidadRepository>(
          update: (_, dataSource, _) => MorosidadRepository(dataSource),
        ),
        ProxyProvider<DataSource, PagoRepository>(
          update: (_, dataSource, _) => PagoRepository(dataSource),
        ),
        ProxyProvider<DataSource, NotificacionesRepository>(
          update: (_, dataSource, _) => NotificacionesRepository(dataSource),
        ),
        ChangeNotifierProvider<AvisosController>(
          create: (_) => AvisosController(),
        ),
      ],
      child: MaterialApp(
        title: 'NABAME Móvil',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.tema.copyWith(
          textTheme: GoogleFonts.interTextTheme(AppTheme.tema.textTheme),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}