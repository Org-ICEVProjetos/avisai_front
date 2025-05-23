import 'package:avisai4/presentation/screens/home/onboarding_screen.dart';
import 'package:avisai4/services/tutorial_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  final _cpfFieldKey = GlobalKey<FormFieldState>();
  final _nomeFieldKey = GlobalKey<FormFieldState>();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _senhaFieldKey = GlobalKey<FormFieldState>();
  final _confirmaSenhaFieldKey = GlobalKey<FormFieldState>();
  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmaSenha = false;
  bool _concordaTermos = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideTitleAnimation;
  late Animation<Offset> _slideSubtitleAnimation;
  late Animation<Offset> _slideForm1Animation;
  late Animation<Offset> _slideForm2Animation;
  late Animation<Offset> _slideForm3Animation;
  late Animation<Offset> _slideForm4Animation;
  late Animation<Offset> _slideForm5Animation;
  late Animation<double> _fadeInTermsAnimation;
  late Animation<double> _fadeInButtonAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Fade in animation for the whole screen
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Slide animations for each element
    _slideTitleAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideSubtitleAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    // Form field animations - staggered entries
    _slideForm1Animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideForm2Animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );

    _slideForm3Animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideForm4Animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    _slideForm5Animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );

    _fadeInTermsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 0.95, curve: Curves.easeOut),
      ),
    );

    _fadeInButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animation after short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _registrar() {
    if (_formKey.currentState!.validate() &&
        _concordaTermos &&
        _senhaController.text == _confirmaSenhaController.text) {
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
    } else if (!_concordaTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Você deve concordar com os Termos e Política de Privacidade',
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else if (_senhaController.text != _confirmaSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('As senhas devem ser iguais'),
          duration: Duration(seconds: 1),
          backgroundColor: Theme.of(context).colorScheme.error,
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthErro) {
            setState(() {
              _carregando = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensagem),
                duration: Duration(seconds: 3),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is Autenticado) {
            _verificarETrocarParaTutorial();
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 20),
                      // Título "Cadastro" com animação
                      SlideTransition(
                        position: _slideTitleAnimation,
                        child: Text(
                          'Cadastro',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            fontSize: 40,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Subtítulo com animação
                      SlideTransition(
                        position: _slideSubtitleAnimation,
                        child: Text(
                          'Ajude a melhorar sua cidade',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 42),

                      // Formulário de cadastro
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Campo Nome Completo com animação
                            SlideTransition(
                              position: _slideForm1Animation,
                              child: _buildInputField(
                                controller: _nomeController,
                                label: 'Nome Completo',
                                hint: "Digite seu nome",
                                keyboardType: TextInputType.name,
                                validator: _validarNome,
                                fieldKey: _nomeFieldKey,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Campo E-mail com animação
                            SlideTransition(
                              position: _slideForm2Animation,
                              child: _buildInputField(
                                controller: _emailController,
                                label: 'E-mail',
                                hint: "Digite seu e-mail",
                                keyboardType: TextInputType.emailAddress,
                                validator: _validarEmail,
                                fieldKey: _emailFieldKey,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Campo CPF com animação
                            SlideTransition(
                              position: _slideForm3Animation,
                              child: _buildInputField(
                                controller: _cpfController,
                                label: 'CPF',
                                hint: "Digite seu CPF",
                                keyboardType: TextInputType.number,
                                validator: _validarCPF,
                                inputFormatters: [
                                  MaskedInputFormatter('000.000.000-00'),
                                ],
                                fieldKey: _cpfFieldKey,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Campo Senha com animação
                            SlideTransition(
                              position: _slideForm4Animation,
                              child: _buildInputField(
                                controller: _senhaController,
                                label: 'Senha',
                                hint: "Digite sua senha",
                                obscureText: !_mostrarSenha,
                                validator: _validarSenha,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _mostrarSenha
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey[700],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _mostrarSenha = !_mostrarSenha;
                                    });
                                  },
                                ),
                                fieldKey: _senhaFieldKey,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Campo Confirmar Senha com animação
                            SlideTransition(
                              position: _slideForm5Animation,
                              child: _buildInputField(
                                controller: _confirmaSenhaController,
                                label: 'Confirmar Senha',
                                hint: "Confirme sua senha",
                                obscureText: !_mostrarConfirmaSenha,
                                validator: _validarConfirmaSenha,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _mostrarConfirmaSenha
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey[700],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _mostrarConfirmaSenha =
                                          !_mostrarConfirmaSenha;
                                    });
                                  },
                                ),
                                fieldKey: _confirmaSenhaFieldKey,
                              ),
                            ),

                            // Checkbox de concordância com termos com animação
                            FadeTransition(
                              opacity: _fadeInTermsAnimation,
                              child: TermsAndPolicyWidget(
                                concordaTermos: _concordaTermos,
                                onChanged: (value) {
                                  setState(() {
                                    _concordaTermos = value ?? false;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Botão de Cadastro com animação
                            FadeTransition(
                              opacity: _fadeInButtonAnimation,
                              child: SizedBox(
                                height: 60,
                                child:
                                    _carregando
                                        ? Center(
                                          child: CircularProgressIndicator(
                                            color: theme.primaryColor,
                                          ),
                                        )
                                        : ElevatedButton(
                                          onPressed: _registrar,
                                          style: theme.elevatedButtonTheme.style
                                              ?.copyWith(
                                                shape: WidgetStateProperty.all<
                                                  RoundedRectangleBorder
                                                >(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          30.0,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                          child: Text(
                                            'Cadastrar',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Link para Login com a mesma animação que o botão
                            FadeTransition(
                              opacity: _fadeInButtonAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Já tem uma conta?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Entrar',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
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

  // Método auxiliar para criar campos de entrada padronizados
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    GlobalKey<FormFieldState>? fieldKey,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Material(
          elevation: 5, // Aqui você controla a sombra como no Card
          borderRadius: BorderRadius.circular(30), // Bordas arredondadas
          shadowColor: Colors.black.withOpacity(0.4), // Cor da sombra
          color: Colors.white, // Fundo branco
          child: TextFormField(
            key: fieldKey,
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            inputFormatters: inputFormatters,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              // labelText: label,
              // labelStyle: TextStyle(
              //   fontWeight: FontWeight.bold,
              //   color: Colors.grey[500],
              // ),
              hintText: hint,
              hintStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              suffixIcon: suffixIcon,
              fillColor: Colors.white,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        Builder(
          builder: (context) {
            final erroText = fieldKey?.currentState?.errorText;
            if (erroText != null && erroText.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                child: Text(
                  erroText,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  // Método para verificar se o tutorial deve ser mostrado e redirecionar
  Future<void> _verificarETrocarParaTutorial() async {
    await TutorialManager.verificarENavegar(
      context,
      const OnboardingScreen(),
      const HomeScreen(index: 1),
    );
  }
}

class TermsAndPolicyWidget extends StatelessWidget {
  final bool concordaTermos;
  final Function(bool?) onChanged;

  const TermsAndPolicyWidget({
    Key? key,
    required this.concordaTermos,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Checkbox(
          value: concordaTermos,
          onChanged: onChanged,
          activeColor: theme.primaryColor,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
              children: [
                const TextSpan(text: 'Li e concordo com os '),
                TextSpan(
                  text: 'Termos',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          _mostrarDialogoTermos(context, true);
                        },
                ),
                const TextSpan(text: ' e '),
                TextSpan(
                  text: 'Política de Privacidade',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          _mostrarDialogoTermos(context, false);
                        },
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoTermos(BuildContext context, bool isTermos) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isTermos ? 'Termos de Uso' : 'Política de Privacidade'),
          content: SingleChildScrollView(
            child: Text(
              isTermos
                  ? 'Aqui iriam os termos de uso...' // Substitua pelo texto real dos termos
                  : 'Política de Privacidade\n\n'
                      'Este aplicativo coleta e armazena dados pessoais fornecidos voluntariamente pelo usuário, '
                      'incluindo nome, CPF, e-mail e senha. Esses dados são usados para autenticação, '
                      'identificação e controle de acesso aos recursos do app.\n\n'
                      'Além disso, os registros criados pelos usuários dentro da aplicação podem ser acessados '
                      'por administradores autorizados com o objetivo de garantir o funcionamento adequado do '
                      'sistema e prestar suporte.\n\n'
                      'Todas as informações são armazenadas em banco de dados seguro. Apenas administradores '
                      'autorizados têm acesso a essas informações para fins operacionais, e nenhum dado é '
                      'compartilhado com terceiros sem o consentimento do usuário, salvo em casos previstos por lei.\n\n'
                      'O usuário pode entrar em contato conosco a qualquer momento para esclarecimentos, '
                      'solicitações de exclusão de conta ou informações sobre os dados armazenados.\n\n'
                      'E-mail de contato: avisaithepi@gmail.com',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
