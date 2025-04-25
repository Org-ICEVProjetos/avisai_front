import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialManager {
  static const String _tutorialKey = 'tutorial_mostrado';

  // Verificar se o tutorial já foi mostrado
  static Future<bool> tutorialJaMostrado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialKey) ?? false;
  }

  // Marcar o tutorial como mostrado
  static Future<void> marcarTutorialComoMostrado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }

  // Resetar o status do tutorial (para testes)
  static Future<void> resetarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, false);
  }

  // Verificar e navegar com base no status do tutorial
  static Future<void> verificarENavegar(
    BuildContext context,
    Widget tutorialScreen,
    Widget homeScreen,
  ) async {
    final tutorialMostrado = await tutorialJaMostrado();

    if (!tutorialMostrado) {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => tutorialScreen),
        );
      }
    } else {
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => homeScreen));
      }
    }
  }
}
