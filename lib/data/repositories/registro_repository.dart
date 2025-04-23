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

  // Salvar foto em armazenamento permanente
  Future<String> _salvarFotoPermanente(String caminhoFotoTemporario) async {
    try {
      final diretorioDocumentos = await getApplicationDocumentsDirectory();
      final pastaFotos = Directory('${diretorioDocumentos.path}/fotos');

      // Criar pasta se não existir
      if (!await pastaFotos.exists()) {
        await pastaFotos.create(recursive: true);
      }

      // Gerar nome único para a foto
      final nomeArquivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final caminhoDestino = path.join(pastaFotos.path, nomeArquivo);

      // Copiar arquivo
      final arquivoOriginal = File(caminhoFotoTemporario);
      await arquivoOriginal.copy(caminhoDestino);

      return caminhoDestino;
    } catch (e) {
      print('Erro ao salvar foto: $e');
      return caminhoFotoTemporario; // Retorna o caminho original em caso de erro
    }
  }

  // Sincroniza um registro com o servidor
  Future<bool> _sincronizarRegistro(Registro registro) async {
    try {
      // Tenta enviar para a API

      // Atualiza o status de sincronização no banco local
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
    // Extrair coordenadas da foto, se disponível
    // No método criarRegistro do RegistroRepository
    // Map<String, double>? metadados;
    // try {
    //   metadados = await _locationService.getCoordinatesFromImageMetadata(
    //     caminhoFotoTemporario,
    //   );
    //   print('Coordenadas extraídas da foto: $metadados');
    //   print('Coordenadas atuais: lat=$latitudeAtual, long=$longitudeAtual');
    // } catch (e) {
    //   print('Erro ao extrair metadados: $e');
    //   metadados = null;
    // }

    // // Se não houver metadados ou se as coordenadas forem (0,0), considere como dentro do raio
    // bool dentroDoRaio = true;

    // if (metadados != null &&
    //     metadados['latitude'] != null &&
    //     metadados['longitude'] != null &&
    //     (metadados['latitude'] != 0.0 || metadados['longitude'] != 0.0)) {
    //   // Só calcule a distância se as coordenadas não forem (0,0)
    //   final latitudeFoto = metadados['latitude']!;
    //   final longitudeFoto = metadados['longitude']!;

    //   final distancia = _locationService.calculateDistance(
    //     latitudeAtual,
    //     longitudeAtual,
    //     latitudeFoto,
    //     longitudeFoto,
    //   );

    //   print('Distância calculada: $distancia metros');
    //   dentroDoRaio = distancia <= 10; // 10 metros
    // } else {
    //   print(
    //     'Sem dados de geolocalização válidos na foto, considerando como dentro do raio',
    //   );
    // }

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

    // Copiar a foto para armazenamento permanente
    String caminhoFotoPermanente;
    try {
      caminhoFotoPermanente = await _salvarFotoPermanente(
        caminhoFotoTemporario,
      );
    } catch (e) {
      print('Erro ao salvar foto, usando caminho original: $e');
      caminhoFotoPermanente = caminhoFotoTemporario;
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
      caminhoFoto: caminhoFotoPermanente,
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
      } catch (e) {
        // Apenas logamos o erro, mas não lançamos para cima
        print('Erro ao sincronizar com a API (ignorado): $e');
        // A sincronização será tentada novamente mais tarde
      }
    }

    return novoRegistro;
  }

  // Tenta encontrar e validar registros próximos
  Future<bool> verificarEValidarRegistrosProximos({
    required CategoriaIrregularidade categoria,
    required double latitude,
    required double longitude,
    required String validadorUsuarioId,
  }) async {
    // Buscar registros próximos não validados da mesma categoria
    final registrosProximos = await _localStorage.getRegistrosProximos(
      latitude,
      longitude,
      10, // 10 metros
      categoria,
    );

    // Filtrar apenas os registros que não foram validados
    final registrosParaValidar =
        registrosProximos
            .where((r) => r.status == StatusValidacao.pendente)
            .toList();

    if (registrosParaValidar.isEmpty) {
      return false;
    }

    // Validar o primeiro registro encontrado
    final registroValidado = registrosParaValidar.first.copyWith(
      status: StatusValidacao.validado,
      validadoPorUsuarioId: validadorUsuarioId,
      dataValidacao: DateTime.now(),
    );

    // Atualizar no banco local
    await _localStorage.updateRegistro(registroValidado);

    // Sincronizar com o servidor se estiver online
    if (_connectivityService.isOnline) {
      await _sincronizarRegistro(registroValidado);
    }

    return true;
  }

  // Obter todos os registros
  Future<List<Registro>> obterTodosRegistros() async {
    return await _localStorage.getRegistros();
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
