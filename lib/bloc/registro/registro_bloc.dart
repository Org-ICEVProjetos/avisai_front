import 'dart:async';
import 'package:avisai4/data/providers/api_provider.dart';
import 'package:avisai4/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/registro.dart';
import '../../data/repositories/registro_repository.dart';
import '../../services/location_service.dart';
import '../../services/connectivity_service.dart';

abstract class RegistroEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class CarregarRegistros extends RegistroEvent {}

class CriarNovoRegistroComLocalizacao extends RegistroEvent {
  final String usuarioId;
  final String usuarioNome;
  final CategoriaIrregularidade categoria;
  final String caminhoFotoTemporario;
  final double latitude;
  final double longitude;
  final String? observation;

  CriarNovoRegistroComLocalizacao({
    required this.usuarioId,
    required this.usuarioNome,
    required this.categoria,
    required this.caminhoFotoTemporario,
    required this.latitude,
    required this.longitude,
    this.observation,
  });

  @override
  List<Object> get props => [
    usuarioId,
    categoria,
    caminhoFotoTemporario,
    latitude,
    longitude,
    observation ?? '',
  ];
}

class SincronizarRegistrosPendentes extends RegistroEvent {
  final BuildContext context;
  final bool silencioso;

  SincronizarRegistrosPendentes({
    required this.context,
    this.silencioso = false,
  });

  @override
  List<Object> get props => [context, silencioso];
}

class _SincronizarRegistrosSilenciosamente extends RegistroEvent {}

class RemoverRegistro extends RegistroEvent {
  final String registroId;
  final bool isSincronizado;

  RemoverRegistro(this.isSincronizado, this.registroId);

  @override
  List<Object> get props => [registroId, isSincronizado];
}

class ConexaoAlterada extends RegistroEvent {
  final bool estaOnline;

  ConexaoAlterada({required this.estaOnline});

  @override
  List<Object> get props => [estaOnline];
}

abstract class RegistroState extends Equatable {
  @override
  List<Object> get props => [];
}

class RegistroCarregando extends RegistroState {}

class RegistroCarregado extends RegistroState {
  final List<Registro> registros;
  final bool estaOnline;

  RegistroCarregado({required this.registros, required this.estaOnline});

  @override
  List<Object> get props => [registros, estaOnline];
}

class RegistroOperacaoSucesso extends RegistroState {
  final String mensagem;

  RegistroOperacaoSucesso({required this.mensagem});

  @override
  List<Object> get props => [mensagem];
}

class RegistroErro extends RegistroState {
  final String mensagem;

  RegistroErro({required this.mensagem});

  @override
  List<Object> get props => [mensagem];
}

class RegistroBloc extends Bloc<RegistroEvent, RegistroState> {
  final RegistroRepository _registroRepository;
  final LocationService _locationService;
  final ConnectivityService _connectivityService;
  StreamSubscription? _conectividadeSubscription;
  final LocalStorageService _localStorage;

  RegistroBloc(
    this._localStorage, {
    required RegistroRepository registroRepository,
    required LocationService locationService,
    required ConnectivityService connectivityService,
  }) : _registroRepository = registroRepository,
       _connectivityService = connectivityService,
       _locationService = locationService,
       super(RegistroCarregando()) {
    on<CarregarRegistros>(_onCarregarRegistros);
    on<SincronizarRegistrosPendentes>(_onSincronizarRegistrosPendentes);
    on<_SincronizarRegistrosSilenciosamente>(_onSincronizarSilenciosamente);
    on<RemoverRegistro>(_onRemoverRegistro);
    on<ConexaoAlterada>(_onConexaoAlterada);
    on<CriarNovoRegistroComLocalizacao>(_onCriarNovoRegistroComLocalizacao);

    _conectividadeSubscription = _connectivityService.connectionStatusStream
        .listen((online) {
          add(ConexaoAlterada(estaOnline: online));
        });
  }

