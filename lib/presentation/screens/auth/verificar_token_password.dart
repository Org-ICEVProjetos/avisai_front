import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';

class VerifyTokenScreen extends StatefulWidget {
  final String cpf;
  final String email;

  const VerifyTokenScreen({super.key, required this.cpf, required this.email});

  @override
  _VerifyTokenScreenState createState() => _VerifyTokenScreenState();
}

class _VerifyTokenScreenState extends State<VerifyTokenScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _digitControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final FocusNode _rootNode = FocusNode();

  bool _carregando = false;
  int _secondsRemaining = 0;
  Timer? _timer;

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

    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });

    _startResendTimer();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  bool _todosDigitosPreenchidos() {
    return _digitControllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getCompleteToken() {
    return _digitControllers.map((controller) => controller.text).join();
  }

  @override
  void dispose() {
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _rootNode.dispose();
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 60;
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
        VerificarTokenSenhaSolicitado(token: _getCompleteToken()),
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

      for (var controller in _digitControllers) {
        controller.clear();
      }

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _focusNodes[0].requestFocus();
        }
      });
    }
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
            });

            Navigator.of(context).pushReplacementNamed(
              '/change-password',
              arguments: {'token': _getCompleteToken()},
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

                    Form(
                      key: _formKey,
                      child: SlideTransition(
                        position: _slideFormAnimation,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 16.0,
                                top: 3.0,
                                left: 5.0,
                              ),
                              child: Text(
                                'Digite o código de 6 dígitos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final double availableWidth =
                                    constraints.maxWidth;

                                final double spacing = 8;
                                final int numBoxes = 6;
                                final double totalSpacing =
                                    spacing * (numBoxes - 1);

                                double boxWidth =
                                    (availableWidth - totalSpacing) / numBoxes;
                                boxWidth = boxWidth.clamp(40, 50);

                                final double horizontalPadding =
                                    (availableWidth -
                                        (boxWidth * numBoxes + totalSpacing)) /
                                    2;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    left:
                                        (horizontalPadding.clamp(
                                              0,
                                              double.infinity,
                                            ) +
                                            5),
                                    right: horizontalPadding.clamp(
                                      0,
                                      double.infinity,
                                    ),
                                    top: 5,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      6,
                                      (index) =>
                                          _buildDigitBox(index, boxWidth),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

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

  Widget _buildDigitBox(int index, double width) {
    return Container(
      width: width,
      height: width * 1.2,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _digitControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.only(
            top: 11,
            bottom: 11,
            left: 3.5,
            right: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              FocusScope.of(context).unfocus();

              if (_todosDigitosPreenchidos()) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _verificarToken();
                });
              }
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '';
          }
          return null;
        },
      ),
    );
  }
}
