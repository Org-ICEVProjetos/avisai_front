import 'dart:async';
import 'package:avisai4/bloc/registro/registro_bloc.dart';
import 'package:avisai4/data/providers/api_provider.dart';
import 'package:avisai4/presentation/screens/auth/profile_screen.dart';
import 'package:avisai4/services/export_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/connectivity/connectivity_bloc.dart';
import '../registro/novo_registro_screen.dart';
import '../registro/meus_registros_screen.dart';
import '../mapa/mapa_irregularidades_screen.dart';

class HomeScreen extends StatefulWidget {
  final int index;
  const HomeScreen({super.key, required this.index});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _indiceAbaSelecionada;
  final List<Widget> _telas = [];
  StreamSubscription? _logoutSubscription;
  ApiProvider apiProvider = ApiProvider();

  @override
  void initState() {
    super.initState();
    _indiceAbaSelecionada = widget.index;
    _logoutSubscription = apiProvider.logoutForcadoStream.listen((needsLogout) {
      if (needsLogout) {
        _forcarLogout(context);
      }
    });
    solicitarPermissao();
  }

  @override
  void dispose() {
    super.dispose();
    _logoutSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authState = context.read<AuthBloc>().state;
    if (authState is Autenticado) {
      final usuario = authState.usuario;

      _telas.clear();
      _telas.addAll([
        MeusRegistrosScreen(usuarioId: usuario.id!),
        NovoRegistroScreen(
          usuarioId: usuario.id!,
          usuarioNome: usuario.nome,
          isVisible: _indiceAbaSelecionada == 1,
        ),
        const MapaIrregularidadesScreen(),
        const PerfilScreen(),
      ]);
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_telas.length > 1 && _telas[1] is NovoRegistroScreen) {
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

  Future<bool> solicitarPermissao() async {
    PermissionStatus statusCamera = await Permission.camera.request();
    PermissionStatus statuslocation = await Permission.location.request();
    if (statusCamera.isGranted && statuslocation.isGranted) {
      return true;
    } else if (statusCamera.isPermanentlyDenied ||
        statuslocation.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    } else {
      return false;
    }
  }

  String _getTitulo() {
    switch (_indiceAbaSelecionada) {
      case 0:
        return 'Histórico';
      case 1:
        return 'Registrar';
      case 2:
        return 'Mapa';
      case 3:
        return 'Perfil';
      default:
        return 'Avisaí';
    }
  }

  List<Widget> _getAcoes() {
    List<Widget> acoes = [];

    acoes.add(
      IconButton(
        icon: const Icon(Icons.logout, size: 30),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              final Size screenSize = MediaQuery.of(context).size;
              final double screenWidth = screenSize.width;
              final double screenHeight = screenSize.height;

              final double titleFontSize = screenWidth * 0.05;
              final double bodyFontSize = screenWidth * 0.04;
              final double buttonHeight = screenHeight * 0.06;

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  screenWidth * 0.06,
                  screenHeight * 0.03,
                  screenWidth * 0.06,
                  screenHeight * 0.02,
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
                  screenWidth * 0.06,
                  0,
                  screenWidth * 0.06,
                  screenHeight * 0.03,
                ),
                actions: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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

                      SizedBox(height: screenHeight * 0.01),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF022865),
                          minimumSize: Size(
                            double.infinity,
                            buttonHeight * 0.8,
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

    if (true) {
      acoes.add(ExportButton());
    }

    return acoes;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is NaoAutenticado) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
        BlocListener<ConnectivityBloc, ConnectivityState>(
          listener: (context, state) {
            if (state is ConnectivityConnected) {
              context.read<RegistroBloc>().add(
                SincronizarRegistrosPendentes(
                  context: context,
                  silencioso: true,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getTitulo(),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          actions: _getAcoes(),
          backgroundColor: const Color(0xFF002569),
          centerTitle: false,
          elevation: 0,
          foregroundColor: Colors.white,
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
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
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _indiceAbaSelecionada,
          onTap: (indice) {
            setState(() {
              _indiceAbaSelecionada = indice;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF002569),
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
            BottomNavigationBarItem(
              icon: Icon(
                _indiceAbaSelecionada == 3
                    ? Icons.person
                    : Icons.person_outline,
                size: 35,
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  void _forcarLogout(BuildContext context) {
    Navigator.of(context).pop();
    context.read<AuthBloc>().add(LogoutSolicitado());
  }
}
