import 'dart:io';

import 'package:avisai4/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/registro.dart';
import '../../services/location_service.dart';
import '../../services/connectivity_service.dart';
import '../providers/api_provider.dart';

class RegistroRepository {
  final LocalStorageService _localStorage;
  final ApiProvider _apiProvider;
  final LocationService _locationService;
  final ConnectivityService _connectivityService;
  final _uuid = Uuid();

  RegistroRepository({
    required LocalStorageService localStorageService,
    required ApiProvider apiProvider,
    required LocationService locationService,
  }) : _localStorage = localStorageService,
       _apiProvider = apiProvider,
       _locationService = locationService,
       _connectivityService = ConnectivityService();

  // Sincroniza registros que não estão salvos no banco mas estão salvos localmente
  Future<bool> _sincronizarRegistro(Registro registro) async {
    try {
      String? endereco = registro.endereco;
      String? rua = registro.rua;
      String? bairro = registro.bairro;
      String? cidade = registro.cidade;

      bool conectividadeReal = _connectivityService.isOnline;

      if (!conectividadeReal) {
        return false;
      }

      if ((endereco == null || endereco == 'Não disponível')) {
        try {
          final dadosEndereco = await _locationService
              .getAddressFromCoordinates(registro.latitude, registro.longitude)
              .timeout(Duration(seconds: 10));

          endereco = dadosEndereco['endereco'];
          rua = dadosEndereco['rua'];
          bairro = dadosEndereco['bairro'];
          cidade = dadosEndereco['cidade'];
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao obter endereço atualizado: $e');
          }
        }
      }

      final registroAtualizado = registro.copyWith(
        endereco: endereco,
        rua: rua,
        bairro: bairro,
        cidade: cidade,
      );

      if (endereco != registro.endereco ||
          rua != registro.rua ||
          bairro != registro.bairro ||
          cidade != registro.cidade) {
        await _localStorage.updateRegistro(registroAtualizado);
      }

      await _tentarEnviarComRetry(registroAtualizado, maxTentativas: 2);

      await _localStorage.marcarRegistroComoSincronizado(registro.id!);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro na sincronização do registro a ${registro.id}: $e');
      }
      rethrow;
    }
  }

  Future<void> _tentarEnviarComRetry(
    Registro registro, {
    int maxTentativas = 2,
  }) async {
    for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
      try {
        await _apiProvider
            .enviarRegistro(registro)
            .timeout(
              Duration(seconds: 15),
              onTimeout: () {
                throw Exception(
                  'Timeout na sincronização (tentativa $tentativa/$maxTentativas)',
                );
              },
            );
        return;
      } catch (e) {
        if (tentativa == maxTentativas) {
          // if (e.toString() ==
          //     "ApiException: Irregularidade já registrada dentro de 10 metros (Status Code: 400)") {
          //   _localStorage.deleteRegistro(registro.id!);
          // }
          rethrow;
        }

        if (kDebugMode) {
          print('Tentativa $tentativa falhou para registro ${registro.id}: $e');
        }

        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  // Tenta sincronizar todos os registros pendentes
  Future<int> sincronizarRegistrosPendentes() async {
    if (!_connectivityService.isOnline) return 0;

    final registrosNaoSincronizados =
        await _localStorage.getRegistrosNaoSincronizados();

    int sincronizados = 0;

    for (final registro in registrosNaoSincronizados) {
      final sucesso = await _sincronizarRegistro(registro);
      if (sucesso) sincronizados++;
    }

    return sincronizados;
  }

  Future<Registro> criarRegistro({
    required String usuarioId,
    required String usuarioNome,
    required CategoriaIrregularidade categoria,
    required String caminhoFotoTemporario,
    required double latitudeAtual,
    required double longitudeAtual,
    String? observation,
  }) async {
    // Gerar ID primeiro
    final String registroId = _uuid.v4();

    Map<String, String> dadosEndereco;
    try {
      dadosEndereco = await _locationService.getAddressFromCoordinates(
        latitudeAtual,
        longitudeAtual,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter endereço (usando padrão): $e');
      }
      dadosEndereco = {
        'endereco': 'Não disponível',
        'rua': 'Não disponível',
        'bairro': 'Não disponível',
        'cidade': 'Não disponível',
      };
    }

    String caminhoImagemFinal;
    try {
      caminhoImagemFinal = await _processarImagem(
        caminhoFotoTemporario,
        registroId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao processar imagem: $e');
      }
      caminhoImagemFinal = caminhoFotoTemporario;
    }

    final Registro novoRegistro = Registro(
      id: registroId,
      usuarioId: usuarioId,
      usuarioNome: usuarioNome,
      categoria: categoria,
      dataHora: DateTime.now(),
      latitude: latitudeAtual,
      longitude: longitudeAtual,
      endereco: dadosEndereco['endereco'],
      rua: dadosEndereco['rua'],
      bairro: dadosEndereco['bairro'],
      cidade: dadosEndereco['cidade'],
      photoPath: caminhoImagemFinal,
      observation: observation,
      status: StatusValidacao.pendente,
      sincronizado: false,
    );
    await _localStorage.insertRegistro(novoRegistro);
    bool conectividadeReal = _connectivityService.isOnline;
    print("AQUI: $conectividadeReal");
    if (conectividadeReal) {
      try {
        bool sincronizado = await _sincronizarRegistro(novoRegistro);

        if (sincronizado) {
          final registros = await _localStorage.getRegistros();
          final registroAtualizado = registros.firstWhere(
            (r) => r.id == novoRegistro.id,
          );
          return registroAtualizado;
        }
      } catch (e) {
        if (e is ApiException &&
            (e.statusCode == 400 ||
                e.statusCode == 409 ||
                e.statusCode == 401)) {
          if (kDebugMode) {
            print(
              "Erro de validação do servidor - removendo registro local: $e",
            );
          }
          // Limpar imagem antes de remover registro
          await _limparImagem(caminhoImagemFinal);
          await _localStorage.deleteRegistro(novoRegistro.id!);
          rethrow;
        }

        if (kDebugMode) {
          print("Erro de conexão - mantendo registro local: $e");
        }
      }
    }

    return novoRegistro;
  }

  // Novo método para processar imagem
  Future<String> _processarImagem(
    String caminhoTemporario,
    String registroId,
  ) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagensDir = '${appDir.path}/cache_imagens';

      final Directory dir = Directory(imagensDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String nomeArquivo = '$registroId.jpg';
      final String caminhoFinal = '$imagensDir/$nomeArquivo';

      final File arquivoTemporario = File(caminhoTemporario);
      if (!await arquivoTemporario.exists()) {
        throw Exception(
          'Arquivo temporário não encontrado: $caminhoTemporario',
        );
      }

      final File arquivoFinal = await arquivoTemporario.copy(caminhoFinal);

      if (!await arquivoFinal.exists()) {
        throw Exception('Falha ao copiar imagem para local definitivo');
      }
      final int tamanhoOriginal = await arquivoTemporario.length();
      final int tamanhoFinal = await arquivoFinal.length();

      if (tamanhoOriginal != tamanhoFinal) {
        throw Exception(
          'Tamanhos diferentes após cópia: $tamanhoOriginal vs $tamanhoFinal',
        );
      }
      try {
        await arquivoTemporario.delete();
      } catch (e) {
        if (kDebugMode) {
          print('Aviso: Não foi possível deletar arquivo temporário: $e');
        }
      }

      if (kDebugMode) {
        print(
          'Imagem processada com sucesso: $caminhoTemporario -> $caminhoFinal',
        );
      }

      return caminhoFinal;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao processar imagem: $e');
      }
      rethrow;
    }
  }

  // Método para limpar imagem
  Future<void> _limparImagem(String caminhoImagem) async {
    try {
      final File arquivo = File(caminhoImagem);
      if (await arquivo.exists()) {
        await arquivo.delete();
        if (kDebugMode) {
          print('Imagem removida: $caminhoImagem');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao remover imagem: $e');
      }
    }
  }

  // Solicita todos os registros para a API
  Future<List<Registro>> obterTodosRegistros() async {
    if (_connectivityService.isOnline) {
      try {
        final registrosServidor = await _apiProvider.obterRegistros();
        final registrosLocais = await _localStorage.getRegistros();

        Set<String> idsServidor = registrosServidor.map((r) => r.id!).toSet();

        final registrosLocaisNaoSincronizados =
            registrosLocais
                .where((r) => !r.sincronizado && !idsServidor.contains(r.id))
                .toList();

        for (var registro in registrosServidor) {
          await _localStorage.insertRegistro(registro);
        }

        return [...registrosServidor, ...registrosLocaisNaoSincronizados];
      } catch (e) {
        return await _localStorage.getRegistros();
      }
    } else {
      return await _localStorage.getRegistros();
    }
  }

  // Solicita a remoção de um registro para a API
  Future<bool> removerRegistro(String registroId, bool isSincronizado) async {
    final registros = await _localStorage.getRegistros();
    final registro = registros.where((r) => r.id == registroId).firstOrNull;

    await _localStorage.deleteRegistro(registroId);

    if (registro != null) {
      await _limparImagem(registro.photoPath);
    }

    if (_connectivityService.isOnline && isSincronizado) {
      await _apiProvider.removerRegistro(registroId);
    }
    return true;
  }
}
