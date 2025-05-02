import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class CustomCameraPreview extends StatefulWidget {
  final CameraController? controller;
  final Function(File)? onCapture;
  final Function()? onSwitchCamera;
  final Function()? onGallerySelect;
  final double aspectRatio;
  final bool showControls;
  final File? imageFile;

  const CustomCameraPreview({
    super.key,
    this.controller,
    this.onCapture,
    this.onSwitchCamera,
    this.onGallerySelect,
    this.aspectRatio = 4 / 3,
    this.showControls = true,
    this.imageFile,
  });

  @override
  _CustomCameraPreviewState createState() => _CustomCameraPreviewState();
}

class _CustomCameraPreviewState extends State<CustomCameraPreview> {
  bool _isCapturing = false;
  bool _hasFlash = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _checkFlashAvailability();
  }

  Future<void> _checkFlashAvailability() async {
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return;
    }

    try {
      // Verificar se a câmera tem flash usando a propriedade disponível
      setState(() {
        _hasFlash = widget.controller!.value.flashMode != null;
      });
    } catch (e) {
      setState(() {
        _hasFlash = false;
      });
      print('Erro ao verificar flash: $e');
    }
  }

  Future<void> _switchFlashMode() async {
    if (widget.controller == null ||
        !widget.controller!.value.isInitialized ||
        !_hasFlash) {
      return;
    }

    try {
      FlashMode newMode;

      switch (widget.controller!.value.flashMode) {
        case FlashMode.off:
          newMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          newMode = FlashMode.always;
          break;
        case FlashMode.always:
          newMode = FlashMode.torch;
          break;
        case FlashMode.torch:
          newMode = FlashMode.off;
          break;
      }

      await widget.controller!.setFlashMode(newMode);

      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      print('Erro ao trocar modo do flash: $e');
    }
  }

  Future<void> _captureImage() async {
    if (widget.controller == null ||
        !widget.controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      final xFile = await widget.controller!.takePicture();
      final file = File(xFile.path);

      if (widget.onCapture != null) {
        widget.onCapture!(file);
      }
    } catch (e) {
      print('Erro ao capturar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao capturar imagem. Tente novamente.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Icon _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return const Icon(Icons.flash_off, color: Colors.white);
      case FlashMode.auto:
        return const Icon(Icons.flash_auto, color: Colors.white);
      case FlashMode.always:
        return const Icon(Icons.flash_on, color: Colors.white);
      case FlashMode.torch:
        return const Icon(Icons.highlight, color: Colors.amber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preview da câmera ou imagem capturada
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Imagem capturada ou preview da câmera
              if (widget.imageFile != null)
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.file(widget.imageFile!, fit: BoxFit.contain),
                )
              else if (widget.controller != null &&
                  widget.controller!.value.isInitialized)
                AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: CameraPreview(widget.controller!),
                )
              else
                const Center(child: CircularProgressIndicator()),

              // Indicador de carregamento ao capturar
              if (_isCapturing)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),

              // Overlay de grade para ajudar no enquadramento
              if (widget.controller != null &&
                  widget.controller!.value.isInitialized &&
                  widget.imageFile == null)
                _buildGridOverlay(),

              // Botão de flash no canto superior
              if (_hasFlash &&
                  widget.controller != null &&
                  widget.controller!.value.isInitialized &&
                  widget.imageFile == null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _getFlashIcon(),
                      onPressed: _switchFlashMode,
                      tooltip: 'Alterar modo do flash',
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Controles da câmera
        if (widget.showControls && widget.imageFile == null)
          _buildCameraControls(),
      ],
    );
  }

  Widget _buildGridOverlay() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(painter: GridPainter()),
    );
  }

  Widget _buildCameraControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botão de galeria
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            onPressed: widget.onGallerySelect,
            tooltip: 'Selecionar da galeria',
          ),

          // Botão de captura
          GestureDetector(
            onTap: _captureImage,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Botão de trocar câmera
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: widget.onSwitchCamera,
            tooltip: 'Trocar câmera',
          ),
        ],
      ),
    );
  }
}

// Painter para desenhar a grade
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1;

    // Linhas horizontais
    final double tercoAltura = size.height / 3;
    canvas.drawLine(
      Offset(0, tercoAltura),
      Offset(size.width, tercoAltura),
      paint,
    );
    canvas.drawLine(
      Offset(0, tercoAltura * 2),
      Offset(size.width, tercoAltura * 2),
      paint,
    );

    // Linhas verticais
    final double tercoLargura = size.width / 3;
    canvas.drawLine(
      Offset(tercoLargura, 0),
      Offset(tercoLargura, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(tercoLargura * 2, 0),
      Offset(tercoLargura * 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
