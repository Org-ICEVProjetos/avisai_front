import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_storage_service.dart';
import '../models/usuario.dart';
import '../providers/api_provider.dart';

class AuthRepository {
  final ApiProvider _apiProvider;
  final LocalStorageService _localStorage;
  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _usuarioIdKey = 'usuario_id';
  static const String _usuarioNomeKey = 'usuario_nome';
  static const String _usuarioCpfKey = 'usuario_cpf';

  AuthRepository({
    required ApiProvider apiProvider,
    required LocalStorageService localStorageService,
    required SharedPreferences prefs,
  })  : _apiProvider = apiProvider,
        _localStorage = localStorageService,
        _prefs = prefs;

  Future<Usuario?> checarAutenticacao() async {
    final token = _prefs.getString(_tokenKey);
    final usuarioId = _prefs.getString(_usuarioIdKey);
    final usuarioNome = _prefs.getString(_usuarioNomeKey);
    final usuarioCpf = _prefs.getString(_usuarioCpfKey);

    if (token != null &&
        usuarioId != null &&
        usuarioNome != null &&
        usuarioCpf != null) {
      _apiProvider.headers['Authorization'] = 'Bearer $token';

      return Usuario(
        id: usuarioId,
        nome: usuarioNome,
        cpf: usuarioCpf,
        email: '',
        senha: '',
      );
    }

    return null;
  }

  Future<Usuario> login(String cpf, String senha) async {
    try {
      final usuario = await _apiProvider.login(cpf, senha);

      _salvarDadosAutenticacao(usuario);

      return usuario;
    } catch (e) {
      final usuarioLocal = await _localStorage.getUsuario(cpf);

      if (usuarioLocal != null && usuarioLocal.senha == senha) {
        _salvarDadosAutenticacao(usuarioLocal);

        return usuarioLocal;
      }

      rethrow;
    }
  }

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

      final usuarioRegistrado = await _apiProvider.registrarUsuario(
        usuario,
        senha,
      );

      _salvarDadosAutenticacao(usuarioRegistrado);

      await _localStorage.insertUsuario(usuarioRegistrado);

      return usuarioRegistrado;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> recuperarSenha(String cpf, String email) async {
    try {
      return await _apiProvider.recuperarSenha(cpf, email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_usuarioIdKey);
    await _prefs.remove(_usuarioNomeKey);
    await _prefs.remove(_usuarioCpfKey);

    _apiProvider.headers.remove('Authorization');
  }

  void _salvarDadosAutenticacao(Usuario usuario) {
    final token = _apiProvider.headers['Authorization']?.replaceFirst(
      'Bearer ',
      '',
    );

    if (token != null) {
      _prefs.setString(_tokenKey, token);
    }

    _prefs.setString(_usuarioIdKey, usuario.id!);
    _prefs.setString(_usuarioNomeKey, usuario.nome);
    _prefs.setString(_usuarioCpfKey, usuario.cpf);
  }
}
