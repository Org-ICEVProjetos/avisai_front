import 'dart:async';
import 'package:avisai4/bloc/auth/auth_bloc.dart';
import 'package:avisai4/services/location_service.dart';
import 'package:avisai4/services/user_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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
  final LocationService _locationService = LocationService();

  final MapController _mapController = MapController();
  bool _mapControllerReady = false;

  List<Marker> _markers = [];
  LatLng _posicaoInicial = const LatLng(
    -5.08917,
    -42.80194,
  ); // Posição padrão: Brasília
  CategoriaIrregularidade? _filtroCategoria;
  double _zoomAtual = 15.0;

  // Localização atual e streams
  LatLng? _posicaoAtual;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _seguirLocalizacao =
      false; // Controla se o mapa deve seguir a localização do usuário

  @override
  void initState() {
    super.initState();
    _inicializarMapa();
    _iniciarMonitoramentoLocalizacao();

    // Carregar registros quando a tela for inicializada
    context.read<RegistroBloc>().add(CarregarRegistros());
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _inicializarMapa() async {
    try {
      // Obter a localização atual
      final posicao = await _locationService.getCurrentLocation();

      setState(() {
        _posicaoInicial = LatLng(posicao.latitude, posicao.longitude);
        _posicaoAtual = _posicaoInicial;
        _seguirLocalizacao = true;
      });
    } catch (e) {
      print('Erro ao obter localização: $e');
      // Continuamos com a posição padrão definida na inicialização
    }
  }

  void _iniciarMonitoramentoLocalizacao() async {
    // Verificar e solicitar permissões
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Iniciar stream de posição
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Atualiza a cada 5 metros de movimento
      ),
    ).listen((Position position) {
      setState(() {
        _posicaoAtual = LatLng(position.latitude, position.longitude);
      });

      // Se modo seguir estiver ativo, mover o mapa junto com a localização
      if (_seguirLocalizacao && _mapControllerReady) {
        _mapController.move(_posicaoAtual!, _zoomAtual);
      }
    });
  }

  Future<void> _irParaPosicaoAtual() async {
    if (!_mapControllerReady || _posicaoAtual == null) return;

    setState(() {
      _seguirLocalizacao = true; // Ativar modo de seguir localização
    });

    _mapController.move(_posicaoAtual!, _zoomAtual);
  }

  Future<String?> obterIdUsuarioLogado() async {
    final usuario = await UserLocalStorage.obterUsuario();
    if (usuario != null) {
      return usuario.id;
    }
    return null;
  }

  void _atualizarMarcadores() async {
    if (!context.mounted) return;

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

      if (!mounted) return;

      setState(() {
        _markers =
            registros.map((registro) {
              return Marker(
                point: LatLng(registro.latitude, registro.longitude),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    _mostrarInfoWindow(context, registro);
                  },
                  child: Icon(
                    Icons.location_pin,
                    color: _getCorPorCategoria(registro.categoria),
                    size: 40,
                  ),
                ),
              );
            }).toList();
      });

      // Ajustar a visualização para mostrar todos os marcadores, se houver algum
      if (_markers.isNotEmpty && _mapControllerReady && !_seguirLocalizacao) {
        _ajustarVisualizacao(registros);
      }
    }
  }

  void _mostrarInfoWindow(BuildContext context, Registro registro) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(_getCategoriaTexto(registro.categoria)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(registro.endereco ?? 'Endereço não disponível'),
                const SizedBox(height: 10),
                Text('Status: ${_getStatusTexto(registro.status)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Fechar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              DetalheRegistroScreen(registro: registro),
                    ),
                  );
                },
                child: const Text('Ver detalhes'),
              ),
            ],
          ),
    );
  }

  String _getStatusTexto(StatusValidacao status) {
    switch (status) {
      case StatusValidacao.validado:
        return 'Validado';
      case StatusValidacao.naoValidado:
        return 'Não validado';
      case StatusValidacao.pendente:
        return 'Pendente';
      case StatusValidacao.emExecucao:
        return 'Em execução';
      case StatusValidacao.resolvido:
        return 'Resolvido';
    }
  }

  Future<void> _ajustarVisualizacao(List<Registro> registros) async {
    if (registros.isEmpty || !_mapControllerReady) return;

    // Se houver apenas um registro, centralizar nele
    if (registros.length == 1) {
      _mapController.move(
        LatLng(registros.first.latitude, registros.first.longitude),
        15.0,
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

    // Adicionar margem
    minLat -= 0.01;
    maxLat += 0.01;
    minLng -= 0.01;
    maxLng += 0.01;

    // Calcular o centro
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // Calcular zoom baseado na distância
    final latDiff = (maxLat - minLat).abs();
    final lngDiff = (maxLng - minLng).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    // Ajustar zoom com base na diferença máxima
    double zoom = 15.0;
    if (maxDiff > 0.5)
      zoom = 8.0;
    else if (maxDiff > 0.2)
      zoom = 10.0;
    else if (maxDiff > 0.1)
      zoom = 12.0;
    else if (maxDiff > 0.05)
      zoom = 13.0;
    else if (maxDiff > 0.01)
      zoom = 14.0;

    _mapController.move(LatLng(centerLat, centerLng), zoom);
    setState(() {
      _zoomAtual = zoom;
      _seguirLocalizacao = false; // Desativar modo de seguir localização
    });
  }

  Color _getCorPorCategoria(CategoriaIrregularidade categoria) {
    switch (categoria) {
      case CategoriaIrregularidade.buraco:
        return Colors.red;
      case CategoriaIrregularidade.posteDefeituoso:
        return Colors.blue;
      case CategoriaIrregularidade.lixoIrregular:
        return Colors.green;
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
            // Atualizamos os marcadores após o próximo frame para garantir que o mapa esteja pronto
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _atualizarMarcadores();
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Mapa
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _posicaoInicial,
                  initialZoom: 15.0,
                  onMapReady: () {
                    setState(() {
                      _mapControllerReady = true;
                    });
                    if (_posicaoAtual != null && _seguirLocalizacao) {
                      _mapController.move(_posicaoAtual!, _zoomAtual);
                    }

                    _atualizarMarcadores();
                  },
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      setState(() {
                        _zoomAtual = position.zoom;
                        _seguirLocalizacao =
                            false; // Desativar seguir localização quando o usuário move o mapa
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.avisai.app',
                    subdomains: const ['a', 'b', 'c'],
                    maxZoom: 19,
                  ),
                  // Camada de marcadores para registros
                  MarkerLayer(markers: _markers),

                  // Camada de marcador para localização atual
                  if (_posicaoAtual != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _posicaoAtual!,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
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
                      foregroundColor:
                          _seguirLocalizacao
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                      tooltip: 'Minha localização',
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),

              // Controles de zoom
              Positioned(
                bottom: 16,
                right: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'btn_zoom_in',
                      onPressed: () {
                        if (!_mapControllerReady) return;
                        setState(() {
                          _zoomAtual += 1.0;
                          if (_zoomAtual > 19.0) _zoomAtual = 19.0;
                        });
                        _mapController.move(
                          _mapController.camera.center,
                          _zoomAtual,
                        );
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'btn_zoom_out',
                      onPressed: () {
                        if (!_mapControllerReady) return;
                        setState(() {
                          _zoomAtual -= 1.0;
                          if (_zoomAtual < 3.0) _zoomAtual = 3.0;
                        });
                        _mapController.move(
                          _mapController.camera.center,
                          _zoomAtual,
                        );
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.remove),
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
