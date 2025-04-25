import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../home/home_screen.dart';
import '../../../bloc/auth/auth_bloc.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      image: 'assets/images/onboarding_city.png',
      title: 'Transformando',
      titleHighlight: 'Teresina',
      titleEnd: ' com você',
      description:
          'Cada registro ajuda a construir uma cidade mais segura, limpa e bem cuidada. Sua participação faz a diferença!',
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_report.png',
      title: 'Registre uma',
      titleHighlight: 'Irregularidade',
      titleEnd: '',
      description:
          'Viu um problema na cidade? Tire uma foto, selecione o tipo de irregularidade e toque em "Enviar". A prefeitura será notificada.',
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_welcome.png',
      title: 'Bem-vindo ao',
      titleHighlight: 'Avisaí',
      titleEnd: '',
      description: 'Ajude a transformar sua cidade com poucos toques na tela.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Marcar que o tutorial já foi mostrado
      _salvarTutorialMostrado();

      // Verificar permissões antes de ir para a Home
      _verificarPermissoes();
    }
  }

  Future<void> _salvarTutorialMostrado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_mostrado', true);
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
    } else {
      // Todas as permissões já estão concedidas, ir direto para Home
      _navegarParaHome();
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
    // Solicitar permissão da câmera
    PermissionStatus cameraStatus = await Permission.camera.request();

    // Solicitar permissão de localização
    PermissionStatus locationStatus = await Permission.location.request();

    if (mounted) {
      // Verificar se alguma permissão foi negada permanentemente
      await _verificarPermissoesNegadasPermanentemente();

      // Navegar para a Home independentemente do resultado das permissões
      _navegarParaHome();
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
                    _navegarParaHome();
                  },
                ),
                TextButton(
                  child: const Text('Abrir configurações'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        _navegarParaHome();
                      }
                    });
                  },
                ),
              ],
            );
          },
        );
        // O método _navegarParaHome será chamado nos botões do diálogo
        return;
      }
    }
  }

  void _navegarParaHome() {
    // Salvar que as permissões já foram solicitadas
    _salvarPermissoesSolicitadas();

    // Navegar para a tela Home
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen(index: 1)),
      );
    }
  }

  Future<void> _salvarPermissoesSolicitadas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissoes_solicitadas', true);
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(data: _pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  // Indicadores de página
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => buildPageIndicator(index == _currentPage),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões de navegação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão Voltar (visível apenas após a primeira página)
                      _currentPage > 0
                          ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _previousPage,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.blue[700],
                              padding: const EdgeInsets.all(12),
                              shape: const CircleBorder(),
                            ),
                          )
                          : const SizedBox(
                            width: 48,
                          ), // Espaço vazio na primeira página
                      // Botão Avançar/Concluir
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _nextPage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[700] : Colors.grey[300],
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

// Dados para cada página do onboarding
class OnboardingPageData {
  final String image;
  final String title;
  final String titleHighlight;
  final String titleEnd;
  final String description;

  OnboardingPageData({
    required this.image,
    required this.title,
    required this.titleHighlight,
    required this.titleEnd,
    required this.description,
  });
}

// Widget para cada página do onboarding
class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Image.asset(data.image, fit: BoxFit.contain)),
          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: [
                TextSpan(text: data.title),
                TextSpan(
                  text: data.titleHighlight,
                  style: TextStyle(color: Colors.blue[700]),
                ),
                TextSpan(text: data.titleEnd),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
