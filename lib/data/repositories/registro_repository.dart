import 'dart:convert';
import 'dart:io';
import 'package:avisai4/services/local_storage_service.dart';
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

  // Construtor com injeção de dependências
  RegistroRepository({
    required LocalStorageService localStorageService,
    required ApiProvider apiProvider,
    required LocationService locationService,
  }) : _localStorage = localStorageService,
       _apiProvider = apiProvider,
       _locationService = locationService,
       _connectivityService = ConnectivityService();

  // Converter foto para base64
  Future<String> _converterFotoParaBase64(String caminhoFotoTemporario) async {
    try {
      final File arquivoOriginal = File(caminhoFotoTemporario);
      final bytes = await arquivoOriginal.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('Erro ao converter foto para base64: $e');
      // Em caso de erro, retornar uma string vazia ou tratar como apropriado
      return '';
    }
  }

  // Sincroniza um registro com o servidor
  Future<bool> _sincronizarRegistro(Registro registro) async {
    try {
      // Primeiro, verificar se é necessário atualizar os dados de endereço
      String? endereco = registro.endereco;
      String? rua = registro.rua;
      String? bairro = registro.bairro;
      String? cidade = registro.cidade;

      // Se os dados de endereço estão indisponíveis e agora temos internet,
      // vamos tentar obter o endereço usando as coordenadas salvas
      if ((endereco == null || endereco == 'Não disponível') &&
          _connectivityService.isOnline) {
        try {
          final dadosEndereco = await _locationService
              .getAddressFromCoordinates(registro.latitude, registro.longitude);

          endereco = dadosEndereco['endereco'];
          rua = dadosEndereco['rua'];
          bairro = dadosEndereco['bairro'];
          cidade = dadosEndereco['cidade'];
        } catch (e) {
          print('Erro ao obter endereço atualizado: $e');
          // Manter os valores originais em caso de erro
        }
      }

      // Atualizar o registro com os novos dados de endereço, se disponíveis
      if (_connectivityService.isOnline) {
        final registroAtualizado = registro.copyWith(
          endereco: endereco,
          rua: rua,
          bairro: bairro,
          cidade: cidade,
        );

        // Salvar as atualizações localmente primeiro
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
    } catch (e) {
      print('Erro ao sincronizar registro: $e');
      return false;
    }
  }

  // Tenta sincronizar todos os registros pendentes
  Future<int> sincronizarRegistrosPendentes() async {
    if (!_connectivityService.isOnline) return 0;

    // Buscar todos os registros não sincronizados
    final registrosNaoSincronizados =
        await _localStorage.getRegistrosNaoSincronizados();

    int sincronizados = 0;

    // Tentar sincronizar cada um
    for (final registro in registrosNaoSincronizados) {
      final sucesso = await _sincronizarRegistro(registro);
      if (sucesso) sincronizados++;
    }

    return sincronizados;
  }

  // Criar um novo registro
  Future<Registro> criarRegistro({
    required String usuarioId,
    required String usuarioNome,
    required CategoriaIrregularidade categoria,
    required String caminhoFotoTemporario,
    required double latitudeAtual,
    required double longitudeAtual,
  }) async {
    // Obter endereço baseado na localização
    Map<String, String> dadosEndereco;
    try {
      dadosEndereco = await _locationService.getAddressFromCoordinates(
        latitudeAtual,
        longitudeAtual,
      );
    } catch (e) {
      print('Erro ao obter endereço (usando padrão): $e');
      dadosEndereco = {
        'endereco': 'Não disponível',
        'rua': 'Não disponível',
        'bairro': 'Não disponível',
        'cidade': 'Não disponível',
      };
    }

    // Converter a foto para base64
    String fotoBase64;
    try {
      fotoBase64 = await _converterFotoParaBase64(caminhoFotoTemporario);
    } catch (e) {
      print('Erro ao converter foto para base64: $e');
      fotoBase64 = ''; // String vazia em caso de erro
    }

    // Criar objeto registro
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
      base64Foto: fotoBase64,
      status: StatusValidacao.pendente,
      sincronizado: false, // Sempre false inicialmente
    );

    // Salvar no armazenamento local
    await _localStorage.insertRegistro(novoRegistro);
    print(
      "Registro criado e salvo localmente: ID=${novoRegistro.id}, usuarioId=${novoRegistro.usuarioId}",
    );

    // Tentar sincronizar com o servidor, se estiver online
    if (_connectivityService.isOnline) {
      try {
        // Usar apenas _sincronizarRegistro, não chamar a API diretamente depois
        final sincronizou = await _sincronizarRegistro(novoRegistro);
        print(
          "Tentativa de sincronização: ${sincronizou ? 'Sucesso' : 'Falha'}",
        );
      } catch (e) {
        print('Erro ao sincronizar com a API (ignorado): $e');
      }
    }

    return novoRegistro;
  }

  Future<List<Registro>> obterTodosRegistros() async {
    // Verificar se está online
    if (_connectivityService.isOnline) {
      try {
        // Tentar buscar dados do servidor
        final registrosServidor = await _apiProvider.obterRegistros();
        // Atualizar banco local com dados do servidor
        for (var registro in registrosServidor) {
          await _localStorage.insertRegistro(registro);
        }
        return await _localStorage.getRegistros();
      } catch (e) {
        print('Erro ao buscar registros do servidor: $e');
        return await _localStorage.getRegistros();
      }
    } else {
      return await _localStorage.getRegistros();
    }
  }

  // Remover um registro
  Future<bool> removerRegistro(String registroId) async {
    try {
      await _localStorage.deleteRegistro(registroId);

      // Se estiver online, notificar o servidor sobre a remoção
      if (_connectivityService.isOnline) {
        await _apiProvider.removerRegistro(registroId);
      }

      return true;
    } catch (e) {
      print('Erro ao remover registro: $e');
      return false;
    }
  }
}
