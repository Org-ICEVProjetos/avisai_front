import 'package:avisai4/presentation/screens/home/onboarding_screen.dart';
import 'package:avisai4/presentation/screens/widgets/tutorial_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _cpfFieldKey = GlobalKey<FormFieldState>();
  final _senhaFieldKey = GlobalKey<FormFieldState>();
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideImageAnimation;
  late Animation<Offset> _slideTitleAnimation;
  late Animation<Offset> _slideSubtitleAnimation;
  late Animation<Offset> _slideFormAnimation;
  late Animation<double> _fadeInButtonAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _slideImageAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideTitleAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideSubtitleAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideFormAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
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
    _cpfController.dispose();
    _senhaController.dispose();
    _animationController.dispose();
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
    // Calcular o tamanho da imagem (90% da largura, 40% da altura, máximo 400px)
    final Size screenSize = MediaQuery.of(context).size;
    final double imageWidth =
        screenSize.width * 0.9 < 400 ? screenSize.width * 0.9 : 400.0;
    final double imageHeight =
        screenSize.height * 0.35 < 400 ? screenSize.height * 0.35 : 400.0;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthErro) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensagem),
                duration: Duration(seconds: 1),
                backgroundColor: theme.colorScheme.error,
              ),
            );
            setState(() {
              _carregando = false;
            });
          } else if (state is Autenticado) {
            // Verificar se deve mostrar o tutorial ou ir direto para a Home
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
                      const SizedBox(height: 20),

                      // Imagem principal - ilustração de login com animação
                      SlideTransition(
                        position: _slideImageAnimation,
                        child: Center(
                          child: SizedBox(
                            width: imageWidth,
                            height: imageHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.asset(
                                'assets/images/login.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: imageWidth,
                                    height: imageHeight,
                                    decoration: BoxDecoration(
                                      color: theme.primaryColorLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 80,
                                      color: theme.primaryColorDark,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Título "Login" com animação
                      SlideTransition(
                        position: _slideTitleAnimation,
                        child: Text(
                          'Login',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.primaryColor,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Subtítulo com animação
                      SlideTransition(
                        position: _slideSubtitleAnimation,
                        child: Text(
                          'Seja bem-vindo(a) de volta!',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[800],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Formulário com animação
                      SlideTransition(
                        position: _slideFormAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Campo CPF
                              Material(
                                elevation: 5,
                                borderRadius: BorderRadius.circular(30),
                                shadowColor: Colors.black.withOpacity(0.4),
                                color: Colors.white,
                                child: TextFormField(
                                  key: _cpfFieldKey,
                                  controller: _cpfController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    MaskedInputFormatter('000.000.000-00'),
                                  ],
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    // labelText: 'CPF',
                                    // labelStyle: TextStyle(
                                    //   fontWeight: FontWeight.bold,
                                    //   color: Colors.grey[500],
                                    // ),
                                    hintText: 'Digite seu CPF',
                                    hintStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  validator: _validarCPF,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final errorText =
                                      _cpfFieldKey.currentState?.errorText;
                                  if (errorText != null &&
                                      errorText.isNotEmpty) {
                                    return Align(
                                      alignment:
                                          Alignment
                                              .centerLeft, // Força alinhamento à esquerda
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left:
                                              8.0, // Um pequeno padding para não ficar colado à borda
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          errorText,
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                          textAlign:
                                              TextAlign
                                                  .left, // Garante que o texto esteja alinhado à esquerda
                                        ),
                                      ),
                                    );
                                  } else {
                                    return SizedBox.shrink();
                                  }
                                },
                              ),

                              const SizedBox(height: 20),

                              // SENHA
                              Material(
                                elevation: 5,
                                borderRadius: BorderRadius.circular(30),
                                shadowColor: Colors.black.withOpacity(0.4),
                                color: Colors.white,
                                child: TextFormField(
                                  key: _senhaFieldKey,
                                  controller: _senhaController,
                                  obscureText: !_mostrarSenha,
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    // labelText: 'Senha',
                                    // labelStyle: TextStyle(
                                    //   fontWeight: FontWeight.bold,
                                    //   color: Colors.grey[500],
                                    // ),
                                    hintText: 'Digite sua senha',
                                    hintStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[500],
                                    ),
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
                                  ),
                                  validator: _validarSenha,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final errorText =
                                      _senhaFieldKey.currentState?.errorText;
                                  if (errorText != null &&
                                      errorText.isNotEmpty) {
                                    return Align(
                                      alignment:
                                          Alignment
                                              .centerLeft, // Força alinhamento à esquerda
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left:
                                              8.0, // Um pequeno padding para não ficar colado à borda
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          errorText,
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                          textAlign:
                                              TextAlign
                                                  .left, // Garante que o texto esteja alinhado à esquerda
                                        ),
                                      ),
                                    );
                                  } else {
                                    return SizedBox.shrink();
                                  }
                                },
                              ),
                              // Link "Esqueceu a senha" (incluído no form animation)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 8.0,
                                    top: 8.0,
                                  ),
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
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.primaryColor,
                                    ),
                                    child: Text(
                                      'Esqueceu a senha?',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botão Entrar com fade-in animation
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
                                    onPressed: _fazerLogin,
                                    style: theme.elevatedButtonTheme.style
                                        ?.copyWith(
                                          shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder
                                          >(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30.0),
                                            ),
                                          ),
                                          padding: WidgetStateProperty.all<
                                            EdgeInsets
                                          >(
                                            const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                    child: Text(
                                      'Entrar',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Link para cadastro também com fade-in animation
                      FadeTransition(
                        opacity: _fadeInButtonAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Não tem uma conta?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: theme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Cadastre-se',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
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

  // Método para verificar se o tutorial deve ser mostrado e redirecionar
  Future<void> _verificarETrocarParaTutorial() async {
    await TutorialManager.verificarENavegar(
      context,
      const OnboardingScreen(),
      const HomeScreen(index: 1),
    );
  }
}
