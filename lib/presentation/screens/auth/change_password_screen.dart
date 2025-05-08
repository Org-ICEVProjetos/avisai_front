import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String token;

  const ChangePasswordScreen({Key? key, required this.token}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmSenhaController = TextEditingController();
  final _senhaFieldKey = GlobalKey<FormFieldState>();
  final _confirmSenhaFieldKey = GlobalKey<FormFieldState>();
  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmSenha = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideTextAnimation;
  late Animation<Offset> _slideForm1Animation;
  late Animation<Offset> _slideForm2Animation;
  late Animation<Offset> _slideButtonAnimation;
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

    // Start animation after short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmSenhaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _alterarSenha() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _carregando = true;
      });

      context.read<AuthBloc>().add(
        AlterarSenhaSolicitada(
          senha: _senhaController.text,
          token: widget.token,
        ),
      );
    }
  }

  String? _validarSenha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Por favor, digite sua nova senha';
    }
    if (valor.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  String? _validarConfirmSenha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Por favor, confirme sua senha';
    }
    if (valor != _senhaController.text) {
      return 'As senhas não coincidem';
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
          'Nova senha',
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
          } else if (state is SenhaAlterada) {
            setState(() {
              _carregando = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Senha alterada com sucesso!'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );

            // Navegar para a tela de login
            Navigator.of(context).popUntil((route) => route.isFirst);
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
                            const TextSpan(text: 'Crie uma '),
                            TextSpan(
                              text: 'nova senha',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ' segura para sua conta. Recomendamos usar uma combinação de letras, números e símbolos.',
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
                          // Campo Senha com animação
                          SlideTransition(
                            position: _slideForm1Animation,
                            child: Column(
                              children: [
                                Material(
                                  elevation: 5,
                                  borderRadius: BorderRadius.circular(30),
                                  shadowColor: Colors.black.withOpacity(0.4),
                                  color: Colors.white,
                                  child: TextFormField(
                                    key: _senhaFieldKey,
                                    controller: _senhaController,
                                    obscureText: !_mostrarSenha,
                                    validator: _validarSenha,
                                    style: theme.textTheme.bodyLarge,
                                    decoration: InputDecoration(
                                      labelText: 'Nova senha',
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[500],
                                      ),
                                      hintText: "Digite sua nova senha",
                                      hintStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[500],
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _mostrarSenha
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _mostrarSenha = !_mostrarSenha;
                                          });
                                        },
                                      ),
                                      fillColor: Colors.white,
                                    ),
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
                          const SizedBox(height: 16),

                          // Campo Confirmar Senha com animação
                          SlideTransition(
                            position: _slideForm2Animation,
                            child: Column(
                              children: [
                                Material(
                                  elevation: 5,
                                  borderRadius: BorderRadius.circular(30),
                                  shadowColor: Colors.black.withOpacity(0.4),
                                  color: Colors.white,
                                  child: TextFormField(
                                    key: _confirmSenhaFieldKey,
                                    controller: _confirmSenhaController,
                                    obscureText: !_mostrarConfirmSenha,
                                    validator: _validarConfirmSenha,
                                    style: theme.textTheme.bodyLarge,
                                    decoration: InputDecoration(
                                      labelText: 'Confirmar senha',
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[500],
                                      ),
                                      hintText: "Confirme sua nova senha",
                                      hintStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[500],
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _mostrarConfirmSenha
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _mostrarConfirmSenha =
                                                !_mostrarConfirmSenha;
                                          });
                                        },
                                      ),
                                      fillColor: Colors.white,
                                    ),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    final errorText =
                                        _confirmSenhaFieldKey
                                            .currentState
                                            ?.errorText;
                                    if (errorText != null &&
                                        errorText.isNotEmpty) {
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão Alterar Senha com animação
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
                                  onPressed: _alterarSenha,
                                  icon: const Icon(Icons.lock_reset),
                                  label: const Text(
                                    'Alterar Senha',
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
                          'assets/images/nova_senha.png',
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
                                Icons.password,
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
