import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/usuario.dart';

class UserLocalStorage {
  static const String _keyUsuario = 'usuario_dados';
  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken =
      'refresh_token'; // Nova chave para o refresh token
  static const String _keyAutenticado = 'usuario_autenticado';

  // Salvar os dados do usuário, token e refresh token
  static Future<bool> salvarUsuario(
    Usuario usuario,
    String token, {
    String? refreshToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Converter objeto Usuario para Map
      final Map<String, dynamic> usuarioMap = {
        'id': usuario.id,
        'nome': usuario.nome,
        'cpf': usuario.cpf,
        'email': usuario.email,
        // Não armazenamos a senha por segurança
      };

      // Salvar dados em formato JSON
      final String usuarioJson = jsonEncode(usuarioMap);
      await prefs.setString(_keyUsuario, usuarioJson);

      // Salvar o token de autenticação
      await prefs.setString(_keyToken, token);

      // Salvar o refresh token se fornecido
      if (refreshToken != null) {
        await prefs.setString(_keyRefreshToken, refreshToken);
      }

      // Marcar que há um usuário autenticado
      await prefs.setBool(_keyAutenticado, true);

      print('Dados do usuário, token e refresh token salvos localmente');
      return true;
    } catch (e) {
      print('Erro ao salvar dados do usuário: $e');
      return false;
    }
  }

  // Obter os dados do usuário
  static Future<Usuario?> obterUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usuarioJson = prefs.getString(_keyUsuario);

      if (usuarioJson == null) {
        return null;
      }

      final Map<String, dynamic> usuarioMap = jsonDecode(usuarioJson);

      // Criar objeto Usuario a partir do Map
      return Usuario(
        id: usuarioMap['id'],
        nome: usuarioMap['nome'],
        cpf: usuarioMap['cpf'],
        email: usuarioMap['email'],
        senha: '', // Não armazenamos a senha
      );
    } catch (e) {
      print('Erro ao obter dados do usuário: $e');
      return null;
    }
  }

  // Obter o token de autenticação
  static Future<String?> obterToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e) {
      print('Erro ao obter token: $e');
      return null;
    }
  }

  // Obter o refresh token
  static Future<String?> obterRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    } catch (e) {
      print('Erro ao obter refresh token: $e');
      return null;
    }
  }

  // Usar o refresh token e promovê-lo para o token principal
  // Retorna o novo refresh token se fornecido pelo servidor
  static Future<String?> usarRefreshToken({String? novoRefreshToken}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_keyRefreshToken);

      if (refreshToken == null) {
        return null;
      }

      // Promove o refresh token para o token principal
      await prefs.setString(_keyToken, refreshToken);

      // Salva o novo refresh token se fornecido
      if (novoRefreshToken != null) {
        await prefs.setString(_keyRefreshToken, novoRefreshToken);
      } else {
        // Se não for fornecido um novo refresh token, removemos o atual
        // pois já foi promovido a token principal
        await prefs.remove(_keyRefreshToken);
      }

      return refreshToken;
    } catch (e) {
      print('Erro ao usar refresh token: $e');
      return null;
    }
  }

  // Verificar se existe usuário autenticado
  static Future<bool> verificarUsuarioAutenticado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAutenticado) ?? false;
    } catch (e) {
      print('Erro ao verificar autenticação: $e');
      return false;
    }
  }

  // Verificar se existe refresh token disponível
  static Future<bool> temRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_keyRefreshToken);
      return refreshToken != null && refreshToken.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar refresh token: $e');
      return false;
    }
  }

  // Remover os dados do usuário (logout)
  static Future<bool> removerUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUsuario);
      await prefs.remove(_keyToken);
      await prefs.remove(_keyRefreshToken); // Também remove o refresh token
      await prefs.setBool(_keyAutenticado, false);

      print('Dados do usuário, token e refresh token removidos localmente');
      return true;
    } catch (e) {
      print('Erro ao remover dados do usuário: $e');
      return false;
    }
  }

  // Atualizar tokens sem alterar os dados do usuário
  static Future<bool> atualizarTokens(
    String novoToken,
    String novoRefreshToken,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, novoToken);
      await prefs.setString(_keyRefreshToken, novoRefreshToken);
      return true;
    } catch (e) {
      print('Erro ao atualizar tokens: $e');
      return false;
    }
  }

  // Verificar e obter dados para login automático
  static Future<Map<String, dynamic>?> obterDadosLoginAutomatico() async {
    final autenticado = await verificarUsuarioAutenticado();
    if (autenticado) {
      final usuario = await obterUsuario();
      final token = await obterToken();
      final refreshToken = await obterRefreshToken();

      if (usuario != null && token != null) {
        return {
          'usuario': usuario,
          'token': token,
          'refreshToken': refreshToken,
        };
      }
    }
    return null;
  }
}
