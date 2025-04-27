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
      image: 'assets/images/onboarding_welcome.png',
      title: 'Bem-vindo ao ',
      titleHighlight: 'Avisaí',
      titleEnd: '',
      description: 'Ajude a transformar sua cidade com poucos toques na tela.',
      customTitle: true, // <- "Avis" e "aí" com cores diferentes
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_report.png',
      title: 'Registre uma ',
      titleHighlight: 'Irregularidade',
      titleEnd: '',
      description:
          'Tire uma foto, selecione o tipo de irregularidade e toque em "Enviar". A prefeitura será notificada',
      customDescription: true, // <- Colorir "prefeitura"
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_city.png',
      title: 'Transformando ',
      titleHighlight: 'Teresina',
      titleEnd: ' com você',
      description:
          'Cada registro ajuda a construir uma cidade mais segura, limpa e bem cuidada. Sua participação faz a diferença!',
      customDescription: true, // <- Colorir "segura", "limpa", "bem cuidada"
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
          onWillPop: () async => false, // Impedir voltar
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone da pasta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Icon(Icons.folder, color: Colors.orange, size: 48),
                    // SizedBox(width: 10),
                    const Text(
                      'Permissão de acesso',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),

                // Título
                const SizedBox(height: 16),

                // Corpo do texto
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontFamily: 'Inter',
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Para uma melhor experiência, é necessário permitir o acesso à ',
                      ),
                      TextSpan(
                        text: 'câmera',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ', à '),
                      TextSpan(
                        text: 'galeria de mídia',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' e à '),
                      TextSpan(
                        text: 'localização',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' do seu dispositivo.'),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Delay para abrir a solicitação de permissões
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        _solicitarPermissoes();
                      }
                      // Marcar que o tutorial já foi mostrado
                      _salvarTutorialMostrado();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF022865),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
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
            // Bottom navigation area with page dots on left, arrows on right
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators on left
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => buildPageIndicator(index == _currentPage),
                    ),
                  ),

                  // Navigation buttons together on right
                  Row(
                    children: [
                      // Back button (only visible after first page)
                      _currentPage > 0
                          ? Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              shape: BoxShape.circle,

                              border: Border.all(color: Colors.blue, width: 2),
                            ),

                            child: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              iconSize: 30,
                              color: const Color(0xFF022865),
                              onPressed: _previousPage,
                              padding: EdgeInsets.zero,
                            ),
                          )
                          : const SizedBox.shrink(),

                      // Next/Finish button
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFF022865),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          iconSize: 30,
                          color: Colors.white,
                          onPressed: _nextPage,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
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
      height: 14.0,
      width: 14.0,
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(30.0),
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
  final bool customTitle;
  final bool customDescription;

  OnboardingPageData({
    required this.image,
    required this.title,
    required this.titleHighlight,
    required this.titleEnd,
    required this.description,
    this.customTitle = false, // << Novo
    this.customDescription = false, // << Novo
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Image.asset(data.image, fit: BoxFit.contain, height: 420),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                data.customTitle
                    ? _buildCustomTitle(context)
                    : _buildDefaultTitle(context),
                const SizedBox(height: 16),
                data.customDescription
                    ? _buildCustomDescription(context)
                    : _buildDefaultDescription(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultTitle(BuildContext context) {
    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 40.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'Inter',
        ),
        children: [
          TextSpan(text: data.title),
          TextSpan(
            text: data.titleHighlight,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          TextSpan(text: data.titleEnd),
        ],
      ),
    );
  }

  Widget _buildCustomTitle(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 40.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        children: [
          TextSpan(
            text: data.title,
            style: const TextStyle(color: Colors.black87),
          ),
          TextSpan(text: 'Avis', style: TextStyle(color: primaryColor)),
          TextSpan(text: 'aí', style: TextStyle(color: secondaryColor)),
          TextSpan(
            text: data.titleEnd,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultDescription(BuildContext context) {
    return Text(
      data.description,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 20.0,
        color: Colors.grey[800],
        fontFamily: 'Inter',
        height: 1.4,
      ),
    );
  }

  Widget _buildCustomDescription(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    if (data.description.contains('prefeitura')) {
      // Segunda página
      final parts = data.description.split('prefeitura');
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.black87,
            fontFamily: 'Inter',
            height: 1.4,
          ),
          children: [
            TextSpan(text: parts[0], style: TextStyle(color: Colors.grey[800])),
            TextSpan(
              text: 'prefeitura',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: parts[1], style: TextStyle(color: Colors.grey[800])),
          ],
        ),
      );
    } else {
      // Terceira página
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.black87,
            fontFamily: 'Inter',
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: 'Cada registro ajuda a construir uma cidade mais ',
              style: TextStyle(color: Colors.grey[800]),
            ),
            TextSpan(
              text: 'segura',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: ', ', style: TextStyle(color: Colors.grey[800])),
            TextSpan(
              text: 'limpa',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: ' e ', style: TextStyle(color: Colors.grey[800])),
            TextSpan(
              text: 'bem cuidada',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '. Sua participação faz a diferença!',
              style: TextStyle(color: Colors.grey[800]),
            ),
          ],
        ),
      );
    }
  }
}
