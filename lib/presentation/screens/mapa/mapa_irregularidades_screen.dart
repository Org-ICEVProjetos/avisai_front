import 'dart:async';
import 'package:avisai4/bloc/auth/auth_bloc.dart';
import 'package:avisai4/services/location_service.dart';
import 'package:avisai4/services/user_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../bloc/registro/registro_bloc.dart';
import '../../../data/models/registro.dart';

import '../widgets/offline_badge.dart';
import 'detalhes_registro_screen.dart';

class MapaIrregularidadesScreen extends StatefulWidget {
  const MapaIrregularidadesScreen({super.key});

  @override
  _MapaIrregularidadesScreenState createState() =>
      _MapaIrregularidadesScreenState();
}

class _MapaIrregularidadesScreenState extends State<MapaIrregularidadesScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  CameraPosition? _posicaoInicial;
  CategoriaIrregularidade? _filtroCategoria;

  @override
  void initState() {
    super.initState();
    _inicializarMapa();

    // Carregar registros quando a tela for inicializada
    context.read<RegistroBloc>().add(CarregarRegistros());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _inicializarMapa() async {
    try {
      // Obter a localização atual
      final posicao = await _locationService.getCurrentLocation();

      setState(() {
        _posicaoInicial = CameraPosition(
          target: LatLng(posicao.latitude, posicao.longitude),
          zoom: 15,
        );
      });
    } catch (e) {
      print('Erro ao obter localização: $e');

      // Usar uma posição padrão em caso de erro
      setState(() {
        _posicaoInicial = const CameraPosition(
          target: LatLng(-15.7801, -47.9292), // Brasília
          zoom: 10,
        );
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controllerCompleter.complete(controller);
    _mapController = controller;

    // Atualizar marcadores quando o mapa for criado
    _atualizarMarcadores();
  }

  Future<void> _irParaPosicaoAtual() async {
    try {
      final posicao = await _locationService.getCurrentLocation();

      final GoogleMapController controller = await _controllerCompleter.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(posicao.latitude, posicao.longitude)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao obter localização atual: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Em algum método ou função da sua classe
  Future<String?> obterIdUsuarioLogado() async {
    final usuario = await UserLocalStorage.obterUsuario();
    if (usuario != null) {
      return usuario.id;
    }
    return null;
  }

  void _atualizarMarcadores() async {
    if (context.mounted) {
      final state = context.read<RegistroBloc>().state;

      if (state is RegistroCarregado) {
        // Obter ID do usuário logado
        final usuario = await UserLocalStorage.obterUsuario();
        final usuarioId = usuario?.id;

        // Filtrar registros por categoria e/ou usuário
        List<Registro> registros = state.registros;

        // Filtrar por categoria se filtro estiver ativo
        if (_filtroCategoria != null) {
          registros =
              registros.where((r) => r.categoria == _filtroCategoria).toList();
        }

        if (usuarioId != null) {
          registros = registros.where((r) => r.usuarioId == usuarioId).toList();
        }
        setState(() {
          _markers =
              registros.map((registro) {
                return Marker(
                  markerId: MarkerId(registro.id!),
                  position: LatLng(registro.latitude, registro.longitude),
                  infoWindow: InfoWindow(
                    title: _getCategoriaTexto(registro.categoria),
                    snippet: registro.endereco ?? 'Endereço não disponível',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  DetalheRegistroScreen(registro: registro),
                        ),
                      );
                    },
                  ),
                  icon: _getIconePorCategoria(registro.categoria),
                );
              }).toSet();
        });

        // Ajustar a visualização para mostrar todos os marcadores, se houver algum
        if (_markers.isNotEmpty && _mapController != null) {
          _ajustarVisualizacao(registros);
        }
      }
    }
  }

  Future<void> _ajustarVisualizacao(List<Registro> registros) async {
    if (registros.isEmpty || _mapController == null) return;

    // Se houver apenas um registro, centralizar nele
    if (registros.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(registros.first.latitude, registros.first.longitude),
          15,
        ),
      );
      return;
    }

    // Calcular os limites que contêm todos os marcadores
    double minLat = registros.first.latitude;
    double maxLat = registros.first.latitude;
    double minLng = registros.first.longitude;
    double maxLng = registros.first.longitude;

    for (var registro in registros) {
      if (registro.latitude < minLat) minLat = registro.latitude;
      if (registro.latitude > maxLat) maxLat = registro.latitude;
      if (registro.longitude < minLng) minLng = registro.longitude;
      if (registro.longitude > maxLng) maxLng = registro.longitude;
    }

    // Criar limites com uma pequena margem
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    // Ajustar a câmera para mostrar todos os marcadores
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  BitmapDescriptor _getIconePorCategoria(CategoriaIrregularidade categoria) {
    // Na implementação real, você pode usar ícones personalizados
    // Para simplificar, estamos usando os ícones padrão
    switch (categoria) {
      case CategoriaIrregularidade.buraco:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case CategoriaIrregularidade.posteDefeituoso:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case CategoriaIrregularidade.lixoIrregular:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  String _getCategoriaTexto(CategoriaIrregularidade categoria) {
    switch (categoria) {
      case CategoriaIrregularidade.buraco:
        return 'Buraco na via';
      case CategoriaIrregularidade.posteDefeituoso:
        return 'Poste com defeito';
      case CategoriaIrregularidade.lixoIrregular:
        return 'Descarte irregular de lixo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<RegistroBloc, RegistroState>(
        listener: (context, state) {
          if (state is RegistroCarregado) {
            _atualizarMarcadores();
          } else if (state is RegistroErro) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text(state.mensagem),
            //     backgroundColor: Colors.red,
            //   ),
            // );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Mapa
              _posicaoInicial == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _posicaoInicial!,
                    onMapCreated: _onMapCreated,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),

              // Barra de status de conectividade
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: BlocBuilder<RegistroBloc, RegistroState>(
                  builder: (context, state) {
                    if (state is RegistroCarregado && !state.estaOnline) {
                      return Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Center(child: OfflineBadge()),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Barra superior com filtros
              Positioned(
                top: MediaQuery.of(context).padding.top + 50,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<
                            CategoriaIrregularidade?
                          >(
                            value: _filtroCategoria,
                            decoration: InputDecoration(
                              labelText: 'Filtrar por categoria',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem<CategoriaIrregularidade?>(
                                value: null,
                                child: Text('Todas as categorias'),
                              ),
                              DropdownMenuItem<CategoriaIrregularidade?>(
                                value: CategoriaIrregularidade.buraco,
                                child: Text('Buracos na via'),
                              ),
                              DropdownMenuItem<CategoriaIrregularidade?>(
                                value: CategoriaIrregularidade.posteDefeituoso,
                                child: Text('Postes com defeito'),
                              ),
                              DropdownMenuItem<CategoriaIrregularidade?>(
                                value: CategoriaIrregularidade.lixoIrregular,
                                child: Text('Descartes irregulares'),
                              ),
                            ],
                            onChanged: (valor) {
                              setState(() {
                                _filtroCategoria = valor;
                              });
                              _atualizarMarcadores();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botões de ação
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'btn_atualizar',
                      onPressed: () {
                        context.read<RegistroBloc>().add(CarregarRegistros());
                      },
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      tooltip: 'Atualizar registros',
                      child: const Icon(Icons.refresh),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton(
                      heroTag: 'btn_localizacao',
                      onPressed: _irParaPosicaoAtual,
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      tooltip: 'Minha localização',
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),

              // Contagem de registros
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: BlocBuilder<RegistroBloc, RegistroState>(
                    builder: (context, state) {
                      if (state is RegistroCarregado) {
                        final registros =
                            _filtroCategoria != null
                                ? state.registros
                                    .where(
                                      (r) => r.categoria == _filtroCategoria,
                                    )
                                    .toList()
                                : state.registros;

                        return Text(
                          '${registros.length} ${registros.length == 1 ? 'irregularidade' : 'irregularidades'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      }
                      return const Text(
                        'Carregando...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Carregando indicador
              if (state is RegistroCarregando)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}
