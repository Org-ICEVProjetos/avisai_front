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
        final dadosEndereco = await _locationService.getAddressFromCoordinates(
          registro.latitude,
          registro.longitude,
        );

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

      // A exceção será propagada se houver erro
      await _apiProvider.enviarRegistro(registroAtualizado);
      await _localStorage.marcarRegistroComoSincronizado(registro.id!);
      return true;
    }

    return false;
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

  Future<Registro> criarRegistro({
    required String usuarioId,
    required String usuarioNome,
    required CategoriaIrregularidade categoria,
    required String caminhoFotoTemporario,
    required double latitudeAtual,
    required double longitudeAtual,
    String? observation, // NOVO PARÂMETRO
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
      observation: observation, // NOVO CAMPO
      status: StatusValidacao.pendente,
      sincronizado: false,
    );

    // Se estiver online, tenta enviar diretamente
    if (_connectivityService.isOnline) {
      try {
        // Tenta sincronizar imediatamente
        await _sincronizarRegistro(novoRegistro);

        // Se chegou até aqui, foi sincronizado com sucesso
        // Agora salva local com sincronizado = true
        final registroSincronizado = novoRegistro.copyWith(sincronizado: true);
        await _localStorage.insertRegistro(registroSincronizado);

        print("Registro criado e sincronizado: ID=${novoRegistro.id}");
        return registroSincronizado;
      } catch (e) {
        // Se for erro de validação do servidor (como buraco próximo),
        // não salva localmente e propaga o erro
        if (e is ApiException && (e.statusCode == 400 || e.statusCode == 409)) {
          print("Erro de validação do servidor - não salvando localmente: $e");
          rethrow; // Propaga o erro sem salvar localmente
        }

        // Se for erro de conexão ou outro erro de rede,
        // salva localmente para sincronizar depois
        print("Erro de conexão - salvando localmente: $e");
        await _localStorage.insertRegistro(novoRegistro);
        print(
          "Registro salvo localmente para sincronização posterior: ID=${novoRegistro.id}",
        );
        return novoRegistro;
      }
    } else {
      // Offline - salva localmente
      await _localStorage.insertRegistro(novoRegistro);
      print("Offline - registro salvo localmente: ID=${novoRegistro.id}");
      return novoRegistro;
    }
  }

  Future<List<Registro>> obterTodosRegistros() async {
    // Verificar se está online
    if (_connectivityService.isOnline) {
      // Tentar buscar dados do servidor
      // A exceção será propagada se houver erro
      final registrosServidor = await _apiProvider.obterRegistros();

      // Atualizar banco local com dados do servidor
      for (var registro in registrosServidor) {
        await _localStorage.insertRegistro(registro);
      }
      return await _localStorage.getRegistros();
    } else {
      return await _localStorage.getRegistros();
    }
  }

  Future<bool> removerRegistro(String registroId) async {
    await _localStorage.deleteRegistro(registroId);
    // Se estiver online, tenta remover do servidor primeiro
    if (_connectivityService.isOnline) {
      // A exceção será propagada se houver erro
      await _apiProvider.removerRegistro(registroId);
    }
    return true;
  }
}
