import 'dart:io';
import 'package:avisai4/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../bloc/connectivity/connectivity_bloc.dart';
import '../../../bloc/registro/registro_bloc.dart';
import '../../../data/models/registro.dart';

class NovoRegistroScreen extends StatefulWidget {
  final String usuarioId;
  final String usuarioNome;
  final bool isVisible;

  const NovoRegistroScreen({
    super.key,
    required this.usuarioId,
    required this.usuarioNome,
    this.isVisible = false,
  });

  @override
  _NovoRegistroScreenState createState() => _NovoRegistroScreenState();
}

class _NovoRegistroScreenState extends State<NovoRegistroScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _imagemCapturada;
  bool _inicializando = true;
  bool _tirouFoto = false;
  bool _erroCamera = false;
  String _mensagemErro = '';
  CategoriaIrregularidade _categoriaIrregularidade =
      CategoriaIrregularidade.buraco;
  Position? _localizacaoCaptura;

  // Controlador de animação
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar controlador de animação
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Inicializa a câmera após um pequeno delay para garantir que o widget está montado
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _inicializarCamera();
      }
    });
  }

  @override
  void dispose() {
    // Liberar recursos da animação
    _buttonAnimationController.dispose();

    try {
      // Garantir que os recursos da câmera são liberados
      if (_cameraController != null) {
        _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      print("Erro ao liberar câmera no dispose: $e");
    }
    _liberarCamera();
    super.dispose();
  }

  @override
  void didUpdateWidget(NovoRegistroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se a visibilidade mudou
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        // Inicializar câmera quando a tela ficar visível
        if (_cameraController == null ||
            !_cameraController!.value.isInitialized) {
          _inicializarCamera();
        }
      } else {
        // Liberar câmera quando a tela ficar invisível
        _liberarCamera();
      }
    }
  }

  Future<void> _liberarCamera() async {
    try {
      if (_cameraController != null) {
        final wasInitialized = _cameraController!.value.isInitialized;
        await _cameraController!.dispose();

        // Atualizar o estado imediatamente para evitar que a interface tente acessar
        // um controlador descartado
        if (mounted && wasInitialized) {
          setState(() {
            _cameraController = null;
          });
        } else {
          _cameraController = null;
        }
      }
    } catch (e) {
      print("Erro ao liberar câmera: $e");
      // Garantir que o controlador seja nulo mesmo em caso de erro
      if (mounted) {
        setState(() {
          _cameraController = null;
        });
      } else {
        _cameraController = null;
      }
    }
  }

  Future<void> _inicializarCamera() async {
    setState(() {
      _inicializando = true;
      _erroCamera = false;
      _mensagemErro = '';
    });

    try {
      // Verificar permissões
      print('Verificando permissões da câmera...');
      final statusCamera = await Permission.camera.status;
      print('Status da permissão de câmera: $statusCamera');

      if (statusCamera.isDenied) {
        await Permission.camera.request();
        setState(() {
          _inicializando = false;
          _erroCamera = true;
          _mensagemErro =
              'Permissão de câmera negada. Por favor, habilite nas configurações do dispositivo.';
        });
        return;
      }

      // Tentar obter as câmeras disponíveis
      print('Buscando câmeras disponíveis...');
      _cameras = await availableCameras();
      print('Câmeras encontradas: ${_cameras?.length ?? 0}');

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _inicializando = false;
          _erroCamera = true;
          _mensagemErro = 'Nenhuma câmera encontrada no dispositivo.';
        });
        return;
      }

      // Inicializar o controlador com a primeira câmera disponível
      print('Inicializando controlador de câmera...');
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium, // Usar resolução média para melhor performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Aguardar a inicialização do controlador
      print('Aguardando inicialização do controlador...');
      await _cameraController!.initialize();
      print('Controlador de câmera inicializado com sucesso!');

      if (!mounted) return;

      setState(() {
        _inicializando = false;
      });
    } catch (e) {
      print('ERRO AO INICIALIZAR CÂMERA: $e');

      if (mounted) {
        setState(() {
          _inicializando = false;
          _erroCamera = true;
          _mensagemErro = 'Erro ao inicializar câmera: $e';
        });
      }
    }
  }

  Future<void> _capturarFoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Câmera não inicializada. Tente novamente.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Mostrar indicador de carregamento
      setState(() {
        _inicializando = true;
      });

      // Capturar a foto
      final arquivo = await _cameraController!.takePicture();

      // Capturar a localização atual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          forceLocationManager: true,
        ),
      );

      setState(() {
        _imagemCapturada = File(arquivo.path);
        _localizacaoCaptura = position;
        _tirouFoto = true;
        _inicializando = false;
      });
    } catch (e) {
      print('Erro ao capturar imagem ou localização: $e');
      setState(() {
        _inicializando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao capturar imagem: $e'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selecionarDaGaleria() async {
    try {
      final picker = ImagePicker();
      final arquivo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reduzir qualidade para economizar memória
      );

      if (arquivo == null) return;

      setState(() {
        _inicializando = true;
      });

      // Capturar a localização atual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          forceLocationManager: true,
        ),
      );

      setState(() {
        _imagemCapturada = File(arquivo.path);
        _tirouFoto = true;
        _localizacaoCaptura = position;
        _inicializando = false;
      });
    } catch (e) {
      setState(() {
        _inicializando = false;
      });
      print('Erro ao selecionar da galeria: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelar() {
    setState(() {
      _imagemCapturada = null;
      _tirouFoto = false;
    });
  }

  Future<void> _enviarRegistro() async {
    if (_imagemCapturada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma imagem capturada.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_localizacaoCaptura == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Localização não disponível. Verifique se o GPS está ativado.',
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostra indicador de progresso
    setState(() {
      _inicializando = true;
    });

    // IMPORTANTE: Libere os recursos da câmera antes de navegar
    await _liberarCamera(); // Alterado para usar o método existente

    try {
      // Armazene o caminho da imagem capturada
      final String caminhoImagem = _imagemCapturada!.path;

      // Crie o registro usando o BLoC, mas passando as coordenadas salvas
      context.read<RegistroBloc>().add(
        CriarNovoRegistroComLocalizacao(
          usuarioId: widget.usuarioId,
          usuarioNome: widget.usuarioNome,
          categoria: _categoriaIrregularidade,
          caminhoFotoTemporario: caminhoImagem,
          latitude: _localizacaoCaptura!.latitude,
          longitude: _localizacaoCaptura!.longitude,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen(index: 0)),
      );

      // Navegue para a tela principal e libere recursos explicitamente
    } catch (e) {
      print("Erro durante o envio do registro: $e");
      if (mounted) {
        setState(() {
          _inicializando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar registro: $e'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistroBloc, RegistroState>(
      listener: (context, state) {
        if (state is RegistroOperacaoSucesso) {
          // Mostra mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensagem),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is RegistroErro) {
          // Mostra erro mas não fecha a tela
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erro na API, mas registro salvo localmente"),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // Status de conectividade no topo
            BlocBuilder<ConnectivityBloc, ConnectivityState>(
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

            // Área da câmera ou imagem (expandida para ocupar o espaço disponível)
            Expanded(
              child:
                  _inicializando
                      ? const Center(child: CircularProgressIndicator())
                      : _tirouFoto
                      ? _visualizarImagemCapturada()
                      : _mostrarCamera(),
            ),
          ],
        ),

        // Bottom Navigation Bar fixa
      ),
    );
  }

  Widget _mostrarCamera() {
    // Se houve erro na inicialização da câmera
    if (_erroCamera) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              _mensagemErro,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _inicializarCamera,
              icon: Icon(Icons.refresh),
              label: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    // Verificações para câmera
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(
        child: Text(
          'Câmera não inicializada.\nPor favor, aguarde ou reinicie o aplicativo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    // Tenta mostrar o preview da câmera
    try {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Preview da câmera
          CameraPreview(_cameraController!),

          // Botão de captura circular na parte inferior
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTapDown: (_) {
                  _buttonAnimationController.forward();
                },
                onTapUp: (_) {
                  _buttonAnimationController.reverse();
                  _capturarFoto();
                },
                onTapCancel: () {
                  _buttonAnimationController.reverse();
                },
                child: AnimatedBuilder(
                  animation: _buttonScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonScaleAnimation.value,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 4,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.transparent,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Botão de galeria no canto inferior direito
          Positioned(
            bottom: 40,
            right: 24,
            child: GestureDetector(
              onTap: _selecionarDaGaleria,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF002569),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      print('Erro ao exibir preview da câmera: $e');
      return Center(
        child: Text(
          'Erro ao exibir câmera: $e',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _visualizarImagemCapturada() {
    return Stack(
      children: [
        // Fundo escurecido
        Container(
          color: Colors.black.withOpacity(0.7),
          width: double.infinity,
          height: double.infinity,
        ),

        // Card central com a imagem e opções
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagem capturada com bordas arredondadas
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                      bottom: Radius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 12,
                          child:
                              _imagemCapturada != null
                                  ? Image.file(
                                    _imagemCapturada!,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                        ),
                        if (_imagemCapturada != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: EdgeInsets.all(10),
                                        child: GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: InteractiveViewer(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.file(
                                                _imagemCapturada!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.black.withOpacity(0.6),
                                child: Icon(
                                  Icons.zoom_out_map,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Seletor de categoria
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(30),
                        shadowColor: Colors.black.withOpacity(0.4),
                        color: Colors.white,
                        child: DropdownButtonFormField<CategoriaIrregularidade>(
                          value:
                              _categoriaIrregularidade, // Deve ser null inicialmente
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[600],
                            ),
                          ),
                          hint: Text(
                            'Selecione a categoria',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                            ),
                          ),
                          icon: const SizedBox.shrink(),
                          items: [
                            DropdownMenuItem(
                              value: CategoriaIrregularidade.buraco,
                              child: Text(
                                'Buraco na via',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: CategoriaIrregularidade.posteDefeituoso,
                              child: Text(
                                'Poste com defeito',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: CategoriaIrregularidade.lixoIrregular,
                              child: Text(
                                'Descarte irregular de lixo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (valor) {
                            if (valor != null) {
                              setState(() {
                                _categoriaIrregularidade = valor;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Texto de confirmação
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Você tem certeza que deseja enviar?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[850],
                      ),
                    ),
                  ),
                ),

                // Botões de ação
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      // Botão Cancelar
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _cancelar,
                          icon: Icon(Icons.close, size: 18),
                          label: Text(
                            'Cancelar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.red,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.red, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Botão Enviar
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _enviarRegistro,
                          icon: Icon(Icons.send, size: 18),
                          label: Text(
                            'Enviar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
