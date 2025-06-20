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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

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
          duration: Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else if (_senhaController.text != _confirmaSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('As senhas devem ser iguais'),
          duration: Duration(seconds: 2),
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
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48.0 : 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Espaço no topo
                      SizedBox(
                        height:
                            isKeyboardVisible
                                ? 8
                                : (isVerySmallScreen ? 16 : 24),
                      ),

                      // Título - menor quando teclado ativo
                      SlideTransition(
                        position: _slideTitleAnimation,
                        child: Text(
                          'Cadastro',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            fontSize: _getTitleFontSize(
                              isSmallScreen,
                              isVerySmallScreen,
                              isKeyboardVisible,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Subtítulo - oculto quando teclado ativo em telas pequenas
                      if (!isKeyboardVisible || !isVerySmallScreen) ...[
                        SlideTransition(
                          position: _slideSubtitleAnimation,
                          child: Text(
                            'Ajude a melhorar sua cidade',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  isVerySmallScreen
                                      ? 12
                                      : (isSmallScreen ? 14 : 16),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      SizedBox(
                        height:
                            isKeyboardVisible
                                ? 12
                                : (isVerySmallScreen ? 20 : 32),
                      ),

                      // Formulário
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Campo Nome
                            SlideTransition(
                              position: _slideForm1Animation,
                              child: _buildInputField(
                                controller: _nomeController,
                                hint: "Digite seu nome completo",
                                keyboardType: TextInputType.name,
                                validator: _validarNome,
                                fieldKey: _nomeFieldKey,
                                isSmallScreen: isVerySmallScreen,
                              ),
                            ),
                            SizedBox(
                              height: _getFieldSpacing(
                                isVerySmallScreen,
                                isKeyboardVisible,
                              ),
                            ),

                            // Campo Email
                            SlideTransition(
                              position: _slideForm2Animation,
                              child: _buildInputField(
                                controller: _emailController,
                                hint: "Digite seu e-mail",
                                keyboardType: TextInputType.emailAddress,
                                validator: _validarEmail,
                                fieldKey: _emailFieldKey,
                                isSmallScreen: isVerySmallScreen,
                              ),
                            ),
                            SizedBox(
                              height: _getFieldSpacing(
                                isVerySmallScreen,
                                isKeyboardVisible,
                              ),
                            ),

                            // Campo CPF
                            SlideTransition(
                              position: _slideForm3Animation,
                              child: _buildInputField(
                                controller: _cpfController,
                                hint: "Digite seu CPF",
                                keyboardType: TextInputType.number,
                                validator: _validarCPF,
                                inputFormatters: [
                                  MaskedInputFormatter('000.000.000-00'),
                                ],
                                fieldKey: _cpfFieldKey,
                                isSmallScreen: isVerySmallScreen,
                              ),
                            ),
                            SizedBox(
                              height: _getFieldSpacing(
                                isVerySmallScreen,
                                isKeyboardVisible,
                              ),
                            ),

                            // Campo Senha
                            SlideTransition(
                              position: _slideForm4Animation,
                              child: _buildInputField(
                                controller: _senhaController,
                                hint: "Digite sua senha",
                                obscureText: !_mostrarSenha,
                                validator: _validarSenha,
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
                                fieldKey: _senhaFieldKey,
                                isSmallScreen: isVerySmallScreen,
                              ),
                            ),
                            SizedBox(
                              height: _getFieldSpacing(
                                isVerySmallScreen,
                                isKeyboardVisible,
                              ),
                            ),

                            // Campo Confirmar Senha
                            SlideTransition(
                              position: _slideForm5Animation,
                              child: _buildInputField(
                                controller: _confirmaSenhaController,
                                hint: "Confirme sua senha",
                                obscureText: !_mostrarConfirmaSenha,
                                validator: _validarConfirmaSenha,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _mostrarConfirmaSenha
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey[700],
                                    size: isVerySmallScreen ? 20 : 24,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _mostrarConfirmaSenha =
                                          !_mostrarConfirmaSenha;
                                    });
                                  },
                                ),
                                fieldKey: _confirmaSenhaFieldKey,
                                isSmallScreen: isVerySmallScreen,
                              ),
                            ),

                            SizedBox(
                              height: _getFieldSpacing(
                                isVerySmallScreen,
                                isKeyboardVisible,
                              ),
                            ),

                            // Termos e Política
                            FadeTransition(
                              opacity: _fadeInTermsAnimation,
                              child: TermsAndPolicyWidget(
                                concordaTermos: _concordaTermos,
                                onChanged: (value) {
                                  setState(() {
                                    _concordaTermos = value ?? false;
                                  });
                                },
                                isSmallScreen: isSmallScreen,
                                isVerySmallScreen: isVerySmallScreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isKeyboardVisible ? 16 : 24),

                      // Botão de cadastrar
                      FadeTransition(
                        opacity: _fadeInButtonAnimation,
                        child: SizedBox(
                          height: isVerySmallScreen ? 48 : 56,
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
                                                  BorderRadius.circular(28.0),
                                            ),
                                          ),
                                        ),
                                    child: Text(
                                      'Cadastrar',
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

                      // Rodapé com login
                      FadeTransition(
                        opacity: _fadeInButtonAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Já tem uma conta?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: isVerySmallScreen ? 12 : 14,
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Entrar',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
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
              hintText: hint,
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

  double _getTitleFontSize(
    bool isSmallScreen,
    bool isVerySmallScreen,
    bool isKeyboardVisible,
  ) {
    if (isKeyboardVisible && isVerySmallScreen) return 24;
    if (isVerySmallScreen) return 28;
    if (isSmallScreen) return 32;
    return 38;
  }

  double _getFieldSpacing(bool isVerySmallScreen, bool isKeyboardVisible) {
    if (isKeyboardVisible && isVerySmallScreen) return 12;
    if (isVerySmallScreen) return 16;
    return 20;
  }

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
  final bool isSmallScreen;
  final bool isVerySmallScreen;

  const TermsAndPolicyWidget({
    super.key,
    required this.concordaTermos,
    required this.onChanged,
    required this.isSmallScreen,
    required this.isVerySmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.scale(
          scale: isVerySmallScreen ? 0.8 : (isSmallScreen ? 0.9 : 1.0),
          child: Checkbox(
            value: concordaTermos,
            onChanged: onChanged,
            activeColor: theme.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
                ),
                children: [
                  const TextSpan(text: 'Li e concordo com os '),
                  TextSpan(
                    text: 'Termos',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      fontSize:
                          isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
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
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      fontSize:
                          isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
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
                  ? 'Termos de Uso do Aplicativo\n\n'
                      'Estes Termos de Uso regulam o uso do aplicativo por parte dos usuários e estabelecem os '
                      'direitos e deveres das partes. Ao utilizar o aplicativo, o usuário concorda com estes termos.\n\n'
                      '1. Aceitação dos Termos\n'
                      'Ao acessar ou usar este aplicativo, o usuário declara que leu, entendeu e concorda com os '
                      'presentes Termos de Uso e com a Política de Privacidade. Caso não concorde, o usuário '
                      'deve desinstalar o aplicativo e interromper seu uso imediatamente.\n\n'
                      '2. Cadastro e Conta do Usuário\n'
                      'Para utilizar as funcionalidades do aplicativo, o usuário deve criar uma conta, fornecendo:\n'
                      '• Nome completo\n'
                      '• CPF\n'
                      '• E-mail\n'
                      '• Senha\n\n'
                      'O usuário se compromete a fornecer informações verídicas, completas e atualizadas.\n\n'
                      '3. Responsabilidades do Usuário\n'
                      'O usuário se compromete a:\n'
                      '• Utilizar o aplicativo de forma lícita, ética e responsável;\n'
                      '• Não compartilhar sua conta com terceiros;\n'
                      '• Não enviar informações falsas, ofensivas, ilícitas ou que infrinjam direitos de terceiros;\n'
                      '• Manter a confidencialidade da sua senha.\n\n'
                      '3.1. Conteúdo Inadequado ou Fora do Escopo\n'
                      'O usuário não deve utilizar o aplicativo para enviar conteúdos que não estejam '
                      'relacionados ao propósito principal da plataforma, como o registro de buracos nas vias '
                      'públicas ou problemas urbanos. É proibido o envio de mensagens promocionais, denúncias '
                      'não relacionadas, opiniões pessoais, propagandas, ou qualquer outro conteúdo que fuja ao '
                      'escopo do aplicativo.\n\n'
                      '4. Funcionalidades do Aplicativo\n'
                      'O aplicativo permite:\n'
                      '• Envio de registros contendo dados de localização e imagens;\n'
                      '• Anexar fotos tiradas no momento;\n'
                      '• Armazenamento seguro das informações enviadas;\n'
                      '• Visualização e gestão dos próprios registros.\n\n'
                      '5. Permissões Requeridas\n'
                      'Para seu pleno funcionamento, o aplicativo pode solicitar permissões de:\n'
                      '• Localização: para registrar a posição geográfica dos eventos;\n'
                      '• Câmera: para permitir a captura de imagens em tempo real;\n\n'
                      'As permissões são solicitadas com o consentimento do usuário e podem ser desativadas a '
                      'qualquer momento nas configurações do dispositivo.\n\n'
                      '6. Propriedade Intelectual\n'
                      'Todos os direitos relativos ao aplicativo, incluindo textos, imagens, códigos e '
                      'funcionalidades, são de propriedade da equipe desenvolvedora, sendo vedada a '
                      'reprodução, cópia ou modificação sem autorização prévia.\n\n'
                      '7. Limitação de Responsabilidade\n'
                      'O aplicativo é fornecido "como está", não havendo garantias de funcionamento contínuo ou '
                      'livre de erros. A equipe não se responsabiliza por:\n'
                      '• Danos decorrentes de uso indevido do aplicativo;\n'
                      '• Interrupções ou falhas na disponibilidade do serviço;\n'
                      '• Conteúdos enviados por usuários.\n\n'
                      '8. Cancelamento e Exclusão\n'
                      'O usuário pode excluir sua conta a qualquer momento, sendo seus dados apagados '
                      'conforme previsto na Política de Privacidade.\n\n'
                      '9. Alterações nos Termos\n'
                      'Reservamo-nos o direito de alterar estes Termos de Uso a qualquer momento. As '
                      'alterações entrarão em vigor na data de sua publicação no aplicativo ou site.\n\n'
                      '10. Contato\n'
                      'Em caso de dúvidas, sugestões ou solicitações, o usuário pode entrar em contato por meio '
                      'dos canais disponibilizados no aplicativo.\n\n'
                      '11. Foro\n'
                      'Este contrato será regido pelas leis brasileiras. Quaisquer disputas serão resolvidas no foro '
                      'da comarca da cidade-sede do projeto, salvo disposição legal em contrário.'
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
