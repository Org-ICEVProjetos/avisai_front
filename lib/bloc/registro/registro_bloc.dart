import 'dart:async';
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

class CriarNovoRegistro extends RegistroEvent {
  final String usuarioId;
  final String usuarioNome;
  final CategoriaIrregularidade categoria;
  final String caminhoFotoTemporario;

  CriarNovoRegistro({
    required this.usuarioId,
    required this.usuarioNome,
    required this.categoria,
    required this.caminhoFotoTemporario,
  });

  @override
  List<Object> get props => [usuarioId, categoria, caminhoFotoTemporario];
}

class VerificarEValidarRegistrosProximos extends RegistroEvent {
  final CategoriaIrregularidade categoria;
  final String validadorUsuarioId;
  final double latitude;
  final double longitude;

  VerificarEValidarRegistrosProximos({
    required this.categoria,
    required this.validadorUsuarioId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [
    categoria,
    validadorUsuarioId,
    latitude,
    longitude,
  ];
}

class CriarNovoRegistroComLocalizacao extends RegistroEvent {
  final String usuarioId;
  final String usuarioNome;
  final CategoriaIrregularidade categoria;
  final String caminhoFotoTemporario;
  final double latitude;
  final double longitude;

  CriarNovoRegistroComLocalizacao({
    required this.usuarioId,
    required this.usuarioNome,
    required this.categoria,
    required this.caminhoFotoTemporario,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [
    usuarioId,
    categoria,
    caminhoFotoTemporario,
    latitude,
    longitude,
  ];
}

class SincronizarRegistrosPendentes extends RegistroEvent {}

class RemoverRegistro extends RegistroEvent {
  final String registroId;

  RemoverRegistro({required this.registroId});

  @override
  List<Object> get props => [registroId];
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
  final ConnectivityService _connectivityService;
  StreamSubscription? _conectividadeSubscription;

  RegistroBloc({
    required RegistroRepository registroRepository,
    required LocationService locationService,
    required ConnectivityService connectivityService,
  }) : _registroRepository = registroRepository,
       _connectivityService = connectivityService,
       super(RegistroCarregando()) {
    on<CarregarRegistros>(_onCarregarRegistros);
    on<VerificarEValidarRegistrosProximos>(
      _onVerificarEValidarRegistrosProximos,
    );
    on<SincronizarRegistrosPendentes>(_onSincronizarRegistrosPendentes);
    on<RemoverRegistro>(_onRemoverRegistro);
    on<ConexaoAlterada>(_onConexaoAlterada);
    on<CriarNovoRegistroComLocalizacao>(_onCriarNovoRegistroComLocalizacao);

    _conectividadeSubscription = _connectivityService.connectionStatusStream
        .listen((online) {
          add(ConexaoAlterada(estaOnline: online));
        });
  }

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
      emit(RegistroErro(mensagem: 'Erro ao carregar registros: $e'));
    }
  }

  Future<void> _onVerificarEValidarRegistrosProximos(
    VerificarEValidarRegistrosProximos event,
    Emitter<RegistroState> emit,
  ) async {
    emit(RegistroCarregando());
    try {
      final resultado = await _registroRepository
          .verificarEValidarRegistrosProximos(
            categoria: event.categoria,
            latitude: event.latitude,
            longitude: event.longitude,
            validadorUsuarioId: event.validadorUsuarioId,
          );

      if (resultado) {
        emit(
          RegistroOperacaoSucesso(mensagem: 'Registro validado com sucesso!'),
        );
      } else {
        emit(
          RegistroOperacaoSucesso(
            mensagem: 'Não há registros próximos para validar.',
          ),
        );
      }

      final registros = await _registroRepository.obterTodosRegistros();
      emit(
        RegistroCarregado(
          registros: registros,
          estaOnline: _connectivityService.isOnline,
        ),
      );
    } catch (e) {
      emit(RegistroErro(mensagem: 'Erro ao validar registros: $e'));
    }
  }

  Future<void> _onSincronizarRegistrosPendentes(
    SincronizarRegistrosPendentes event,
    Emitter<RegistroState> emit,
  ) async {
    if (!_connectivityService.isOnline) {
      emit(
        RegistroErro(
          mensagem: 'Sem conexão com a internet. Não é possível sincronizar.',
        ),
      );
      return;
    }

    emit(RegistroCarregando());
    try {
      final quantidadeSincronizada =
          await _registroRepository.sincronizarRegistrosPendentes();

      emit(
        RegistroOperacaoSucesso(
          mensagem:
              'Sincronização concluída: $quantidadeSincronizada registros sincronizados.',
        ),
      );

      final registros = await _registroRepository.obterTodosRegistros();
      emit(
        RegistroCarregado(
          registros: registros,
          estaOnline: _connectivityService.isOnline,
        ),
      );
    } catch (e) {
      emit(RegistroErro(mensagem: 'Erro ao sincronizar registros: $e'));
    }
  }

  Future<void> _onRemoverRegistro(
    RemoverRegistro event,
    Emitter<RegistroState> emit,
  ) async {
    emit(RegistroCarregando());
    try {
      await _registroRepository.removerRegistro(event.registroId);

      emit(RegistroOperacaoSucesso(mensagem: 'Registro removido com sucesso.'));

      final registros = await _registroRepository.obterTodosRegistros();
      emit(
        RegistroCarregado(
          registros: registros,
          estaOnline: _connectivityService.isOnline,
        ),
      );
    } catch (e) {
      emit(RegistroErro(mensagem: 'Erro ao remover registro: $e'));
    }
  }

  void _onConexaoAlterada(ConexaoAlterada event, Emitter<RegistroState> emit) {
    if (event.estaOnline) {
      add(SincronizarRegistrosPendentes());
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

  Future<void> _onCriarNovoRegistroComLocalizacao(
    CriarNovoRegistroComLocalizacao event,
    Emitter<RegistroState> emit,
  ) async {
    emit(RegistroCarregando());
    try {
      await _registroRepository.criarRegistro(
        usuarioId: event.usuarioId,
        usuarioNome: event.usuarioNome,
        categoria: event.categoria,
        caminhoFotoTemporario: event.caminhoFotoTemporario,
        latitudeAtual: event.latitude,
        longitudeAtual: event.longitude,
      );

      // Como a localização já foi capturada no momento da foto, não precisamos
      // revalidar a proximidade - o registro sempre será pendente

      // Emitir mensagem de sucesso
      emit(RegistroOperacaoSucesso(mensagem: 'Registro criado com sucesso!'));

      // Carregar registros atualizados
      final registros = await _registroRepository.obterTodosRegistros();
      emit(
        RegistroCarregado(
          registros: registros,
          estaOnline: _connectivityService.isOnline,
        ),
      );
    } catch (e) {
      print('Erro ao criar registro: $e');
      emit(RegistroErro(mensagem: 'Erro ao criar registro: $e'));

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
}
