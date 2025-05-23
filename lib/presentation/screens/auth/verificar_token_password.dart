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

  // 6 controllers para os 6 dígitos do token
  final List<TextEditingController> _digitControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // 6 focus nodes para gerenciar o foco entre os campos
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Para controlar o key listener
  final FocusNode _rootNode = FocusNode();

  bool _carregando = false;
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

    // Foca no primeiro campo quando a tela é carregada
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

      // Limpar os campos do token quando reenviar
      for (var controller in _digitControllers) {
        controller.clear();
      }

      // Atraso curto para aguardar o processamento do envio
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          // Foca no primeiro campo
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

            // Navegar para a tela de alteração de senha
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) =>
                        ChangePasswordScreen(token: _getCompleteToken()),
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

                    // NOVA implementação do campo de token com 6 caixas
                    Form(
                      key: _formKey,
                      child: SlideTransition(
                        position: _slideFormAnimation,
                        child: Column(
                          children: [
                            // Label para o campo de código
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

                            // Row com 6 caixas de entrada - TORNANDO RESPONSIVO
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Calculando o tamanho ideal para os campos
                                // Considere o espaço total disponível e deixe um pequeno espaço entre eles
                                final double availableWidth =
                                    constraints.maxWidth;

                                // Determine o tamanho máximo do campo e o espaçamento entre eles
                                // Vamos garantir que haja pelo menos 8 pixels entre os campos
                                final double spacing = 8;
                                final int numBoxes = 6;
                                final double totalSpacing =
                                    spacing * (numBoxes - 1);

                                // Calcule o tamanho do campo, com um mínimo de 40 e máximo de 50
                                double boxWidth =
                                    (availableWidth - totalSpacing) / numBoxes;
                                boxWidth = boxWidth.clamp(40, 50);

                                // Ajuste o espaçamento horizontal final baseado no tamanho dos campos
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
                                            5), // Corrige o deslocamento para a esquerda
                                    right: horizontalPadding.clamp(
                                      0,
                                      double.infinity,
                                    ),
                                    top: 5, // Corrige o deslocamento para baixo
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

  // Widget para cada caixa de dígito
  Widget _buildDigitBox(int index, double width) {
    return Container(
      width: width,
      height: width * 1.2, // Mantém a proporção
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

          // Ajustando o padding interno para corrigir o desalinhamento dos números
          contentPadding: const EdgeInsets.only(
            top: 11, // Movendo o texto um pouco para cima
            bottom: 11,
            left: 3.5, // Corrigindo o deslocamento para a esquerda
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
          // Se o dígito foi digitado, mover para o próximo campo
          if (value.isNotEmpty) {
            // Se não for o último campo, mover para o próximo
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Se for o último campo, remover o foco
              FocusScope.of(context).unfocus();

              // Verificar se todos os campos estão preenchidos para validar
              if (_todosDigitosPreenchidos()) {
                // Opcional: verificar token automaticamente após um curto delay
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _verificarToken();
                });
              }
            }
          }
          // Se o campo foi apagado, voltar para o anterior
          else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return ''; // Validação leve, só para marcar o campo
          }
          return null;
        },
      ),
    );
  }
}
