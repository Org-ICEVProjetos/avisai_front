import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import '../../../bloc/auth/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _cpfFieldKey = GlobalKey<FormFieldState>();
  bool _carregando = false;
  bool _enviado = false;

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideTextAnimation;
  late Animation<Offset> _slideForm1Animation;
  late Animation<Offset> _slideForm2Animation;
  late Animation<Offset> _slideButtonAnimation;
  late Animation<Offset> _slideImageAnimation;
  late Animation<double> _fadeSuccessAnimation;

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

    _slideTextAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideForm1Animation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideForm2Animation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideButtonAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );

    _slideImageAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeSuccessAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _emailController.dispose();
    _animationController.dispose();
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
    final cpf = valor.replaceAll(RegExp(r'[^\d]'), '');
    if (cpf.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthErro) {
            setState(() {
              _carregando = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensagem),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is RecuperacaoSenhaEnviada) {
            setState(() {
              _carregando = false;
              _enviado = true;
            });

            Navigator.of(context).pushReplacementNamed(
              '/verify-token',
              arguments: {
                'cpf': _cpfController.text,
                'email': _emailController.text,
              },
            );

            _animationController.reset();
            _animationController.forward();
          }
        },
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: Column(
              children: [
                // AppBar customizada
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48.0 : 24.0,
                    vertical: isVerySmallScreen ? 8.0 : 16.0,
                  ),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size:
                              isVerySmallScreen
                                  ? 22
                                  : (isSmallScreen ? 24 : 28),
                          color: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Recuperar senha',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: _getAppBarTitleSize(
                            isSmallScreen,
                            isVerySmallScreen,
                            isKeyboardVisible,
                          ),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),

                // Conteúdo principal
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 48.0 : 24.0,
                      ),
                      child:
                          !_enviado
                              ? _buildFormScreen(
                                theme,
                                isSmallScreen,
                                isVerySmallScreen,
                                isKeyboardVisible,
                                screenWidth,
                              )
                              : _buildSuccessScreen(
                                theme,
                                isSmallScreen,
                                isVerySmallScreen,
                                screenWidth,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormScreen(
    ThemeData theme,
    bool isSmallScreen,
    bool isVerySmallScreen,
    bool isKeyboardVisible,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Espaço no topo
        SizedBox(
          height: isKeyboardVisible ? 12 : (isVerySmallScreen ? 16 : 24),
        ),

        // Texto explicativo - menor quando teclado ativo
        if (!isKeyboardVisible || !isVerySmallScreen) ...[
          SlideTransition(
            position: _slideTextAnimation,
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: _getDescriptionFontSize(
                    isSmallScreen,
                    isVerySmallScreen,
                    isKeyboardVisible,
                  ),
                  color: Colors.grey[800],
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Para recuperar sua senha, insira corretamente seu ',
                  ),
                  TextSpan(
                    text: 'e-mail',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' de acesso e '),
                  TextSpan(
                    text: 'CPF',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        '. Um link para redefinição será enviado para o e-mail informado.',
                  ),
                ],
              ),
            ),
          ),
        ],

        SizedBox(
          height: isKeyboardVisible ? 16 : (isVerySmallScreen ? 24 : 32),
        ),

        // Formulário
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Campo CPF
              SlideTransition(
                position: _slideForm1Animation,
                child: _buildInputField(
                  controller: _cpfController,
                  label: 'CPF',
                  hint: "Digite seu CPF",
                  keyboardType: TextInputType.number,
                  validator: _validarCPF,
                  inputFormatters: [MaskedInputFormatter('000.000.000-00')],
                  fieldKey: _cpfFieldKey,
                  isSmallScreen: isVerySmallScreen,
                ),
              ),
              SizedBox(
                height: _getFieldSpacing(isVerySmallScreen, isKeyboardVisible),
              ),

              // Campo Email
              SlideTransition(
                position: _slideForm2Animation,
                child: _buildInputField(
                  controller: _emailController,
                  label: 'E-mail',
                  hint: "Digite seu e-mail",
                  keyboardType: TextInputType.emailAddress,
                  validator: _validarEmail,
                  fieldKey: _emailFieldKey,
                  isSmallScreen: isVerySmallScreen,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: isKeyboardVisible ? 20 : (isVerySmallScreen ? 24 : 32),
        ),

        // Botão de recuperar senha
        SlideTransition(
          position: _slideButtonAnimation,
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
                    : ElevatedButton.icon(
                      onPressed: _recuperarSenha,
                      icon: Icon(Icons.send, size: isVerySmallScreen ? 18 : 20),
                      label: Text(
                        'Recuperar Senha',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isVerySmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF022865),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
          ),
        ),

        // Imagem - adaptada ou oculta quando teclado ativo
        if (!isKeyboardVisible) ...[
          SizedBox(height: isVerySmallScreen ? 32 : 48),
          SlideTransition(
            position: _slideImageAnimation,
            child: Center(
              child: SizedBox(
                width: _getImageWidth(screenWidth, isVerySmallScreen),
                height: _getImageHeight(isSmallScreen, isVerySmallScreen),
                child: Image.asset(
                  'assets/images/recuperacao_senha.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.primaryColorLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        size:
                            _getImageHeight(isSmallScreen, isVerySmallScreen) *
                            0.3,
                        color: theme.primaryColorDark,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],

        SizedBox(height: isKeyboardVisible ? 16 : 24),
      ],
    );
  }

  Widget _buildSuccessScreen(
    ThemeData theme,
    bool isSmallScreen,
    bool isVerySmallScreen,
    double screenWidth,
  ) {
    return FadeTransition(
      opacity: _fadeSuccessAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: isVerySmallScreen ? 20 : 32),

          // Ícone de sucesso
          Icon(
            Icons.check_circle,
            size: isVerySmallScreen ? 60 : (isSmallScreen ? 70 : 80),
            color: Colors.green,
          ),

          SizedBox(height: isVerySmallScreen ? 16 : 24),

          // Título de sucesso
          Text(
            'Solicitação enviada com sucesso!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 24),
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontFamily: 'Inter',
            ),
          ),

          SizedBox(height: isVerySmallScreen ? 12 : 16),

          // Descrição
          Text(
            'Verifique seu e-mail para as instruções de recuperação de senha.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
              color: Colors.grey[700],
              fontFamily: 'Inter',
              height: 1.4,
            ),
          ),

          SizedBox(height: isVerySmallScreen ? 24 : 32),

          // Imagem de sucesso
          SizedBox(
            width: _getImageWidth(screenWidth, isVerySmallScreen),
            height: _getSuccessImageHeight(isSmallScreen, isVerySmallScreen),
            child: Image.asset(
              'assets/images/email_enviado.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mark_email_read,
                    size:
                        _getSuccessImageHeight(
                          isSmallScreen,
                          isVerySmallScreen,
                        ) *
                        0.3,
                    color: theme.primaryColorDark,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: isVerySmallScreen ? 32 : 48),

          // Botão de voltar
          SizedBox(
            width: double.infinity,
            height: isVerySmallScreen ? 48 : 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.arrow_back, size: isVerySmallScreen ? 18 : 20),
              label: Text(
                'Voltar para o Login',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isVerySmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF022865),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 2,
              ),
            ),
          ),

          SizedBox(height: isVerySmallScreen ? 16 : 24),
        ],
      ),
    );
  }

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
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(28),
          shadowColor: Colors.black.withOpacity(0.1),
          color: Colors.white,
          child: TextFormField(
            key: fieldKey,
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            inputFormatters: inputFormatters,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: isSmallScreen ? 14 : 16,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
                fontSize: isSmallScreen ? 14 : 16,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
                fontSize: isSmallScreen ? 14 : 16,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isSmallScreen ? 14 : 16,
              ),
              border: InputBorder.none,
              floatingLabelBehavior: FloatingLabelBehavior.never,
              suffixIcon: suffixIcon,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        // Erro do campo
        Builder(
          builder: (context) {
            final errorText = fieldKey?.currentState?.errorText;
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

  // Funções auxiliares para dimensionamento responsivo
  double _getAppBarTitleSize(
    bool isSmallScreen,
    bool isVerySmallScreen,
    bool isKeyboardVisible,
  ) {
    if (isKeyboardVisible && isVerySmallScreen) return 18;
    if (isVerySmallScreen) return 20;
    if (isSmallScreen) return 24;
    return 28;
  }

  double _getDescriptionFontSize(
    bool isSmallScreen,
    bool isVerySmallScreen,
    bool isKeyboardVisible,
  ) {
    if (isKeyboardVisible && isVerySmallScreen) return 14;
    if (isVerySmallScreen) return 16;
    if (isSmallScreen) return 18;
    return 20;
  }

  double _getFieldSpacing(bool isVerySmallScreen, bool isKeyboardVisible) {
    if (isKeyboardVisible && isVerySmallScreen) return 14;
    if (isVerySmallScreen) return 16;
    return 20;
  }

  double _getImageWidth(double screenWidth, bool isVerySmallScreen) {
    if (isVerySmallScreen) return screenWidth * 0.7;
    return screenWidth * 0.8;
  }

  double _getImageHeight(bool isSmallScreen, bool isVerySmallScreen) {
    if (isVerySmallScreen) return 150;
    if (isSmallScreen) return 200;
    return 250;
  }

  double _getSuccessImageHeight(bool isSmallScreen, bool isVerySmallScreen) {
    if (isVerySmallScreen) return 180;
    if (isSmallScreen) return 220;
    return 280;
  }
}
