import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraException implements Exception {
  final String message;

  CameraException(this.message);

  @override
  String toString() => 'CameraException: $message';
}

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  List<CameraDescription>? cameras;
  CameraController? controller;
  bool _initialized = false;

  // Inicializar câmeras disponíveis
  Future<void> initialize() async {
    if (_initialized) return;

    // Verificar permissão
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission.isDenied) {
      throw CameraException('Permissão de câmera negada');
    }

    try {
      // Obter câmeras disponíveis
      cameras = await availableCameras();
      _initialized = true;
    } on CameraException catch (e) {
      throw CameraException('Erro ao inicializar câmeras: ${e.toString()}');
    }
  }

  // Criar e inicializar o controlador de câmera
  Future<CameraController> initializeController({
    ResolutionPreset resolution = ResolutionPreset.high,
    CameraLensDirection lensDirection = CameraLensDirection.back,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (cameras == null || cameras!.isEmpty) {
      throw CameraException('Nenhuma câmera disponível');
    }

    // Buscar a câmera com a direção solicitada (traseira por padrão)
    CameraDescription? camera;
    for (var cam in cameras!) {
      if (cam.lensDirection == lensDirection) {
        camera = cam;
        break;
      }
    }

    // Se não encontrar a câmera solicitada, usar a primeira disponível
    camera ??= cameras!.first;

    // Configurar o controlador
    final cameraController = CameraController(
      camera,
      resolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Inicializar o controlador
    try {
      await cameraController.initialize();
      controller = cameraController;
      return cameraController;
    } catch (e) {
      throw CameraException(
          'Erro ao inicializar controlador de câmera: ${e.toString()}');
    }
  }

  // Tirar uma foto
  Future<File> tirarFoto() async {
    if (controller == null || !controller!.value.isInitialized) {
      throw CameraException('Controlador de câmera não inicializado');
    }

    try {
      // Capturar imagem
      final XFile foto = await controller!.takePicture();

      // Verificar resultado
      final File arquivo = File(foto.path);
      if (!await arquivo.exists()) {
        throw CameraException('Erro ao salvar foto');
      }

      return arquivo;
    } catch (e) {
      throw CameraException('Erro ao tirar foto: ${e.toString()}');
    }
  }

  // Selecionar imagem da galeria
  Future<File?> selecionarDaGaleria() async {
    try {
      final permissao = await Permission.photos.request();
      if (permissao.isDenied) {
        throw CameraException('Permissão de acesso à galeria negada');
      }

      final picker = ImagePicker();
      final XFile? imagem = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (imagem == null) {
        return null; // Usuário cancelou a seleção
      }

      return File(imagem.path);
    } catch (e) {
      throw CameraException('Erro ao selecionar imagem: ${e.toString()}');
    }
  }

  // Salvar imagem no armazenamento permanente
  Future<File> salvarImagemPermanente(File imagemTemporaria) async {
    try {
      // Obter diretório de documentos
      final Directory diretorioDocumentos =
          await getApplicationDocumentsDirectory();
      final pastaFotos = Directory('${diretorioDocumentos.path}/fotos');

      // Criar pasta se não existir
      if (!await pastaFotos.exists()) {
        await pastaFotos.create(recursive: true);
      }

      // Gerar nome único para arquivo
      final String nomeArquivo =
          'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String caminhoDestino = path.join(pastaFotos.path, nomeArquivo);

      // Copiar arquivo
      return await imagemTemporaria.copy(caminhoDestino);
    } catch (e) {
      throw CameraException('Erro ao salvar imagem: ${e.toString()}');
    }
  }

  // Liberar recursos
  void dispose() {
    controller?.dispose();
    controller = null;
  }
}
