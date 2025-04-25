import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/connectivity/connectivity_bloc.dart';
import '../../../bloc/registro/registro_bloc.dart';
import '../registro/novo_registro_screen.dart';
import '../registro/meus_registros_screen.dart';
import '../mapa/mapa_irregularidades_screen.dart';
import '../auth/login_screen.dart';
import '../widgets/offline_badge.dart';

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
