import 'package:avisai4/presentation/screens/auth/verificar_token_password.dart';
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

  // Animation controllers
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

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Fade in animation for the whole screen
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Slide animations for each element
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

    // Start animation after short delay
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
    final Size screenSize = MediaQuery.of(context).size;
    final double imageWidth =
        screenSize.width * 0.9 < 400 ? screenSize.width * 0.9 : 400.0;
    final double imageHeight =
        screenSize.height * 0.35 < 400 ? screenSize.height * 0.35 : 400.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Agora tem uma leve sombra
        centerTitle: false,
        title: Text(
          'Recuperar senha',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 30,
            fontFamily: 'Inter',
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 28, // Ícone maior
            color: Colors.black, // Ícone mais forte
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is RecuperacaoSenhaEnviada) {
            setState(() {
              _carregando = false;
              _enviado = true;
            });

            // Navegar para a próxima tela de verificação de token
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => VerifyTokenScreen(
                      cpf: _cpfController.text,
                      email: _emailController.text,
                    ),
              ),
            );

            // Reiniciar a animação quando recebe confirmação
            _animationController.reset();
            _animationController.forward();
          }
        },
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child:
                    !_enviado
                        ? _buildFormScreen(theme, imageWidth, imageHeight)
                        : _buildSuccessScreen(theme, imageWidth, imageHeight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tela de formulário para inserir CPF e email
  Widget _buildFormScreen(
    ThemeData theme,
    double imageWidth,
    double imageHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto explicativo com animação
        SlideTransition(
          position: _slideTextAnimation,
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[800],
                fontFamily: 'Inter',
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: 'Para recuperar sua senha, insira corretamente seu ',
                ),
                TextSpan(
                  text: 'e-mail',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' de acesso e '),
                TextSpan(
                  text: 'CPF',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
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
        const SizedBox(height: 32),

        // Formulário com animações
        Form(
          key: _formKey,
          child: Column(
            children: [
              // CPF com animação
              SlideTransition(
                position: _slideForm1Animation,
                child: _buildInputField(
                  controller: _cpfController,
                  label: 'CPF',
                  hint: "Digite sua CPF",
                  keyboardType: TextInputType.number,
                  validator: _validarCPF,
                  inputFormatters: [MaskedInputFormatter('000.000.000-00')],
                  fieldKey: _cpfFieldKey,
                ),
              ),
              const SizedBox(height: 16),

              // Email com animação
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
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botão Recuperar Senha com animação
        SlideTransition(
          position: _slideButtonAnimation,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child:
                _carregando
                    ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    )
                    : ElevatedButton.icon(
                      onPressed: _recuperarSenha,
                      icon: const Icon(Icons.send),
                      label: const Text(
                        'Recuperar Senha',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF022865),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                    ),
          ),
        ),

        const SizedBox(height: 32),

        // Imagem com animação
        SlideTransition(
          position: _slideImageAnimation,
          child: Center(
            child: Image.asset(
              'assets/images/recuperacao_senha.png',
              height: imageHeight,
              width: imageWidth,
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
      ],
    );
  }

  // Tela de sucesso após envio do formulário
  Widget _buildSuccessScreen(
    ThemeData theme,
    double imageWidth,
    double imageHeight,
  ) {
    return FadeTransition(
      opacity: _fadeSuccessAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Ícone de sucesso
          Icon(Icons.check_circle, size: 80, color: Colors.green),

          const SizedBox(height: 24),

          // Título de sucesso
          Text(
            'Solicitação enviada com sucesso!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontFamily: 'Inter',
            ),
          ),

          const SizedBox(height: 16),

          // Texto explicativo
          Text(
            'Verifique seu e-mail para as instruções de recuperação de senha.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Inter',
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Imagem de confirmação
          Image.asset(
            'assets/images/email_enviado.png',
            height: imageHeight,
            width: imageWidth,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: imageWidth,
                height: imageHeight,
                decoration: BoxDecoration(
                  color: theme.primaryColorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mark_email_read,
                  size: 80,
                  color: theme.primaryColorDark,
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Botão para voltar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'Voltar para o Login',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF022865),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
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
              labelText: label,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
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
}
