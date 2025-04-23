import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/usuario.dart';

class UserLocalStorage {
  static const String _keyUsuario = 'usuario_dados';
  static const String _keyAutenticado = 'usuario_autenticado';

  // Salvar os dados do usuário
  static Future<bool> salvarUsuario(Usuario usuario) async {
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

      // Marcar que há um usuário autenticado
      await prefs.setBool(_keyAutenticado, true);

      print('Dados do usuário salvos localmente');
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

  // Remover os dados do usuário (logout)
  static Future<bool> removerUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUsuario);
      await prefs.setBool(_keyAutenticado, false);

      print('Dados do usuário removidos localmente');
      return true;
    } catch (e) {
      print('Erro ao remover dados do usuário: $e');
      return false;
    }
  }

  // Verificar e obter dados para login automático
  static Future<Usuario?> obterDadosLoginAutomatico() async {
    final autenticado = await verificarUsuarioAutenticado();
    if (autenticado) {
      return await obterUsuario();
    }
    return null;
  }
}
