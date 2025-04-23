import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _fazerLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _carregando = true;
      });

      context.read<AuthBloc>().add(
        LoginSolicitado(cpf: _cpfController.text, senha: _senhaController.text),
      );
    }
  }

  String? _validarCPF(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Por favor, digite seu CPF';
    }

    final cpf = valor.replaceAll(RegExp(r'[^\d]'), '');

    if (cpf.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    return null;
  }

  String? _validarSenha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Por favor, digite sua senha';
    }

    if (valor.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthErro) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensagem),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _carregando = false;
            });
          } else if (state is Autenticado) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo e título
                      Icon(
                        Icons.report_problem,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Avisaí',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajude a melhorar sua cidade',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 40),

                      // Formulário de login
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomInput(
                              controller: _cpfController,
                              label: 'CPF',
                              hint: 'Digite seu CPF',
                              prefixIcon: Icons.person,
                              keyboardType: TextInputType.number,
                              validator: _validarCPF,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              inputFormatters: const [],
                            ),
                            const SizedBox(height: 16),
                            CustomInput(
                              controller: _senhaController,
                              label: 'Senha',
                              hint: 'Digite sua senha',
                              prefixIcon: Icons.lock,
                              obscureText: !_mostrarSenha,
                              validator: _validarSenha,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _mostrarSenha
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _mostrarSenha = !_mostrarSenha;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Esqueceu a senha
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Esqueceu a senha?'),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Botão de login
                            _carregando
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : CustomButton(
                                  texto: 'Entrar',
                                  onPressed: _fazerLogin,
                                  icone: Icons.login,
                                ),
                            const SizedBox(height: 24),

                            // Registro
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Não tem conta?'),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Cadastre-se'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
