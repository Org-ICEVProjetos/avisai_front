import 'package:avisai4/services/user_storage_service.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_storage_service.dart';
import '../models/usuario.dart';
import '../providers/api_provider.dart';

class AuthRepository {
  final ApiProvider _apiProvider;

  AuthRepository({
    required ApiProvider apiProvider,
    required LocalStorageService localStorageService,
    required SharedPreferences prefs,
  }) : _apiProvider = apiProvider;

  // Checa autenticação a partir do que está salvo localemnete
  Future<Usuario?> checarAutenticacao() async {
    final dadosAutenticacao =
        await UserLocalStorage.obterDadosLoginAutomatico();

    if (dadosAutenticacao != null) {
      final usuario = dadosAutenticacao['usuario'] as Usuario;
      final token = dadosAutenticacao['token'] as String;

      _apiProvider.configurarToken(token);

      return usuario;
    }

    return null;
  }

  //Validar tokens para login automático
  Future<Usuario?> validarTokenERenovar() async {
    try {
      final tokenValido = await _apiProvider.validarERenovarToken();

      if (tokenValido) {
        return await UserLocalStorage.obterUsuario();
      } else {
        await UserLocalStorage.removerUsuario();
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao validar token: $e');
      }
      await UserLocalStorage.removerUsuario();
      return null;
    }
  }

  // Chama a API para requisção de login e salva usuário localmente
  Future<Usuario> login(String cpf, String senha) async {
    try {
      final resultado = await _apiProvider.login(cpf, senha);
      final usuario = resultado['usuario'] as Usuario;
      final token = resultado['accessToken'] as String;
      final refreshToken = resultado['refreshToken'] as String;

      await UserLocalStorage.salvarUsuario(
        usuario,
        token,
        refreshToken: refreshToken,
      );

      return usuario;
    } catch (e) {
      rethrow;
    }
  }

  // Chama a API para solicitação de registro e salva usuário localmente
  Future<Usuario> registrar(
    String nome,
    String cpf,
    String email,
    String senha,
  ) async {
    try {
      final usuario = Usuario(
        id: null,
        nome: nome,
        cpf: cpf,
        email: email,
        senha: senha,
      );

      final resultado = await _apiProvider.registrarUsuario(usuario, senha);
      final usuarioRegistrado = resultado['usuario'] as Usuario;
      final token = resultado['accessToken'] as String;

      await UserLocalStorage.salvarUsuario(usuarioRegistrado, token);

      return usuarioRegistrado;
    } catch (e) {
      rethrow;
    }
  }

  // Chama API para solicitação de recuperação de senha
  Future<bool> recuperarSenha(String cpf, String email) async {
    try {
      return await _apiProvider.recuperarSenha(cpf, email);
    } catch (e) {
      rethrow;
    }
  }

  // Chama API para requisição de validação de código de alteração de senha
  Future<bool> validarTokenSenha(String token) async {
    try {
      return await _apiProvider.validarTokenSenha(token);
    } catch (e) {
      rethrow;
    }
  }

  // Chama API para requisição de mudança de senha
  Future<bool> alterarSenha(String senha, String token) async {
    try {
      return await _apiProvider.alterarSenha(senha, token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _apiProvider.headers.remove('Authorization');
  }
}
