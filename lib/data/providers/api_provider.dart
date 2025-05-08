import 'dart:convert';
import 'package:avisai4/services/user_storage.dart';
import 'package:http/http.dart' as http;
import '../models/registro.dart';
import '../models/usuario.dart';
import '../../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

class ApiProvider {
  final String baseUrl = ApiConfig.baseUrl;
  final Map<String, String> headers = {'Content-Type': 'application/json'};
  String? _currentToken;
  String? _refreshToken;

  // Método para configurar o token
  void configurarToken(String token) {
    _currentToken = token;
    headers['Authorization'] = 'Bearer $token';
  }

  // Método para configurar o refresh token
  void configurarRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
  }

  // Método para limpar os tokens
  void limparTokens() {
    headers.remove('Authorization');
    _currentToken = null;
    _refreshToken = null;
  }

  // Método para decodificar JWT
  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return {}; // Token inválido
    }

    final payload = parts[1];
    var normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> payloadMap = json.decode(resp);

    return payloadMap;
  }

  // Método para verificar se o token está expirado
  bool isTokenExpired(String token) {
    try {
      Map<String, dynamic> decodedToken = _decodeJwt(token);
      if (!decodedToken.containsKey('exp')) {
        return true; // Se não tiver exp, consideramos expirado para forçar renovação
      }

      int exp = decodedToken['exp'];
      int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Verificar se expira em menos de 30 segundos (margem de segurança)
      return currentTime >= (exp - 30);
    } catch (e) {
      print('Erro ao decodificar token: $e');
      return true; // Em caso de erro, consideramos expirado
    }
  }

  // Método para atualizar o token usando refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) {
      return false;
    }

    final url = Uri.parse('$baseUrl/auth/refresh-token');

    try {
      // Removemos o token de autorização temporariamente
      final headersSemAuth = Map<String, String>.from(headers);
      headersSemAuth.remove('Authorization');

      final response = await http.post(
        url,
        headers: headersSemAuth,
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        final newRefreshToken = data['refreshToken']; // pode existir ou não

        // Atualiza tokens na memória
        configurarToken(newToken);

        if (newRefreshToken != null) {
          configurarRefreshToken(newRefreshToken);
        }

        // Atualiza no storage
        await UserLocalStorage.atualizarTokens(
          newToken,
          newRefreshToken ?? _refreshToken!,
        );

        return true;
      } else {
        print('Falha ao atualizar token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erro ao atualizar token: $e');
      return false;
    }
  }

  // Método genérico para fazer requisições com validação e atualização de token
  Future<http.Response> _requestWithTokenValidation({
    required Future<http.Response> Function() request,
    bool tentarRefresh = true,
  }) async {
    // Verifica se temos um token atual
    if (_currentToken == null) {
      // Tenta recuperar o token do storage
      _currentToken = await UserLocalStorage.obterToken();
      if (_currentToken != null) {
        configurarToken(_currentToken!);
      }

      // Tenta recuperar o refresh token se necessário
      if (_refreshToken == null) {
        _refreshToken = await UserLocalStorage.obterRefreshToken();
      }
    }

    // Se temos token e está expirado, tenta refresh
    if (_currentToken != null &&
        tentarRefresh &&
        isTokenExpired(_currentToken!)) {
      final refreshSuccess = await _refreshAccessToken();

      // Se falhou e temos um backup de refresh token, tenta usá-lo
      if (!refreshSuccess && _refreshToken != null) {
        // Promover o refresh token para token principal como último recurso
        final backupToken = await UserLocalStorage.usarRefreshToken();
        if (backupToken != null) {
          configurarToken(backupToken);
        }
      }
    }

    // Realiza a requisição
    try {
      final response = await request();

      // Se recebeu 401 durante a requisição e é a primeira tentativa
      if (response.statusCode == 401 && tentarRefresh) {
        final refreshSuccess = await _refreshAccessToken();

        if (refreshSuccess) {
          // Tenta novamente com o novo token
          return await _requestWithTokenValidation(
            request: request,
            tentarRefresh: false, // Evita loop infinito
          );
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  String limparCPF(String cpfFormatado) {
    return cpfFormatado.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<Map<String, dynamic>> login(String cpf, String senha) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'cpf': limparCPF(cpf), 'password': senha}),
      );

      print("Body: ${response.body}");
      print("Status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        final token = dados['accessToken'];
        final refreshToken =
            dados['refreshToken']; // nome pode variar conforme API

        // Configurar o token para as próximas requisições
        configurarToken(token);
        if (refreshToken != null) {
          configurarRefreshToken(refreshToken);
        }

        return {
          'usuario': Usuario.fromJson(dados as Map<String, dynamic>),
          'accessToken': token,
          'refreshToken': refreshToken,
        };
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao fazer login',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> registrarUsuario(
    Usuario usuario,
    String senha,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');

    try {
      // Definindo o charset no header
      final headersCorrected = {
        ...headers,
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
      };

      final response = await http.post(
        url,
        headers: headersCorrected,
        body: jsonEncode({
          'name': usuario.nome,
          'cpf': limparCPF(usuario.cpf),
          'email': usuario.email,
          'password': senha,
        }),
      );

      print("Status code: ${response.statusCode}");

      if (response.statusCode == 201) {
        // Adicionando charset na decodificação do JSON
        final dados = jsonDecode(utf8.decode(response.bodyBytes));
        final token = dados['accessToken'];
        final refreshToken =
            dados['refreshToken']; // nome pode variar conforme API

        // Configurar o token para as próximas requisições
        configurarToken(token);
        if (refreshToken != null) {
          configurarRefreshToken(refreshToken);
        }

        // Aplicar correções de codificação antes de criar o objeto Usuario
        Map<String, dynamic> dadosCorrigidos = Map<String, dynamic>.from(dados);

        // Corrigir nome se necessário
        if (dadosCorrigidos.containsKey('name') &&
            dadosCorrigidos['name'] != null) {
          dadosCorrigidos['name'] = _corrigirTextoAcentuado(
            dadosCorrigidos['name'],
          );
        }

        return {
          'usuario': Usuario.fromJson(dadosCorrigidos),
          'accessToken': token,
          'refreshToken': refreshToken,
        };
      } else {
        if (response.body.isNotEmpty) {
          final erro = jsonDecode(utf8.decode(response.bodyBytes));
          throw ApiException(
            erro['mensagem'] ?? 'Erro ao registrar usuário',
            statusCode: response.statusCode,
          );
        } else {
          throw ApiException(
            'Erro ao registrar usuário. Resposta vazia.',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      print(e.toString());
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  // Método para corrigir textos com problemas de codificação
  String _corrigirTextoAcentuado(String texto) {
    // Mapeamento de padrões de texto com codificação incorreta
    final Map<String, String> substituicoes = {
      'Ã£': 'ã',
      'Ã¡': 'á',
      'Ã©': 'é',
      'Ã³': 'ó',
      'Ãº': 'ú',
      'Ã§': 'ç',
      'Ã': 'Á',
      'Ãª': 'ê',
      'Ã¢': 'â',
      'Ãµ': 'õ',
      'Ã­': 'í',
      'Ã´': 'ô',
    };

    String resultado = texto;
    substituicoes.forEach((padrao, substituto) {
      resultado = resultado.replaceAll(padrao, substituto);
    });

    return resultado;
  }

  Future<bool> recuperarSenha(String cpf, String email) async {
    final url = Uri.parse('$baseUrl/password/forgot');

    try {
      // Usamos o método com validação de token
      final response = await _requestWithTokenValidation(
        request:
            () => http.post(
              url,
              headers: headers,
              body: jsonEncode({'cpf': limparCPF(cpf), 'email': email}),
            ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao recuperar senha',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  Future<bool> validarTokenSenha(String token) async {
    final url = Uri.parse('$baseUrl/password/validate');

    try {
      // Usamos o método com validação de token
      final response = await _requestWithTokenValidation(
        request:
            () => http.post(
              url,
              headers: headers,
              body: jsonEncode({'token': token}),
            ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao validar código',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  Future<bool> alterarSenha(String senha, String token) async {
    final url = Uri.parse('$baseUrl/password/change/$token');

    try {
      // Usamos o método com validação de token
      final response = await _requestWithTokenValidation(
        request:
            () => http.post(
              url,
              headers: headers,
              body: jsonEncode({'password': senha}),
            ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao trocar de senha',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  Future<bool> logout() async {
    final url = Uri.parse('$baseUrl/auth/logout');

    try {
      // Simplesmente tentamos fazer logout sem verificar token
      // Pois mesmo se falhar, limparemos os tokens localmente
      final response = await http.post(url, headers: headers);

      // Independente do resultado, limpar os tokens da memória
      limparTokens();

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Erro ao fazer logout no servidor: $e');
      return false;
    }
  }

  Future<Registro> enviarRegistro(Registro registro) async {
    final url = Uri.parse('$baseUrl/pothole-reports/create');

    try {
      // Usar toApiJson() em vez de toJson()
      final dadosRegistro = registro.toApiJson();

      print('Enviando para $url');

      // Enviar com validação de token
      final response = await _requestWithTokenValidation(
        request:
            () => http.post(
              url,
              headers: headers,
              body: jsonEncode(dadosRegistro),
            ),
      );

      print("Status code: ${response.statusCode}");

      if (response.statusCode == 201) {
        final dados = jsonDecode(response.body);
        return Registro.fromJson(dados as Map<String, dynamic>);
      } else {
        final body = response.body;
        String mensagem = 'Erro ao enviar registro';
        if (body.isNotEmpty) {
          try {
            final erro = jsonDecode(body);
            mensagem = erro['mensagem'] ?? mensagem;
          } catch (_) {
            mensagem = 'Erro ${response.statusCode}: $body';
          }
        }
        throw ApiException(mensagem, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  Future<List<Registro>> obterRegistros() async {
    final url = Uri.parse('$baseUrl/pothole-reports');

    try {
      // Definir charset nos headers
      final headersCorrected = {
        ...headers,
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
      };

      // Usar com validação de token
      final response = await _requestWithTokenValidation(
        request: () => http.get(url, headers: headersCorrected),
      );

      print("Status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Decodificar o corpo da resposta usando UTF-8
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> dados = jsonDecode(decodedBody);

        print("Número de registros recebidos: ${dados.length}");

        List<Registro> registros = [];
        for (var item in dados) {
          try {
            final registro = Registro.fromJson(item as Map<String, dynamic>);
            registros.add(registro);
            print(
              "Registro adicionado: ID=${registro.id}, usuarioId=${registro.usuarioId}",
            );
          } catch (e) {
            print("Erro ao converter registro: $e");
          }
        }

        return registros;
      } else {
        final erro = jsonDecode(utf8.decode(response.bodyBytes));
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao obter registros',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print("Erro ao obter registros: $e");
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  Future<bool> removerRegistro(String registroId) async {
    final url = Uri.parse('$baseUrl/pothole-reports/$registroId');

    try {
      // Usar com validação de token
      final response = await _requestWithTokenValidation(
        request: () => http.delete(url, headers: headers),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao remover registro',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }
}
