import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';

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

  //Inicializa serviço de conexão
  void initialize() {
    _checkConnectivity();
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  // Checa qual a coenxão atual
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
      if (kDebugMode) {
        print('Erro ao verificar conectividade: $e');
      }
      _connectionStatusController.add(false);
      _isOnline = false;
    }
  }

  // Atualiza status de conexão atual
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    _connectionStatusController.add(isConnected);
    _isOnline = isConnected;
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
