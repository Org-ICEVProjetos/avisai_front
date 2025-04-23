import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  bool _carregando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _cpfController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _recuperarSenha() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _carregando = true;
      });

      context.read<AuthBloc>().add(
            RecuperacaoSenhaSolicitada(
              cpf: _cpfController.text,
              email: _emailController.text,
            ),
          );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
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
          } else if (state is RecuperacaoSenhaEnviada) {
            setState(() {
              _carregando = false;
              _enviado = true;
            });
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ícone
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),

                    // Título
                    Text(
                      'Recuperação de Senha',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!_enviado) ...[
                      // Texto explicativo
                      Text(
                        'Informe seu CPF e e-mail cadastrado para receber as instruções de recuperação de senha.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Formulário
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                              hint: 'Digite seu e-mail cadastrado',
                              prefixIcon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validarEmail,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 32),

                            // Botão de recuperação
                            _carregando
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : CustomButton(
                                    texto: 'Recuperar Senha',
                                    onPressed: _recuperarSenha,
                                    icone: Icons.send,
                                  ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Mensagem de sucesso
                      const Icon(
                        Icons.check_circle,
                        size: 60,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Solicitação enviada com sucesso!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verifique seu e-mail para as instruções de recuperação de senha.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botão para voltar
                      CustomButton(
                        texto: 'Voltar para o Login',
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icone: Icons.arrow_back,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botão para voltar (quando o formulário está visível)
                    if (!_enviado)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Voltar para o Login'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
