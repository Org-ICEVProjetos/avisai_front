import 'dart:convert';
import 'dart:io';
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

  // Método para configurar o token
  void configurarToken(String token) {
    headers['Authorization'] = 'Bearer $token';
  }

  Future<Map<String, dynamic>> login(String cpf, String senha) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'cpf': cpf, 'senha': senha}),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        final token = dados['token'];

        // Configurar o token para as próximas requisições
        configurarToken(token);

        return {'usuario': Usuario.fromJson(dados['usuario']), 'token': token};
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
    final url = Uri.parse('$baseUrl/auth/registrar');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'nome': usuario.nome,
          'cpf': usuario.cpf,
          'email': usuario.email,
          'senha': senha,
        }),
      );

      if (response.statusCode == 201) {
        final dados = jsonDecode(response.body);
        final token = dados['token'];

        // Configurar o token para as próximas requisições
        configurarToken(token);

        return {'usuario': Usuario.fromJson(dados['usuario']), 'token': token};
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao registrar usuário',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  Future<bool> recuperarSenha(String cpf, String email) async {
    final url = Uri.parse('$baseUrl/auth/recuperar-senha');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'cpf': cpf, 'email': email}),
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

  Future<Registro> enviarRegistro(Registro registro) async {
    final url = Uri.parse('$baseUrl/registros');

    try {
      // Criar o objeto de dados para enviar
      final dadosRegistro = registro.toJson();

      // Remover campos desnecessários para a API
      dadosRegistro.remove('id');
      dadosRegistro.remove('sincronizado');

      // Enviar tudo como uma única requisição JSON, incluindo o base64
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(dadosRegistro),
      );

      if (response.statusCode == 201) {
        final dados = jsonDecode(response.body);
        return Registro.fromJson(dados);
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao enviar registro',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  Future<List<Registro>> obterRegistros() async {
    final url = Uri.parse('$baseUrl/registros');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> dados = jsonDecode(response.body);
        return dados.map((item) => Registro.fromJson(item)).toList();
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao obter registros',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  Future<bool> removerRegistro(String registroId) async {
    final url = Uri.parse('$baseUrl/registros/$registroId');

    try {
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
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

  Future<Registro> validarRegistro(
    String registroId,
    String validadorId,
  ) async {
    final url = Uri.parse('$baseUrl/registros/$registroId/validar');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'validadorId': validadorId}),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        return Registro.fromJson(dados);
      } else {
        final erro = jsonDecode(response.body);
        throw ApiException(
          erro['mensagem'] ?? 'Erro ao validar registro',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }
}
