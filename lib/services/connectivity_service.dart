import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  void initialize() {
    // Verificar estado inicial da conexão
    _checkConnectivity();

    // Ouvir mudanças na conectividade
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      if (results.isNotEmpty) {
        _updateConnectionStatus(results);
      } else {
        _connectionStatusController.add(false);
        _isOnline = false;
      }
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
      _connectionStatusController.add(false);
      _isOnline = false;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Consideramos online se qualquer um dos resultados for diferente de "none"
    bool isConnected =
        results.any((result) => result != ConnectivityResult.none);
    _connectionStatusController.add(isConnected);
    _isOnline = isConnected;
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
