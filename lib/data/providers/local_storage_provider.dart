import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/registro.dart';
import '../models/usuario.dart';
import '../models/categoria.dart';

class LocalStorageProvider {
  static final LocalStorageProvider _instance =
      LocalStorageProvider._internal();
  factory LocalStorageProvider() => _instance;
  LocalStorageProvider._internal();

  late SharedPreferences _prefs;

  static const String _usuarioKey = 'usuario_atual';
  static const String _registrosKey = 'registros_locais';
  static const String _categoriasKey = 'categorias';
  static const String _ultimaSincronizacaoKey = 'ultima_sincronizacao';
  static const String _configuracaoAppKey = 'configuracao_app';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> salvarUsuarioAtual(Usuario usuario) async {
    final usuarioJson = usuario.toJson();
    await _prefs.setString(_usuarioKey, jsonEncode(usuarioJson));
  }

  Future<Usuario?> obterUsuarioAtual() async {
    final usuarioString = _prefs.getString(_usuarioKey);
    if (usuarioString == null) return null;

    try {
      final usuarioJson = jsonDecode(usuarioString);
      return Usuario.fromJson(usuarioJson);
    } catch (e) {
      print('Erro ao decodificar usuário: $e');
      return null;
    }
  }

  Future<void> removerUsuarioAtual() async {
    await _prefs.remove(_usuarioKey);
  }

  Future<void> salvarRegistrosLocais(List<Registro> registros) async {
    final registrosJson = registros.map((r) => r.toJson()).toList();
    await _prefs.setString(_registrosKey, jsonEncode(registrosJson));
  }

  Future<List<Registro>> obterRegistrosLocais() async {
    final registrosString = _prefs.getString(_registrosKey);
    if (registrosString == null) return [];

    try {
      final registrosJson = jsonDecode(registrosString) as List;
      return registrosJson.map((json) => Registro.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao decodificar registros: $e');
      return [];
    }
  }

  Future<void> adicionarRegistro(Registro registro) async {
    final registros = await obterRegistrosLocais();
    registros.add(registro);
    await salvarRegistrosLocais(registros);
  }

  Future<void> atualizarRegistro(Registro registro) async {
    final registros = await obterRegistrosLocais();
    final index = registros.indexWhere((r) => r.id == registro.id);

    if (index >= 0) {
      registros[index] = registro;
      await salvarRegistrosLocais(registros);
    }
  }

  Future<void> removerRegistro(String registroId) async {
    final registros = await obterRegistrosLocais();
    registros.removeWhere((r) => r.id == registroId);
    await salvarRegistrosLocais(registros);
  }

  Future<void> limparRegistros() async {
    await _prefs.remove(_registrosKey);
  }

  Future<void> salvarCategorias(List<Categoria> categorias) async {
    final categoriasJson = categorias.map((c) => c.toJson()).toList();
    await _prefs.setString(_categoriasKey, jsonEncode(categoriasJson));
  }

  Future<List<Categoria>> obterCategorias() async {
    final categoriasString = _prefs.getString(_categoriasKey);

    if (categoriasString == null) {
      final categoriasDefault = Categoria.getCategoriasDefault();
      await salvarCategorias(categoriasDefault);
      return categoriasDefault;
    }

    try {
      final categoriasJson = jsonDecode(categoriasString) as List;
      return categoriasJson.map((json) => Categoria.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao decodificar categorias: $e');
      return Categoria.getCategoriasDefault();
    }
  }

  Future<void> salvarUltimaSincronizacao() async {
    await _prefs.setString(
      _ultimaSincronizacaoKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> obterUltimaSincronizacao() async {
    final dataString = _prefs.getString(_ultimaSincronizacaoKey);
    if (dataString == null) return null;

    try {
      return DateTime.parse(dataString);
    } catch (e) {
      print('Erro ao obter data de sincronização: $e');
      return null;
    }
  }

  Future<void> salvarConfiguracaoApp(Map<String, dynamic> config) async {
    await _prefs.setString(_configuracaoAppKey, jsonEncode(config));
  }

  Future<Map<String, dynamic>> obterConfiguracaoApp() async {
    final configString = _prefs.getString(_configuracaoAppKey);
    if (configString == null) {
      final configPadrao = {
        'notificacoesAtivas': true,
        'temaPadrao': 'sistema',
        'idioma': 'pt_BR',
        'sincronizacaoAutomatica': true,
        'qualidadeImagem': 'media',
      };
      await salvarConfiguracaoApp(configPadrao);
      return configPadrao;
    }

    try {
      return jsonDecode(configString);
    } catch (e) {
      print('Erro ao decodificar configurações: $e');
      return {};
    }
  }

  Future<void> atualizarItemConfiguracaoApp(String chave, dynamic valor) async {
    final config = await obterConfiguracaoApp();
    config[chave] = valor;
    await salvarConfiguracaoApp(config);
  }

  Future<void> limparTodosDados() async {
    await _prefs.clear();
  }
}
