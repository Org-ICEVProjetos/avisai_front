import 'package:avisai4/data/models/usuario.dart';
import 'package:avisai4/services/user_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../bloc/auth/auth_bloc.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Configurar animação
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // Usar um Future.delayed é mais seguro que Timer quando se trata de verificar o mounted
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Não usamos context.mounted, apenas checked o mounted da classe State
        verificarLoginAutomatico();
      }
    });
  }

  void verificarLoginAutomatico() async {
    if (!mounted) return; // Verificação de segurança adicional

    try {
      final dadosLogin = await UserLocalStorage.obterDadosLoginAutomatico();

      // Sempre verificar mounted antes de usar context
      if (!mounted) return;

      if (dadosLogin != null) {
        final usuario = dadosLogin['usuario'] as Usuario;
        context.read<AuthBloc>().add(
          LoginAutomaticoSolicitado(usuario: usuario),
        );
      } else {
        context.read<AuthBloc>().add(VerificarAutenticacao(fromSplash: true));
      }
    } catch (e) {
      print('Erro no login automático: $e');
      if (mounted) {
        context.read<AuthBloc>().add(VerificarAutenticacao(fromSplash: true));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Autenticado) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(index: 1),
              ),
            );
          } else if (state is NaoAutenticado) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              FadeTransition(
                opacity: _animation,
                child: ScaleTransition(
                  scale: _animation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.report_problem,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Título
              FadeTransition(
                opacity: _animation,
                child: const Text(
                  'Avisaí',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Subtítulo
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'Ajude a melhorar sua cidade',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Indicador de carregamento
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
