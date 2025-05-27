import 'package:avisai4/presentation/screens/auth/change_password_screen.dart';
import 'package:avisai4/presentation/screens/auth/verificar_token_password.dart';
import 'package:avisai4/presentation/screens/mapa/detalhes_registro_screen.dart';
import 'package:flutter/material.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/mapa/mapa_irregularidades_screen.dart';
import '../presentation/screens/registro/novo_registro_screen.dart';
import '../presentation/screens/registro/meus_registros_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/splash': (context) => const SplashScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/forgot-password': (context) => const ForgotPasswordScreen(),
  '/verify-token': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return VerifyTokenScreen(cpf: args['cpf'], email: args['email']);
  },
  '/change-password': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return ChangePasswordScreen(token: args['token']);
  },
  '/home': (context) => const HomeScreen(index: 1),
  '/registro/novo': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return NovoRegistroScreen(
      usuarioId: args['usuarioId'],
      usuarioNome: args['usuarioNome'],
    );
  },
  '/registro/meus': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return MeusRegistrosScreen(usuarioId: args['usuarioId']);
  },
  '/registro/detalhe': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return DetalheRegistroScreen(registro: args['registro']);
  },
  '/mapa': (context) => const MapaIrregularidadesScreen(),
};
