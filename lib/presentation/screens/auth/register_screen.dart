import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';

import '../home/home_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmaSenha = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    super.dispose();
  }

  void _registrar() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _carregando = true;
      });

      context.read<AuthBloc>().add(
            RegistroSolicitado(
              nome: _nomeController.text,
              cpf: _cpfController.text,
              email: _emailController.text,
              senha: _senhaController.text,
            ),
          );
    }
  }

  String? _validarNome(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Por favor, digite seu nome';
    }

    if (valor.length < 3) {
      return 'O nome deve ter pelo menos 3 caracteres';
    }

    return null;
  }

  String? _validarCPF(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Por favor, digite seu CPF';
    }

    // Remover caracteres especiais
    final cpf = valor.replaceAll(RegExp(r'[^\d]'), '');

    if (cpf.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    // Validação simplificada, em um app real deveria ter validação completa
    return null;
  }

  String? _validarEmail(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Por favor, digite seu e-mail';
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(valor)) {
      return 'Digite um e-mail válido';
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

  String? _validarConfirmaSenha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Por favor, confirme sua senha';
    }

    if (valor != _senhaController.text) {
      return 'As senhas não conferem';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthErro) {
            setState(() {
              _carregando = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensagem),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is Autenticado) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
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
                      // Título
                      Text(
                        'Crie sua conta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha os campos abaixo para se cadastrar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Formulário de cadastro
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomInput(
                              controller: _nomeController,
                              label: 'Nome completo',
                              hint: 'Digite seu nome completo',
                              prefixIcon: Icons.person,
                              keyboardType: TextInputType.name,
                              validator: _validarNome,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 16),
                            CustomInput(
                              controller: _cpfController,
                              label: 'CPF',
                              hint: 'Digite seu CPF',
                              prefixIcon: Icons.badge,
                              keyboardType: TextInputType.number,
                              validator: _validarCPF,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              inputFormatters: [
                                // Aqui poderia adicionar formatadores para CPF
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CustomInput(
                              controller: _emailController,
                              label: 'E-mail',
                              hint: 'Digite seu e-mail',
                              prefixIcon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validarEmail,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
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
                            const SizedBox(height: 16),
                            CustomInput(
                              controller: _confirmaSenhaController,
                              label: 'Confirmar senha',
                              hint: 'Confirme sua senha',
                              prefixIcon: Icons.lock_outline,
                              obscureText: !_mostrarConfirmaSenha,
                              validator: _validarConfirmaSenha,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _mostrarConfirmaSenha
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _mostrarConfirmaSenha =
                                        !_mostrarConfirmaSenha;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Botão de cadastro
                            _carregando
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : CustomButton(
                                    texto: 'Cadastrar',
                                    onPressed: _registrar,
                                    icone: Icons.app_registration,
                                  ),
                            const SizedBox(height: 24),

                            // Voltar para login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Já tem conta?'),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Entrar'),
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
