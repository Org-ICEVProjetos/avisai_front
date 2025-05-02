import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/connectivity/connectivity_bloc.dart';
import '../../../bloc/registro/registro_bloc.dart';
import '../registro/novo_registro_screen.dart';
import '../registro/meus_registros_screen.dart';
import '../mapa/mapa_irregularidades_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int index;
  const HomeScreen({super.key, required this.index});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _indiceAbaSelecionada;
  final List<Widget> _telas = [];

  @override
  void initState() {
    super.initState();
    _indiceAbaSelecionada = widget.index;
    // Carregar registros quando a tela for inicializada
    context.read<RegistroBloc>().add(CarregarRegistros());
    solicitarPermissaoCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Obter usuário autenticado
    final authState = context.read<AuthBloc>().state;
    if (authState is Autenticado) {
      final usuario = authState.usuario;

      // Inicializar telas com base no índice atual
      _telas.clear();
      _telas.addAll([
        MeusRegistrosScreen(usuarioId: usuario.id!),
        NovoRegistroScreen(
          usuarioId: usuario.id!,
          usuarioNome: usuario.nome,
          isVisible: _indiceAbaSelecionada == 1,
        ),
        const MapaIrregularidadesScreen(),
      ]);
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    // Atualizar as telas quando o índice mudar
    if (_telas.length > 1 && _telas[1] is NovoRegistroScreen) {
      // Recriar a tela de registro com a visibilidade atualizada
      final authState = context.read<AuthBloc>().state;
      if (authState is Autenticado) {
        final usuario = authState.usuario;
        _telas[1] = NovoRegistroScreen(
          usuarioId: usuario.id!,
          usuarioNome: usuario.nome,
          isVisible: _indiceAbaSelecionada == 1,
        );
      }
    }
  }

  Future<bool> solicitarPermissaoCamera() async {
    // Solicita a permissão de câmera
    PermissionStatus status = await Permission.camera.request();
    await Permission.location.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    } else {
      // Permissão negada (não permanentemente)
      return false;
    }
  }

  // Título personalizado com base na aba selecionada
  String _getTitulo() {
    switch (_indiceAbaSelecionada) {
      case 0:
        return 'Histórico';
      case 1:
        return 'Registrar';
      case 2:
        return 'Mapa';
      default:
        return 'Avisaí';
    }
  }

  // Ações personalizadas com base na aba selecionada
  List<Widget> _getAcoes() {
    List<Widget> acoes = [];

    // Botão de logout para todas as abas
    acoes.add(
      IconButton(
        icon: const Icon(Icons.logout, size: 30),
        onPressed: () {
          // Mostrar diálogo de confirmação
          showDialog(
            context: context,
            builder: (BuildContext context) {
              // Get screen size
              final Size screenSize = MediaQuery.of(context).size;
              final double screenWidth = screenSize.width;
              final double screenHeight = screenSize.height;

              // Calculate responsive sizes
              final double titleFontSize =
                  screenWidth * 0.05; // 5% of screen width
              final double bodyFontSize =
                  screenWidth * 0.04; // 4% of screen width
              final double buttonHeight =
                  screenHeight * 0.06; // 6% of screen height

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    screenWidth * 0.04,
                  ), // Responsive border radius
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  screenWidth * 0.06, // Left padding
                  screenHeight * 0.03, // Top padding
                  screenWidth * 0.06, // Right padding
                  screenHeight * 0.02, // Bottom padding
                ),
                title: Text(
                  'Sair',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'Tem certeza que deseja sair?',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                actionsPadding: EdgeInsets.fromLTRB(
                  screenWidth * 0.06, // Left padding
                  0, // Top padding
                  screenWidth * 0.06, // Right padding
                  screenHeight * 0.03, // Bottom padding
                ),
                actions: [
                  // Layout de coluna para os botões ocuparem toda a largura
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Botão principal "Sair"
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<AuthBloc>().add(LogoutSolicitado());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.08,
                            ),
                          ),
                          minimumSize: Size(double.infinity, buttonHeight),
                        ),
                        child: Text(
                          'Sair',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            fontSize: bodyFontSize,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: screenHeight * 0.01,
                      ), // Espaçamento entre botões
                      // Botão secundário "Cancelar"
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF022865),
                          minimumSize: Size(
                            double.infinity,
                            buttonHeight *
                                0.8, // Ligeiramente menor que o botão principal
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
        tooltip: 'Sair',
      ),
    );

    return acoes;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is NaoAutenticado) {
          // Redirecionar para a tela de login se não estiver autenticado
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        // AppBar personalizada com base na aba selecionada
        appBar: AppBar(
          title: Text(
            _getTitulo(),
            style: const TextStyle(
              fontSize: 34, // Fonte maior
              fontWeight: FontWeight.bold, // Negrito
              color: Colors.white,
              fontFamily: 'Inter', // Se quiser manter seu padrão de fontes
            ),
          ),
          actions: _getAcoes(),
          backgroundColor: const Color(0xFF002569),
          centerTitle: false,
          elevation: 0, // Sem sombra
          foregroundColor: Colors.white, // Ícones brancos
          toolbarHeight: 80, // <- aumenta a altura da AppBar
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Autenticado) {
              return IndexedStack(
                index: _indiceAbaSelecionada,
                children: _telas,
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        // BottomNavigationBar personalizada
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _indiceAbaSelecionada,
          onTap: (indice) {
            setState(() {
              _indiceAbaSelecionada = indice;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(
            0xFF002569,
          ), // Azul escuro para o item selecionado
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                _indiceAbaSelecionada == 0
                    ? Icons.history
                    : Icons.history_outlined,
                size: 35,
              ),
              label: 'Histórico',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _indiceAbaSelecionada == 1
                    ? Icons.camera_alt
                    : Icons.camera_alt_outlined,
                size: 35,
              ),

              label: 'Registrar',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _indiceAbaSelecionada == 2 ? Icons.map : Icons.map_outlined,
                size: 35,
              ),
              label: 'Mapa',
            ),
          ],
        ),
      ),
    );
  }
}
