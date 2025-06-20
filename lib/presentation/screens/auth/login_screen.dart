import 'package:avisai4/presentation/screens/home/onboarding_screen.dart';
import 'package:avisai4/services/tutorial_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../home/home_screen.dart';

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
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // Detecta diferentes tipos de tela
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isTablet = screenWidth > 600;

    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthErro) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.mensagem),
                  duration: Duration(seconds: 3),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
              setState(() {
                _carregando = false;
              });
            } else if (state is Autenticado) {
              _verificarETrocarParaTutorial();
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 48.0 : 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Seção superior com imagem e título
                        if (!isKeyboardVisible || !isVerySmallScreen) ...[
                          SizedBox(
                            height:
                                isVerySmallScreen
                                    ? 8
                                    : (isSmallScreen ? 16 : 32),
                          ),

                          // Imagem - reduzida quando teclado visível
                          SlideTransition(
                            position: _slideImageAnimation,
                            child: Center(
                              child: SizedBox(
                                height: _getImageHeight(
                                  isSmallScreen,
                                  isVerySmallScreen,
                                  isKeyboardVisible,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Image.asset(
                                    'assets/images/login.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: _getImageHeight(
                                          isSmallScreen,
                                          isVerySmallScreen,
                                          isKeyboardVisible,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColorLight,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size:
                                              _getImageHeight(
                                                isSmallScreen,
                                                isVerySmallScreen,
                                                isKeyboardVisible,
                                              ) *
                                              0.3,
                                          color: theme.primaryColorDark,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 8 : 16),
                        ],

                        // Título - sempre visível, mas menor quando teclado ativo
                        SlideTransition(
                          position: _slideTitleAnimation,
                          child: Text(
                            'Login',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: theme.primaryColor,
                              fontSize: _getTitleFontSize(
                                isSmallScreen,
                                isVerySmallScreen,
                                isKeyboardVisible,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Subtítulo - oculto quando teclado ativo em telas pequenas
                        if (!isKeyboardVisible || !isVerySmallScreen) ...[
                          SlideTransition(
                            position: _slideSubtitleAnimation,
                            child: Text(
                              'Seja bem-vindo(a) de volta!',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[800],
                                fontSize:
                                    isVerySmallScreen
                                        ? 12
                                        : (isSmallScreen ? 14 : 16),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        SizedBox(
                          height:
                              isKeyboardVisible
                                  ? 16
                                  : (isVerySmallScreen ? 16 : 24),
                        ),

                        // Formulário - sempre visível e acessível
                        SlideTransition(
                          position: _slideFormAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Campo CPF
                                _buildTextField(
                                  key: _cpfFieldKey,
                                  controller: _cpfController,
                                  hintText: 'Digite seu CPF',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    MaskedInputFormatter('000.000.000-00'),
                                  ],
                                  validator: _validarCPF,
                                  theme: theme,
                                  isSmallScreen: isVerySmallScreen,
                                ),

                                SizedBox(height: isVerySmallScreen ? 12 : 16),

                                // Campo Senha
                                _buildTextField(
                                  key: _senhaFieldKey,
                                  controller: _senhaController,
                                  hintText: 'Digite sua senha',
                                  obscureText: !_mostrarSenha,
                                  validator: _validarSenha,
                                  theme: theme,
                                  isSmallScreen: isVerySmallScreen,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _mostrarSenha
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey[700],
                                      size: isVerySmallScreen ? 20 : 24,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _mostrarSenha = !_mostrarSenha;
                                      });
                                    },
                                  ),
                                ),

                                // Esqueceu a senha - sempre visível
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      right: 8.0,
                                      top: 8.0,
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pushNamed('/forgot-password');
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: theme.primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      child: Text(
                                        'Esqueceu a senha?',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: Colors.grey[800],
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  isVerySmallScreen ? 11 : 13,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Espaço flexível para empurrar botão para baixo
                        SizedBox(height: isKeyboardVisible ? 20 : 32),

                        // Botão de login - sempre visível
                        FadeTransition(
                          opacity: _fadeInButtonAnimation,
                          child: SizedBox(
                            width: double.infinity,
                            height: isVerySmallScreen ? 48 : 56,
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
                                                    BorderRadius.circular(28.0),
                                              ),
                                            ),
                                            padding: WidgetStateProperty.all<
                                              EdgeInsets
                                            >(
                                              EdgeInsets.symmetric(
                                                vertical:
                                                    isVerySmallScreen ? 12 : 16,
                                              ),
                                            ),
                                          ),
                                      child: Text(
                                        'Entrar',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontSize:
                                                  isVerySmallScreen ? 16 : 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Rodapé com cadastro - sempre visível
                        FadeTransition(
                          opacity: _fadeInButtonAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Não tem uma conta?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: isVerySmallScreen ? 12 : 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/register');
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
                                  'Cadastre-se',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isKeyboardVisible ? 16 : 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required GlobalKey<FormFieldState> key,
    required TextEditingController controller,
    required String hintText,
    required ThemeData theme,
    required bool isSmallScreen,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(28),
          shadowColor: Colors.black.withOpacity(0.1),
          color: Colors.white,
          child: TextFormField(
            key: key,
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: isSmallScreen ? 14 : 16,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
                fontSize: isSmallScreen ? 14 : 16,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 14 : 16,
              ),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        // Erro do campo
        Builder(
          builder: (context) {
            final errorText = key.currentState?.errorText;
            if (errorText != null && errorText.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                child: Text(
                  errorText,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  double _getImageHeight(
    bool isSmallScreen,
    bool isVerySmallScreen,
    bool isKeyboardVisible,
  ) {
    if (isKeyboardVisible && isVerySmallScreen) return 0;
    if (isKeyboardVisible) return 120;
    if (isVerySmallScreen) return 200;
    if (isSmallScreen) return 280;
    return 350;
  }

  double _getTitleFontSize(
    bool isSmallScreen,
    bool isVerySmallScreen,
    bool isKeyboardVisible,
  ) {
    if (isKeyboardVisible && isVerySmallScreen) return 22;
    if (isVerySmallScreen) return 28;
    if (isSmallScreen) return 32;
    return 38;
  }

  Future<void> _verificarETrocarParaTutorial() async {
    await TutorialManager.verificarENavegar(
      context,
      const OnboardingScreen(),
      const HomeScreen(index: 1),
    );
  }
}
