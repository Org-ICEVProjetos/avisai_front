import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../bloc/registro/registro_bloc.dart';
import '../../../data/models/registro.dart';
import '../widgets/custom_button.dart';
import '../widgets/offline_badge.dart';

class NovoRegistroScreen extends StatefulWidget {
  final String usuarioId;
  final String usuarioNome;

  const NovoRegistroScreen({
    super.key,
    required this.usuarioId,
    required this.usuarioNome,
  });

  @override
  _NovoRegistroScreenState createState() => _NovoRegistroScreenState();
}

class _NovoRegistroScreenState extends State<NovoRegistroScreen> {
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

  @override
  void initState() {
    super.initState();
    // Inicializa a câmera após um pequeno delay para garantir que o widget está montado
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _inicializarCamera();
      }
    });
  }

  @override
  void dispose() {
    try {
      // Garantir que os recursos da câmera são liberados
      if (_cameraController != null) {
        _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      print("Erro ao liberar câmera no dispose: $e");
    }
    super.dispose();
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

      if (arquivo != null) {
        setState(() {
          _imagemCapturada = File(arquivo.path);
          _tirouFoto = true;
        });
      }
    } catch (e) {
      print('Erro ao selecionar da galeria: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
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
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

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

      // Aguarde um curto período para garantir que o processo começou
      await Future.delayed(Duration(milliseconds: 200));

      // Navegue para a tela principal
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print("Erro durante o envio do registro: $e");
      if (mounted) {
        setState(() {
          _inicializando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar registro: $e'),
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
            SnackBar(
              content: Text("Erro na API, mas registro salvo localmente"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _tirouFoto ? 'A foto ficou boa?' : "Registrar Irregularidade",
          ),
          actions: [
            BlocBuilder<RegistroBloc, RegistroState>(
              builder: (context, state) {
                if (state is RegistroCarregado && !state.estaOnline) {
                  return const OfflineBadge();
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body:
            _inicializando
                ? const Center(child: CircularProgressIndicator())
                : _construirCorpo(),
      ),
    );
  }

  Widget _construirCorpo() {
    return Column(
      children: [
        // Área da câmera ou imagem
        Expanded(child: _tirouFoto ? _visualizarImagem() : _mostrarCamera()),

        // Área de seleção de categoria
        if (_tirouFoto)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Selecione a categoria da irregularidade:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CategoriaIrregularidade>(
                  value: _categoriaIrregularidade,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: CategoriaIrregularidade.buraco,
                      child: Text('Buraco na via'),
                    ),
                    DropdownMenuItem(
                      value: CategoriaIrregularidade.posteDefeituoso,
                      child: Text('Poste com defeito'),
                    ),
                    DropdownMenuItem(
                      value: CategoriaIrregularidade.lixoIrregular,
                      child: Text('Descarte irregular de lixo'),
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
              ],
            ),
          ),

        // Barra de botões
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                _tirouFoto
                    ? [
                      Expanded(
                        child: CustomButton(
                          icone: Icons.close,
                          texto: 'Cancelar',
                          onPressed: _cancelar,
                          cor: Colors.red,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          icone: Icons.send,
                          texto: 'Enviar',
                          onPressed: _enviarRegistro,
                          cor: Colors.green,
                        ),
                      ),
                    ]
                    : [
                      Expanded(
                        child: CustomButton(
                          icone: Icons.photo_library,
                          texto: 'Galeria',
                          onPressed: _selecionarDaGaleria,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          icone: Icons.camera_alt,
                          texto: 'Capturar',
                          onPressed: _erroCamera ? () {} : _capturarFoto,
                          cor: Colors.blue,
                        ),
                      ),
                    ],
          ),
        ),
      ],
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
    if (_cameraController == null) {
      return Center(
        child: Text(
          'Controlador da câmera é nulo.\nPor favor, reinicie o aplicativo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (!_cameraController!.value.isInitialized) {
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
      return Container(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
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

  Widget _visualizarImagem() {
    return Container(
      width: double.infinity,
      child:
          _imagemCapturada != null
              ? FadeInImage(
                placeholder: AssetImage('assets/images/placeholder.png'),
                image: FileImage(_imagemCapturada!),
                fit: BoxFit.contain,
                imageErrorBuilder: (context, error, stackTrace) {
                  print('Erro ao carregar imagem: $error');
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Erro ao carregar imagem: $error'),
                    ],
                  );
                },
              )
              : const Center(child: Text('Nenhuma imagem capturada')),
    );
  }
}
