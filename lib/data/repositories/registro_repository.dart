import 'dart:convert';
import 'dart:io';
import 'package:avisai4/services/local_storage_service.dart';
import 'package:uuid/uuid.dart';
import '../models/registro.dart';
import '../../services/location_service.dart';
import '../../services/connectivity_service.dart';
import '../providers/api_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

      // Enviar para a API
      await _apiProvider.enviarRegistro(registroAtualizado);

      // Atualizar o status de sincronização no banco local
      await _localStorage.marcarRegistroComoSincronizado(registro.id!);

      return true;
    } catch (e) {
      print('Erro ao sincronizar registro: $e');
      return false;
    }
  }

  // Tenta sincronizar todos os registros pendentes
  Future<int> sincronizarRegistrosPendentes() async {
    if (!_connectivityService.isOnline) return 0;

    // Buscar todos os registros não sincronizados
    final registrosNaoSincronizados = await _localStorage.getRegistros(
      apenasNaoSincronizados: true,
    );

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

    // Salvar no armazenamento local - esta parte é crítica e deve funcionar
    await _localStorage.insertRegistro(novoRegistro);

    // Tentar sincronizar com o servidor, se estiver online
    // Se falhar, isso será tratado no bloco catch do BLoC
    if (_connectivityService.isOnline) {
      try {
        await _sincronizarRegistro(novoRegistro);
        await _apiProvider.enviarRegistro(novoRegistro);
      } catch (e) {
        // Apenas logamos o erro, mas não lançamos para cima
        print('Erro ao sincronizar com a API (ignorado): $e');
        // A sincronização será tentada novamente mais tarde
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
          await _localStorage.insertRegistro(
            registro.copyWith(sincronizado: true),
          );
        }

        // Retornar dados do banco local (que agora está atualizado com os dados do servidor)
        return await _localStorage.getRegistros();
      } catch (e) {
        print('Erro ao buscar registros do servidor: $e');
        // Em caso de erro na comunicação com o servidor, cair no fallback local
        return await _localStorage.getRegistros();
      }
    } else {
      // Se estiver offline, buscar apenas os dados locais
      return await _localStorage.getRegistros();
    }
  }

  // Obter registros do usuário
  Future<List<Registro>> obterRegistrosDoUsuario(String usuarioId) async {
    final registros = await _localStorage.getRegistros();
    return registros.where((r) => r.usuarioId == usuarioId).toList();
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
