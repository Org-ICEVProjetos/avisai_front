import 'package:avisai4/services/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_storage_service.dart';
import '../models/usuario.dart';
import '../providers/api_provider.dart';

class AuthRepository {
  final ApiProvider _apiProvider;
  final LocalStorageService _localStorage;

  AuthRepository({
    required ApiProvider apiProvider,
    required LocalStorageService localStorageService,
    required SharedPreferences prefs,
  }) : _apiProvider = apiProvider,
       _localStorage = localStorageService;

  Future<Usuario?> checarAutenticacao() async {
    // Buscar dados de autenticação
    final dadosAutenticacao =
        await UserLocalStorage.obterDadosLoginAutomatico();

    if (dadosAutenticacao != null) {
      final usuario = dadosAutenticacao['usuario'] as Usuario;
      final token = dadosAutenticacao['token'] as String;

      // Configurar o token no apiProvider
      _apiProvider.configurarToken(token);

      return usuario;
    }

    return null;
  }

  Future<Usuario> login(String cpf, String senha) async {
    try {
      final resultado = await _apiProvider.login(cpf, senha);
      final usuario = resultado['usuario'] as Usuario;
      final token = resultado['accessToken'] as String;
      final refreshToken = resultado['refreshToken'] as String;

      // Salvar dados localmente
      await UserLocalStorage.salvarUsuario(
        usuario,
        token,
        refreshToken: refreshToken,
      );

      return usuario;
    } catch (e) {
      // Verificar se há um usuário local com essas credenciais
      // Nota: Isso deve ser removido em produção, pois o login offline sem token
      // não é compatível com o novo esquema de autenticação
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

      final resultado = await _apiProvider.registrarUsuario(usuario, senha);
      final usuarioRegistrado = resultado['usuario'] as Usuario;
      final token = resultado['accessToken'] as String;

      // Salvar dados localmente
      await UserLocalStorage.salvarUsuario(usuarioRegistrado, token);

      // Também salvar no banco de dados local para uso offline
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

  Future<bool> validarTokenSenha(String token) async {
    try {
      return await _apiProvider.validarTokenSenha(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> alterarSenha(String senha, String token) async {
    try {
      return await _apiProvider.alterarSenha(senha, token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    // Remover dados locais
    await UserLocalStorage.removerUsuario();

    // Limpar token do cabeçalho HTTP
    _apiProvider.headers.remove('Authorization');
  }
}