  // Carrega os registros na tela
  Future<void> _onCarregarRegistros(
    CarregarRegistros event,
    Emitter<RegistroState> emit,
  ) async {
    emit(RegistroCarregando());
    try {
      final registros = await _registroRepository.obterTodosRegistros();
      emit(
        RegistroCarregado(
          registros: registros,
          estaOnline: _connectivityService.isOnline,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar registros: $e');
      }

      String mensagem = 'Erro ao carregar registros: $e';
      if (e is ApiException) {
        mensagem = e.message;
      }

      emit(RegistroErro(mensagem: mensagem));

      try {
        final registrosLocais = await _localStorage.getRegistros();
        emit(
          RegistroCarregado(
            registros: registrosLocais,
            estaOnline: _connectivityService.isOnline,
          ),
        );
      } catch (_) {}
    }
  }

  // Cria novo registro
  Future<void> _onCriarNovoRegistroComLocalizacao(
    CriarNovoRegistroComLocalizacao event,
    Emitter<RegistroState> emit,
  ) async {
    emit(RegistroCarregando());
    try {
      bool jaExiste = await _locationService.isLocationNearSavedDocument(
        event.latitude,
        event.longitude,
      );

      if (jaExiste) {
        throw Exception('Esse registro já foi criado');
      }

      final novoRegistro = await _registroRepository.criarRegistro(
        usuarioId: event.usuarioId,
        usuarioNome: event.usuarioNome,
        categoria: event.categoria,
        caminhoFotoTemporario: event.caminhoFotoTemporario,
        latitudeAtual: event.latitude,
        longitudeAtual: event.longitude,
        observation: event.observation,
      );

      // Verificar se o registro foi realmente salvo
      bool registroSalvo = await _localStorage.registroExiste(novoRegistro.id!);

      if (!registroSalvo) {
        throw Exception('Falha ao salvar registro localmente');
      }

      final registros = await _registroRepository.obterTodosRegistros();

      String mensagem =
          novoRegistro.sincronizado
              ? 'Registro criado e sincronizado com sucesso!'
              : 'Registro salvo localmente. Será sincronizado quando houver conexão.';

      emit(RegistroOperacaoSucesso(mensagem: mensagem));
      emit(
        RegistroCarregado(
          registros: registros,
          estaOnline: _connectivityService.isOnline,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao criar registro: $e');
      }

      String mensagem = 'Erro ao criar registro: $e';

      if (mensagem ==
          "Erro ao criar registro: Exception: Esse registro já foi criado") {
        mensagem = 'Esse registro já foi criado';
      }
      if (e is ApiException && e.statusCode == 400) {
        mensagem = e.message;
      }

      emit(RegistroErro(mensagem: mensagem));

      try {
        final registros = await _registroRepository.obterTodosRegistros();
        emit(
          RegistroCarregado(
            registros: registros,
            estaOnline: _connectivityService.isOnline,
          ),
        );
      } catch (_) {}
    }
  }

  // Sincroniza registros salvos localemente que não está no banco de dados remoto
  Future<void> _onSincronizarRegistrosPendentes(
    SincronizarRegistrosPendentes event,
    Emitter<RegistroState> emit,
  ) async {
    if (!_connectivityService.isOnline) {
      if (!event.silencioso) {
        ScaffoldMessenger.of(event.context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sem conexão com a internet. Não é possível sincronizar.',
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    RegistroState estadoAtual = state;

    try {
      final quantidadeSincronizada =
          await _registroRepository.sincronizarRegistrosPendentes();

      if (quantidadeSincronizada > 0 && !event.silencioso) {
        ScaffoldMessenger.of(event.context).showSnackBar(
          SnackBar(
            content: Text(
              '$quantidadeSincronizada registro(s) sincronizado(s)',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      final registros = await _registroRepository.obterTodosRegistros();
      if (estadoAtual is RegistroCarregado) {
        emit(
          RegistroCarregado(
            registros: registros,
            estaOnline: _connectivityService.isOnline,
          ),
        );
      }
    } catch (e) {
      if (!event.silencioso) {
        ScaffoldMessenger.of(event.context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sincronizar: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        if (kDebugMode) {
          print('Erro na sincronização automática: $e');
        }
      }
    }
  }

  // Sincroniza silenciosamente (não mostra tela de carregamento) os registros
  Future<void> _onSincronizarSilenciosamente(
    _SincronizarRegistrosSilenciosamente event,
    Emitter<RegistroState> emit,
  ) async {
    if (!_connectivityService.isOnline) {
      return;
    }

    try {
      await _registroRepository.sincronizarRegistrosPendentes();

      if (state is RegistroCarregado) {
        final registros = await _registroRepository.obterTodosRegistros();
        emit(
          RegistroCarregado(
            registros: registros,
            estaOnline: _connectivityService.isOnline,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro na sincronização silenciosa: $e");
      }
    }
  }

  // Remove registro
  Future<void> _onRemoverRegistro(
    RemoverRegistro event,
    Emitter<RegistroState> emit,
  ) async {
    emit(RegistroCarregando());
    try {
      await _registroRepository.removerRegistro(
        event.registroId,
        event.isSincronizado,
      );

      emit(RegistroOperacaoSucesso(mensagem: 'Registro removido com sucesso.'));

      final registros = await _registroRepository.obterTodosRegistros();
      emit(
        RegistroCarregado(
          registros: registros,
          estaOnline: _connectivityService.isOnline,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao remover registro: $e');
      }

      String mensagem = 'Erro ao remover registro: $e';
      if (e is ApiException) {
        mensagem = e.message;
      }

      emit(RegistroErro(mensagem: mensagem));
      try {
        final registros = await _registroRepository.obterTodosRegistros();
        emit(
          RegistroCarregado(
            registros: registros,
            estaOnline: _connectivityService.isOnline,
          ),
        );
      } catch (_) {}
    }
  }

  // Verifca alteração de conexão para sincronização automática
  void _onConexaoAlterada(ConexaoAlterada event, Emitter<RegistroState> emit) {
    if (event.estaOnline) {
      add(_SincronizarRegistrosSilenciosamente());
    } else if (state is RegistroCarregado) {
      final estadoAtual = state as RegistroCarregado;
      emit(
        RegistroCarregado(registros: estadoAtual.registros, estaOnline: false),
      );
    }
  }

  @override
  Future<void> close() {
    _conectividadeSubscription?.cancel();
    return super.close();
  }
}
