import 'package:avisai4/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
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
    String? endereco = registro.endereco;
    String? rua = registro.rua;
    String? bairro = registro.bairro;
    String? cidade = registro.cidade;

    if ((endereco == null || endereco == 'Não disponível') &&
        _connectivityService.isOnline) {
      try {
        final dadosEndereco = await _locationService.getAddressFromCoordinates(
          registro.latitude,
          registro.longitude,
        );

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

    if (_connectivityService.isOnline) {
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

      await _apiProvider.enviarRegistro(registroAtualizado);
      await _localStorage.marcarRegistroComoSincronizado(registro.id!);
      return true;
    }

    return false;
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

    final Registro novoRegistro = Registro(
      id: _uuid.v4(),
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
      photoPath: caminhoFotoTemporario,
      observation: observation,
      status: StatusValidacao.pendente,
      sincronizado: false,
    );

    if (_connectivityService.isOnline) {
      try {
        await _sincronizarRegistro(novoRegistro);

        final registroSincronizado = novoRegistro.copyWith(sincronizado: true);
        await _localStorage.insertRegistro(registroSincronizado);

        return registroSincronizado;
      } catch (e) {
        if (e is ApiException &&
            (e.statusCode == 400 ||
                e.statusCode == 409 ||
                e.statusCode == 401)) {
          if (kDebugMode) {
            print(
              "Erro de validação do servidor - não salvando localmente: $e",
            );
          }
          rethrow;
        }

        if (kDebugMode) {
          print("Erro de conexão - salvando localmente: $e");
        }
        await _localStorage.insertRegistro(novoRegistro);

        return novoRegistro;
      }
    } else {
      await _localStorage.insertRegistro(novoRegistro);

      return novoRegistro;
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
    await _localStorage.deleteRegistro(registroId);
    if (_connectivityService.isOnline && isSincronizado) {
      await _apiProvider.removerRegistro(registroId);
    }
    return true;
  }
}
