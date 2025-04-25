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
import '../widgets/offline_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceAbaSelecionada = 1;
  final List<Widget> _telas = [];
  bool _checkedPermissions = false;

  @override
  void initState() {
    super.initState();

    // Carregar registros quando a tela for inicializada
    context.read<RegistroBloc>().add(CarregarRegistros());

    // Adiar a verificação de permissões para depois da renderização
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_checkedPermissions) {
        _verificarPermissoes();
        _checkedPermissions = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Obter usuário autenticado
    final authState = context.read<AuthBloc>().state;
    if (authState is Autenticado) {
      final usuario = authState.usuario;

      // Inicializar telas
      _telas.clear();
      _telas.addAll([
        MeusRegistrosScreen(usuarioId: usuario.id!),
        NovoRegistroScreen(usuarioId: usuario.id!, usuarioNome: usuario.nome),
        const MapaIrregularidadesScreen(),
      ]);
    }
  }

  Future<void> _verificarPermissoes() async {
    // Verificar status atual das permissões SEM solicitar
    final cameraStatus = await Permission.camera.isGranted;
    final locationStatus = await Permission.location.isGranted;
    final locationWhenInUseStatus =
        await Permission.locationWhenInUse.isGranted;

    // Se alguma permissão ainda não foi concedida, mostrar diálogo explicativo
    if (!cameraStatus || !locationStatus || !locationWhenInUseStatus) {
      if (mounted) {
        _mostrarDialogoPermissoes();
      }
    }
  }

  void _mostrarDialogoPermissoes() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop:
              () async =>
                  false, // Impedir que o diálogo seja fechado com o botão de voltar
          child: AlertDialog(
            title: const Text('Permissões necessárias'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const [
                  Text(
                    'Para utilizar todas as funcionalidades do aplicativo, precisamos de algumas permissões:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.camera_alt, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Câmera: para registrar as irregularidades com fotos',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Localização: para identificar onde as irregularidades foram encontradas',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Essas permissões são essenciais para o funcionamento do aplicativo e para garantir a precisão das informações.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Entendi'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Garantir que o diálogo seja fechado completamente antes de solicitar permissões
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _solicitarPermissoes();
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _solicitarPermissoes() async {
    // Verificar as permissões atuais
    bool todasPermissoesAceitas = true;

    // Solicitar permissão da câmera
    PermissionStatus cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      todasPermissoesAceitas = false;
    }

    // Solicitar permissão de localização
    PermissionStatus locationStatus = await Permission.location.request();
    if (locationStatus != PermissionStatus.granted) {
      todasPermissoesAceitas = false;
    }

    if (mounted) {
      // Verificar se alguma permissão foi negada permanentemente
      _verificarPermissoesNegadasPermanentemente();
    }
  }

  Future<void> _verificarPermissoesNegadasPermanentemente() async {
    // Verificar se alguma permissão foi negada permanentemente
    bool cameraPermanentlyDenied = await Permission.camera.isPermanentlyDenied;
    bool locationPermanentlyDenied =
        await Permission.location.isPermanentlyDenied;

    if (cameraPermanentlyDenied || locationPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permissões necessárias'),
              content: const Text(
                'Algumas permissões necessárias foram negadas permanentemente. '
                'Para utilizar todas as funcionalidades do aplicativo, por favor, '
                'vá até as configurações do seu dispositivo e habilite as permissões solicitadas.\n\n'
                'Após habilitar as permissões, reinicie o aplicativo para que as alterações tenham efeito.',
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Abrir configurações'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // O resto do código permanece o mesmo
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
        appBar: AppBar(
          title: const Text('Avisaí'),
          actions: [
            BlocBuilder<ConnectivityBloc, ConnectivityState>(
              builder: (context, state) {
                if (state is ConnectivityDisconnected) {
                  return const OfflineBadge();
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                final connectivityState =
                    context.read<ConnectivityBloc>().state;
                if (connectivityState is ConnectivityConnected) {
                  context.read<RegistroBloc>().add(
                    SincronizarRegistrosPendentes(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sincronizando registros...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sem conexão com a internet. Não é possível sincronizar.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              tooltip: 'Sincronizar',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // Mostrar diálogo de confirmação
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Sair'),
                        content: const Text('Tem certeza que deseja sair?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.read<AuthBloc>().add(LogoutSolicitado());
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Sair'),
                          ),
                        ],
                      ),
                );
              },
              tooltip: 'Sair',
            ),
          ],
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
          currentIndex: _indiceAbaSelecionada,
          onTap: (indice) {
            setState(() {
              _indiceAbaSelecionada = indice;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Meus Registros',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_a_photo),
              label: 'Registrar',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          ],
        ),
      ),
    );
  }
}
