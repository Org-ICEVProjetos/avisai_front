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
  '/home': (context) => const HomeScreen(),
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

class AppNavigator {
  static void navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.of(context).pushNamed('/register');
  }

  static void navigateToForgotPassword(BuildContext context) {
    Navigator.of(context).pushNamed('/forgot-password');
  }

  static void navigateToNovoRegistro(
    BuildContext context, {
    required String usuarioId,
    required String usuarioNome,
  }) {
    Navigator.of(context).pushNamed(
      '/registro/novo',
      arguments: {'usuarioId': usuarioId, 'usuarioNome': usuarioNome},
    );
  }

  static void navigateToMeusRegistros(
    BuildContext context, {
    required String usuarioId,
  }) {
    Navigator.of(
      context,
    ).pushNamed('/registro/meus', arguments: {'usuarioId': usuarioId});
  }

  static void navigateToDetalheRegistro(
    BuildContext context, {
    required dynamic registro,
  }) {
    Navigator.of(
      context,
    ).pushNamed('/registro/detalhe', arguments: {'registro': registro});
  }

  static void navigateToMapa(BuildContext context) {
    Navigator.of(context).pushNamed('/mapa');
  }

  static void goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  static void goBackToHome(BuildContext context) {
    Navigator.of(context).popUntil(ModalRoute.withName('/home'));
  }
}
