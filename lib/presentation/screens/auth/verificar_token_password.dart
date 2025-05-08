import 'dart:async';
import 'package:avisai4/presentation/screens/auth/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';

class VerifyTokenScreen extends StatefulWidget {
  final String cpf;
  final String email;

  const VerifyTokenScreen({Key? key, required this.cpf, required this.email})
    : super(key: key);

  @override
  _VerifyTokenScreenState createState() => _VerifyTokenScreenState();
}

class _VerifyTokenScreenState extends State<VerifyTokenScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _tokenFieldKey = GlobalKey<FormFieldState>();
  bool _carregando = false;
  bool _tokenValidado = false;
  int _secondsRemaining = 0;
  Timer? _timer;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideTextAnimation;
  late Animation<Offset> _slideFormAnimation;
  late Animation<Offset> _slideButtonAnimation;
  late Animation<Offset> _slideResendButtonAnimation;
  late Animation<Offset> _slideImageAnimation;

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

    _slideFormAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
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

    _slideResendButtonAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
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

    // Start animation after short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });

    // Start the timer for resend button
    _startResendTimer();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 60; // 1 minute
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _verificarToken() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _carregando = true;
      });

      context.read<AuthBloc>().add(
        VerificarTokenSenhaSolicitado(token: _tokenController.text),
      );
    }
  }

  void _reenviarCodigo() {
    if (_secondsRemaining == 0) {
      setState(() {
        _carregando = true;
      });

      context.read<AuthBloc>().add(
        RecuperacaoSenhaSolicitada(cpf: widget.cpf, email: widget.email),
      );

      _startResendTimer();
    }
  }

  String? _validarToken(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Por favor, digite o código recebido por e-mail';
    }

    if (valor.length < 6) {
      return 'O código deve conter pelo menos 6 caracteres';
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
        screenSize.height * 0.25 < 300 ? screenSize.height * 0.25 : 300.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        title: Text(
          'Verificar código',
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
            size: 28,
            color: Colors.black,
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
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is TokenSenhaValidado) {
            setState(() {
              _carregando = false;
              _tokenValidado = true;
            });

            // Navegar para a tela de alteração de senha
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) =>
                        ChangePasswordScreen(token: _tokenController.text),
              ),
            );
          } else if (state is RecuperacaoSenhaEnviada) {
            setState(() {
              _carregando = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Código reenviado com sucesso!'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
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
                            TextSpan(text: 'Enviamos um '),
                            TextSpan(
                              text: 'código de verificação',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' para o e-mail '),
                            TextSpan(
                              text: widget.email,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '. Por favor, insira-o abaixo para continuar.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Formulário com animação
                    Form(
                      key: _formKey,
                      child: SlideTransition(
                        position: _slideFormAnimation,
                        child: Column(
                          children: [
                            Material(
                              elevation: 5,
                              borderRadius: BorderRadius.circular(30),
                              shadowColor: Colors.black.withOpacity(0.4),
                              color: Colors.white,
                              child: TextFormField(
                                key: _tokenFieldKey,
                                controller: _tokenController,
                                keyboardType: TextInputType.text,
                                validator: _validarToken,
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: 'Código de verificação',
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[500],
                                  ),
                                  hintText: "Digite o código recebido",
                                  hintStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[500],
                                  ),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                  fillColor: Colors.white,
                                ),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final errorText =
                                    _tokenFieldKey.currentState?.errorText;
                                if (errorText != null && errorText.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12.0,
                                      top: 4.0,
                                    ),
                                    child: Text(
                                      errorText,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão Verificar Código com animação
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
                                  onPressed: _verificarToken,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text(
                                    'Verificar Código',
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

                    const SizedBox(height: 16),

                    // Botão Reenviar Código com animação
                    SlideTransition(
                      position: _slideResendButtonAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child:
                            _secondsRemaining > 0
                                ? TextButton(
                                  onPressed: null,
                                  child: Text(
                                    'Reenviar código (${_secondsRemaining}s)',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                                : TextButton.icon(
                                  onPressed: _reenviarCodigo,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(
                                    'Reenviar código',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.primaryColor,
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
                          'assets/images/verificacao_codigo.png',
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
                                Icons.mail_lock,
                                size: 80,
                                color: theme.primaryColorDark,
                              ),
                            );
                          },
                        ),
                      ),
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
