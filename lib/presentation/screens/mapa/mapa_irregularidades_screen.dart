// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:async';
import 'package:avisai4/bloc/connectivity/connectivity_bloc.dart';
import 'package:avisai4/config/api_config.dart';
import 'package:avisai4/services/location_service.dart';
import 'package:avisai4/services/user_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../bloc/registro/registro_bloc.dart';
import '../../../data/models/registro.dart';

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
  LatLng _posicaoInicial = const LatLng(-5.08917, -42.80194);
  CategoriaIrregularidade? _filtroCategoria;
  double _zoomAtual = 15.0;
  LatLng? _posicaoAtual;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _seguirLocalizacao = false;

  @override
  void initState() {
    super.initState();
    _inicializarMapa();
    _iniciarMonitoramentoLocalizacao();
    context.read<RegistroBloc>().add(CarregarRegistros());
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _inicializarMapa() async {
    try {
      final posicao = await _locationService.getCurrentLocation();

      setState(() {
        _posicaoInicial = LatLng(posicao.latitude, posicao.longitude);
        _posicaoAtual = _posicaoInicial;
        _seguirLocalizacao = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter localização: $e');
      }
    }
  }

  void _iniciarMonitoramentoLocalizacao() async {
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

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() {
        _posicaoAtual = LatLng(position.latitude, position.longitude);
      });

      if (_seguirLocalizacao && _mapControllerReady) {
        _mapController.move(_posicaoAtual!, _zoomAtual);
      }
    });
  }

  Future<void> _irParaPosicaoAtual() async {
    if (!_mapControllerReady || _posicaoAtual == null) return;

    setState(() {
      _seguirLocalizacao = true;
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
      final usuario = await UserLocalStorage.obterUsuario();
      final usuarioId = usuario?.id;
      List<Registro> registros = state.registros;

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
                alignment: Alignment.bottomCenter,
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

      if (_markers.isNotEmpty && _mapControllerReady && !_seguirLocalizacao) {
        _ajustarVisualizacao(registros);
      }
    }
  }

  IconData _getCategoriaIcone(CategoriaIrregularidade categoria) {
    switch (categoria) {
      case CategoriaIrregularidade.buraco:
        return Icons.construction;
      case CategoriaIrregularidade.posteDefeituoso:
        return Icons.lightbulb_outline;
      case CategoriaIrregularidade.lixoIrregular:
        return Icons.delete_outline;
      case CategoriaIrregularidade.outro:
        return Icons.abc;
    }
  }

  IconData _getStatusIcone(StatusValidacao status) {
    switch (status) {
      case StatusValidacao.pendente:
        return Icons.hourglass_empty;
      case StatusValidacao.validado:
        return Icons.check_circle;
      case StatusValidacao.naoValidado:
        return Icons.cancel;
      case StatusValidacao.emRota:
        return Icons.engineering;
      case StatusValidacao.resolvido:
        return Icons.task_alt;
    }
  }

  Color _getStatusCor(StatusValidacao status) {
    switch (status) {
      case StatusValidacao.pendente:
        return Colors.orange;
      case StatusValidacao.validado:
        return Colors.green;
      case StatusValidacao.naoValidado:
        return Colors.red;
      case StatusValidacao.emRota:
        return Theme.of(context).colorScheme.primary;
      case StatusValidacao.resolvido:
        return Colors.green.shade800;
    }
  }

  void _mostrarInfoWindow(BuildContext context, Registro registro) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            title: null,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      _getCategoriaIcone(registro.categoria),
                      color: const Color(0xFF022865),
                      size: 36,
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Text(
                        _getCategoriaTexto(registro.categoria),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        registro.endereco ?? 'Endereço não disponível',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontFamily: 'Inter',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      _getStatusIcone(registro.status),
                      size: 20,
                      color: _getStatusCor(registro.status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${_getStatusTexto(registro.status)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(
                        '/registro/detalhe',
                        arguments: {'registro': registro},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF022865),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Ver detalhes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(fontSize: 16, fontFamily: 'Inter'),
                    ),
                  ),
                ],
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
      case StatusValidacao.emRota:
        return 'Em rota';
      case StatusValidacao.resolvido:
        return 'Resolvido';
    }
  }

  Future<void> _ajustarVisualizacao(List<Registro> registros) async {
    if (registros.isEmpty || !_mapControllerReady) return;

    if (registros.length == 1) {
      _mapController.move(
        LatLng(registros.first.latitude, registros.first.longitude),
        15.0,
      );
      return;
    }

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

    minLat -= 0.01;
    maxLat += 0.01;
    minLng -= 0.01;
    maxLng += 0.01;

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    final latDiff = (maxLat - minLat).abs();
    final lngDiff = (maxLng - minLng).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    double zoom = 15.0;
    if (maxDiff > 0.5) {
      zoom = 8.0;
    } else if (maxDiff > 0.2)
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
      _seguirLocalizacao = false;
    });
  }

  Color _getCorPorCategoria(CategoriaIrregularidade categoria) {
    switch (categoria) {
      case CategoriaIrregularidade.buraco:
        return Colors.red;
      case CategoriaIrregularidade.posteDefeituoso:
        return Theme.of(context).colorScheme.primary;
      case CategoriaIrregularidade.lixoIrregular:
        return Colors.green;
      case CategoriaIrregularidade.outro:
        return Colors.black;
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
      case CategoriaIrregularidade.outro:
        return 'Outro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<RegistroBloc, RegistroState>(
        listener: (context, state) {
          if (state is RegistroCarregado) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _atualizarMarcadores();
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
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
                        _seguirLocalizacao = false;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: ApiConfig.openStreetApi,
                    userAgentPackageName: 'com.avisai.app',
                    subdomains: const ['a', 'b', 'c'],
                    maxZoom: 19,
                  ),

                  MarkerLayer(markers: _markers),

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
                            CategoriaIrregularidade
                          >(
                            value: _filtroCategoria,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            hint: const Text('Filtrar por categoria'),
                            items: const [
                              DropdownMenuItem<CategoriaIrregularidade>(
                                value: null,
                                child: Text('Todas as categorias'),
                              ),
                              DropdownMenuItem(
                                value: CategoriaIrregularidade.buraco,
                                child: Text('Buracos na via'),
                              ),
                              DropdownMenuItem(
                                value: CategoriaIrregularidade.posteDefeituoso,
                                child: Text('Postes com defeito'),
                              ),
                              DropdownMenuItem(
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

              if (state is RegistroCarregando)
                const Center(child: CircularProgressIndicator()),

              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "© OpenStreetMap contributors",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
                  builder: (context, state) {
                    if (state is ConnectivityDisconnected) {
                      return Container(
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Offline',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
