import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../home/home_screen.dart';

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
      customTitle: true,
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_report.png',
      title: 'Registre uma ',
      titleHighlight: 'Irregularidade',
      titleEnd: '',
      description:
          'Tire uma foto, selecione o tipo de irregularidade e toque em "Enviar". A prefeitura será notificada',
      customDescription: true,
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_city.png',
      title: 'Transformando ',
      titleHighlight: 'Teresina',
      titleEnd: ' com você',
      description:
          'Cada registro ajuda a construir uma cidade mais segura, limpa e bem cuidada. Sua participação faz a diferença!',
      customDescription: true,
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
      _verificarPermissoes();
    }
  }

  Future<void> _salvarTutorialMostrado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_mostrado', true);
  }

  Future<void> _verificarPermissoes() async {
    final cameraStatus = await Permission.camera.isGranted;
    final locationStatus = await Permission.location.isGranted;
    final locationWhenInUseStatus =
        await Permission.locationWhenInUse.isGranted;

    if (!cameraStatus || !locationStatus || !locationWhenInUseStatus) {
      if (mounted) {
        _mostrarDialogoPermissoes();
      }
    } else {
      _navegarParaHome();
    }
  }

  void _mostrarDialogoPermissoes() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final Size screenSize = MediaQuery.of(context).size;
        final double screenWidth = screenSize.width;
        final double screenHeight = screenSize.height;

        final double iconSize = screenWidth * 0.12;
        final double titleFontSize = screenWidth * 0.05;
        final double bodyFontSize = screenWidth * 0.04;
        final double buttonHeight = screenHeight * 0.06;

        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
            ),
            contentPadding: EdgeInsets.fromLTRB(
              screenWidth * 0.06,
              screenHeight * 0.03,
              screenWidth * 0.06,
              0,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.folder, color: Colors.orange, size: iconSize),
                    Text(
                      'Permissão de acesso',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.02),

                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      color: Colors.black87,
                      fontFamily: 'Inter',
                      height: 1.5,
                    ),
                    children: const [
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
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: screenHeight * 0.03),
              ],
            ),
            actionsPadding: EdgeInsets.fromLTRB(
              screenWidth * 0.06,
              0,
              screenWidth * 0.06,
              screenHeight * 0.03,
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _solicitarPermissoes();
                    }

                    _salvarTutorialMostrado();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF022865),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.08),
                  ),
                  minimumSize: Size(double.infinity, buttonHeight),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      fontSize: bodyFontSize,
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
    try {
      await Permission.camera.request().timeout(
        Duration(seconds: 5),
        onTimeout: () => PermissionStatus.denied,
      );

      await Permission.location.request().timeout(
        Duration(seconds: 5),
        onTimeout: () => PermissionStatus.denied,
      );

      if (!mounted) return;

      await _verificarPermissoesNegadasPermanentemente();
      _navegarParaHome();
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao solicitar permissões: $e");
      }
      if (mounted) _navegarParaHome();
    }
  }

  Future<void> _verificarPermissoesNegadasPermanentemente() async {
    bool cameraPermanentlyDenied = await Permission.camera.isPermanentlyDenied;
    bool locationPermanentlyDenied =
        await Permission.location.isPermanentlyDenied;

    if (cameraPermanentlyDenied || locationPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final Size screenSize = MediaQuery.of(context).size;
            final double screenWidth = screenSize.width;
            final double screenHeight = screenSize.height;

            final double titleFontSize = screenWidth * 0.05;
            final double bodyFontSize = screenWidth * 0.04;
            final double buttonHeight = screenHeight * 0.06;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              contentPadding: EdgeInsets.fromLTRB(
                screenWidth * 0.06,
                screenHeight * 0.03,
                screenWidth * 0.06,
                screenHeight * 0.02,
              ),
              title: Text(
                'Permissões necessárias',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Algumas permissões necessárias foram negadas permanentemente. '
                'Para utilizar todas as funcionalidades do aplicativo, por favor, '
                'vá até as configurações do seu dispositivo e habilite as permissões solicitadas.\n\n'
                'Após habilitar as permissões, reinicie o aplicativo para que as alterações tenham efeito.',
                style: TextStyle(
                  fontSize: bodyFontSize,
                  color: Colors.black87,
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                screenWidth * 0.06,
                0,
                screenWidth * 0.06,
                screenHeight * 0.03,
              ),
              actions: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        openAppSettings();
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            _navegarParaHome();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF022865),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.08,
                          ),
                        ),
                        minimumSize: Size(double.infinity, buttonHeight),
                      ),
                      child: Text(
                        'Abrir configurações',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          fontSize: bodyFontSize,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navegarParaHome();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        minimumSize: Size(double.infinity, buttonHeight * 0.8),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
        return;
      }
    }
  }

  void _navegarParaHome() {
    _salvarPermissoesSolicitadas().then((_) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen(index: 1)),
        );
      } else if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen(index: 1)),
          (route) => false,
        );
      }
    });
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

            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => buildPageIndicator(index == _currentPage),
                    ),
                  ),

                  Row(
                    children: [
                      _currentPage > 0
                          ? Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[200],
                              shape: BoxShape.circle,

                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.5,
                              ),
                            ),

                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              iconSize: 35,
                              color: const Color(0xFF022865),
                              onPressed: _previousPage,
                              padding: EdgeInsets.zero,
                            ),
                          )
                          : const SizedBox.shrink(),

                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFF022865),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          iconSize: 35,
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
    this.customTitle = false,
    this.customDescription = false,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

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
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          TextSpan(text: data.titleEnd),
        ],
      ),
    );
  }

  Widget _buildCustomTitle(BuildContext context) {
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
          TextSpan(
            text: 'Avis',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
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
    if (data.description.contains('prefeitura')) {
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
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: parts[1], style: TextStyle(color: Colors.grey[800])),
          ],
        ),
      );
    } else {
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
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: ', ', style: TextStyle(color: Colors.grey[800])),
            TextSpan(
              text: 'limpa',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: ' e ', style: TextStyle(color: Colors.grey[800])),
            TextSpan(
              text: 'bem cuidada',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
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
