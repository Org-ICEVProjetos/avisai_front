import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:avisai4/services/user_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
  final StreamController<bool> _logoutForcadoController =
      StreamController<bool>.broadcast();
  Stream<bool> get logoutForcadoStream => _logoutForcadoController.stream;
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
      return {};
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
        return true;
      }

      int exp = decodedToken['exp'];
      int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return currentTime >= (exp - 30);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao decodificar token: $e');
      }
      return true;
    }
  }

  // Método público para validar e renovar token usando refresh token
  Future<bool> validarERenovarToken() async {
    if (_currentToken == null || _refreshToken == null) {
      _currentToken = await UserLocalStorage.obterToken();
      _refreshToken = await UserLocalStorage.obterRefreshToken();

      if (_currentToken != null) {
        configurarToken(_currentToken!);
      }
    }

    if (_refreshToken == null) {
      return false;
    }

    if (_currentToken != null && !isTokenExpired(_currentToken!)) {
      return true;
    }

    final renewed = await _refreshAccessToken();

    if (kDebugMode) {
      print('Renovação ${renewed ? 'bem-sucedida' : 'falhou'}');
    }

    return renewed;
  }

  // Método para atualizar o token usando refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) {
      if (kDebugMode) {
        print(
          'REFRESH TOKEN: Refresh token é nulo - logout forçado necessário',
        );
      }

      _logoutForcadoController.add(true);
      return false;
    }

    final url = Uri.parse('$baseUrl/auth/refresh-token');

    try {
      final headersSemAuth = Map<String, String>.from(headers);
      headersSemAuth.remove('Authorization');

      final response = await http.post(
        url,
        headers: headersSemAuth,
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        configurarToken(newToken);
        if (newRefreshToken != null) {
          configurarRefreshToken(newRefreshToken);
        }

        await UserLocalStorage.atualizarTokens(
          newToken,
          newRefreshToken ?? _refreshToken!,
        );

        return true;
      } else {
        if (kDebugMode) {
          print('REFRESH TOKEN: Falha - logout forçado necessário');
        }

        _logoutForcadoController.add(true);
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('REFRESH TOKEN: Erro - logout forçado necessário: $e');
      }
      _logoutForcadoController.add(true);
      return false;
    }
  }

  // Método genérico para fazer requisições com validação e atualização de token
  Future<http.Response> _requestWithTokenValidation({
    required Future<http.Response> Function() request,
    bool tentarRefresh = true,
  }) async {
    if (_currentToken == null) {
      _currentToken = await UserLocalStorage.obterToken();
      if (_currentToken != null) {
        configurarToken(_currentToken!);
      }
      _refreshToken ??= await UserLocalStorage.obterRefreshToken();
    }
    if (_currentToken != null &&
        tentarRefresh &&
        isTokenExpired(_currentToken!)) {
      final refreshSuccess = await _refreshAccessToken();

      if (!refreshSuccess && _refreshToken != null) {
        final backupToken = await UserLocalStorage.usarRefreshToken();
        if (backupToken != null) {
          configurarToken(backupToken);
        }
      }
    }

    try {
      final response = await request();

      if (response.statusCode == 401 && tentarRefresh) {
        final refreshSuccess = await _refreshAccessToken();

        if (refreshSuccess) {
          return await _requestWithTokenValidation(
            request: request,
            tentarRefresh: false,
          );
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Método auxiliar que retorna só os núemros do CPF
  String limparCPF(String cpfFormatado) {
    return cpfFormatado.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // Requisição de login
  Future<Map<String, dynamic>> login(String cpf, String senha) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'cpf': limparCPF(cpf), 'password': senha}),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        final token = dados['accessToken'];
        final refreshToken = dados['refreshToken'];

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
          _corrigirTextoAcentuado(erro['message']),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('clientexception') &&
          errorMessage.contains('socketexception')) {
        throw ApiException(
          'Servidor fora do ar no momento. Tente novamente mais tarde.',
        );
      } else if (errorMessage.contains('timeout') ||
          errorMessage.contains('handshake')) {
        throw ApiException(
          'Problema de conectividade. Verifique sua conexão com a internet.',
        );
      } else if (errorMessage.contains('host lookup failed')) {
        throw ApiException(
          'Sem conexão com a internet. Verifique sua conectividade.',
        );
      } else {
        throw ApiException('Erro de conexão: ${e.toString()}');
      }
    }
  }

  // Requisição de registro de conta
  Future<Map<String, dynamic>> registrarUsuario(
    Usuario usuario,
    String senha,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');

    try {
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

      if (response.statusCode == 201) {
        final dados = jsonDecode(utf8.decode(response.bodyBytes));
        final token = dados['accessToken'];
        final refreshToken = dados['refreshToken'];

        configurarToken(token);
        if (refreshToken != null) {
          configurarRefreshToken(refreshToken);
        }

        Map<String, dynamic> dadosCorrigidos = Map<String, dynamic>.from(dados);

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
            _corrigirTextoAcentuado(erro['message']),
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
      if (kDebugMode) {
        print(e.toString());
      }
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  // Requisição de registro de conta
  Future<bool> excluirUsuario(Usuario usuario) async {
    final url = Uri.parse('$baseUrl/user/delete');

    try {
      final headersCorrected = {
        ...headers,
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
      };

      final response = await http.delete(url, headers: headersCorrected);

      if (response.statusCode == 204) {
        _logoutForcadoController.add(true);
        return true;
      } else {
        if (response.body.isNotEmpty) {
          final erro = jsonDecode(utf8.decode(response.bodyBytes));
          throw ApiException(
            _corrigirTextoAcentuado(erro['message']),
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
      if (kDebugMode) {
        print(e.toString());
      }
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  // Método para corrigir textos com problemas de codificação
  String _corrigirTextoAcentuado(String texto) {
    final Map<String, String> substituicoes = {
      'Ã£': 'ã',
      'Ã¡': 'á',
      'Ã©': 'é',
      'Ã³': 'ó',
      'Ãº': 'ú',
      'Ã§': 'ç',
      'Ã': 'Á',
      'Ãª': 'ê',
      'Áª': 'ê',
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

  // Requisição de solicitação de recuepração de senha
  Future<bool> recuperarSenha(String cpf, String email) async {
    final url = Uri.parse('$baseUrl/password/forgot');

    try {
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
          _corrigirTextoAcentuado(erro['message']),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  // Requisição que valida código manadado pela solicitação de alteração de senha
  Future<bool> validarTokenSenha(String token) async {
    final url = Uri.parse('$baseUrl/password/validate');

    try {
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
          _corrigirTextoAcentuado(erro['message']),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  // Requisição que altera a senha de fato
  Future<bool> alterarSenha(String senha, String token) async {
    final url = Uri.parse('$baseUrl/password/change/$token');

    try {
      final response = await _requestWithTokenValidation(
        request:
            () => http.post(
              url,
              headers: headers,
              body: jsonEncode({'newPassword': senha}),
            ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          _corrigirTextoAcentuado(erro['message']),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  // Baixa a imagem da URL e salva no cache
  Future<String> _baixarImagemDaUrlParaCache(
    String urlRemota,
    String nomeArquivo,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/cache_imagens');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final nomeComExtensao = '$nomeArquivo.jpg';
    final pathDestino = '${cacheDir.path}/$nomeComExtensao';
    final arquivoDestino = File(pathDestino);

    if (await arquivoDestino.exists()) {
      return pathDestino;
    }

    try {
      final response = await http
          .get(
            Uri.parse(urlRemota),
            headers: {'User-Agent': 'Mozilla/5.0 (compatible; Flutter)'},
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        await arquivoDestino.writeAsBytes(response.bodyBytes);

        return pathDestino;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      if (kDebugMode) {
        print("Timeout na requisição");
      }
      throw Exception('Timeout ao baixar imagem');
    } on SocketException catch (e) {
      if (kDebugMode) {
        print("Erro de conexão: $e");
      }
      throw Exception('Erro de conexão: $e');
    } catch (e) {
      if (kDebugMode) {
        print("Erro geral: $e");
      }
      throw Exception('Erro ao baixar imagem: $e');
    }
  }

  // Salva a imagem da URL e salva no cache
  Future<String> _moverParaCacheComNome(
    String pathTemporario,
    String nomeArquivo,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/cache_imagens');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final nomeComExtensao =
        nomeArquivo.endsWith('.jpg') ? nomeArquivo : '$nomeArquivo.jpg';

    final pathDestino = '${cacheDir.path}/$nomeComExtensao';
    final arquivoDestino = File(pathDestino);

    if (await arquivoDestino.exists()) {
      return pathDestino;
    }

    final arquivoTemporario = File(pathTemporario);
    if (await arquivoTemporario.exists()) {
      await arquivoTemporario.copy(pathDestino);
    } else {
      throw Exception('Arquivo temporário não encontrado: $pathTemporario');
    }

    return pathDestino;
  }

  // Requisição que envia um novo registro
  Future<Registro> enviarRegistro(Registro registro) async {
    final url = Uri.parse('$baseUrl/pothole-reports/create');
    File foto = File(registro.photoPath);

    if (kDebugMode) {}

    try {
      http.MultipartRequest criarRequest() {
        final request = http.MultipartRequest('POST', url);

        final headersWithoutContentType = Map<String, String>.from(headers);
        headersWithoutContentType.remove('Content-Type');
        request.headers.addAll(headersWithoutContentType);

        final dadosRegistro = registro.toApiJson();
        dadosRegistro.forEach((key, value) {
          if (value != null && key != 'photoPath') {
            request.fields[key] = value.toString();
          }
        });

        return request;
      }

      Future<void> adicionarArquivo(http.MultipartRequest request) async {
        if (await foto.exists()) {
          final multipartFile = await http.MultipartFile.fromPath(
            'photoPath',
            foto.path,
          );
          request.files.add(multipartFile);
        }
      }

      var request = criarRequest();
      await adicionarArquivo(request);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        final refreshSuccess = await _refreshAccessToken();

        if (refreshSuccess) {
          request = criarRequest();
          await adicionarArquivo(request);

          streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        } else {
          throw ApiException(
            'Não foi possível atualizar o token',
            statusCode: 401,
          );
        }
      }

      if (response.statusCode == 201) {
        final dados = jsonDecode(response.body);
        Registro registroRetornado = Registro.fromJson(
          dados as Map<String, dynamic>,
        );

        final fileNovo = await _moverParaCacheComNome(
          registro.photoPath,
          registro.id!,
        );

        final registroComFotoLocal = registroRetornado.copyWith(
          photoPath: fileNovo,
        );

        return registroComFotoLocal;
      } else {
        final body = response.body;
        String mensagem = 'Erro ao enviar registro';
        if (body.isNotEmpty) {
          try {
            final erro = jsonDecode(body);
            mensagem = _corrigirTextoAcentuado(erro['message']);
          } catch (_) {
            mensagem = 'Erro ${response.statusCode}: $body';
          }
        }
        throw ApiException(mensagem, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;

      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('clientexception') &&
          errorMessage.contains('socketexception')) {
        throw ApiException(
          'Servidor fora do ar no momento. Tente novamente mais tarde.',
        );
      }

      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  // Requisição que obtém registros
  Future<List<Registro>> obterRegistros() async {
    final url = Uri.parse('$baseUrl/pothole-reports');

    try {
      final headersCorrected = {
        ...headers,
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
      };

      final response = await _requestWithTokenValidation(
        request: () => http.get(url, headers: headersCorrected),
      );

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> dados = jsonDecode(decodedBody);

        List<Registro> registros = [];
        for (var item in dados) {
          try {
            final registro = Registro.fromJson(item as Map<String, dynamic>);

            // Baixa e salva a imagem no cache se ela vier como URL
            Registro registroComCache = registro;
            if (registro.photoPath.startsWith('http')) {
              try {
                final pathLocal = await _baixarImagemDaUrlParaCache(
                  registro.photoPath,
                  registro.id!,
                );
                registroComCache = registro.copyWith(photoPath: pathLocal);
              } catch (e) {
                if (kDebugMode) {
                  print("Erro ao baixar imagem do registro ${registro.id}: $e");
                }
              }
            }

            registros.add(registroComCache);
            if (kDebugMode) {}
          } catch (e) {
            if (kDebugMode) {
              print("Erro ao converter registro: $e");
            }
          }
        }

        return registros;
      } else {
        final erro = jsonDecode(utf8.decode(response.bodyBytes));
        throw ApiException(
          _corrigirTextoAcentuado(erro['message']),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao obter registros: $e");
      }
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  //   Requisição que remove registros
  Future<bool> removerRegistro(String registroId) async {
    final url = Uri.parse('$baseUrl/pothole-reports/$registroId');

    try {
      final response = await _requestWithTokenValidation(
        request: () => http.delete(url, headers: headers),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          _corrigirTextoAcentuado(erro['message']),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }
}
