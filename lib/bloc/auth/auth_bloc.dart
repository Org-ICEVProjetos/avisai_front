import 'dart:async';
import 'package:avisai4/data/providers/api_provider.dart';
import 'package:avisai4/services/user_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/usuario.dart';
import '../../data/repositories/auth_repository.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class VerificarAutenticacao extends AuthEvent {
  final bool fromSplash;

  const VerificarAutenticacao({this.fromSplash = false});

  @override
  List<Object> get props => [fromSplash];
}

class LoginSolicitado extends AuthEvent {
  final String cpf;
  final String senha;

  const LoginSolicitado({required this.cpf, required this.senha});

  @override
  List<Object> get props => [cpf, senha];
}

class RegistroSolicitado extends AuthEvent {
  final String nome;
  final String cpf;
  final String email;
  final String senha;

  const RegistroSolicitado({
    required this.nome,
    required this.cpf,
    required this.email,
    required this.senha,
  });

  @override
  List<Object> get props => [nome, cpf, email, senha];
}

class RecuperacaoSenhaSolicitada extends AuthEvent {
  final String cpf;
  final String email;

  const RecuperacaoSenhaSolicitada({required this.cpf, required this.email});

  @override
  List<Object> get props => [cpf, email];
}

class VerificarTokenSenhaSolicitado extends AuthEvent {
  final String token;

  const VerificarTokenSenhaSolicitado({required this.token});

  @override
  List<Object> get props => [token];
}

class AlterarSenhaSolicitada extends AuthEvent {
  final String senha;
  final String token;

  const AlterarSenhaSolicitada({required this.senha, required this.token});

  @override
  List<Object> get props => [senha, token];
}

class LogoutSolicitado extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class ValidarTokenAutomatico extends AuthEvent {
  const ValidarTokenAutomatico();
}

class NaoAutenticado extends AuthState {}

class Carregando extends AuthState {}

class Autenticado extends AuthState {
  final Usuario usuario;

  const Autenticado(this.usuario);

  @override
  List<Object> get props => [usuario];
}

class AuthErro extends AuthState {
  final String mensagem;

  const AuthErro(this.mensagem);

  @override
  List<Object> get props => [mensagem];
}

class RecuperacaoSenhaEnviada extends AuthState {}

class TokenSenhaValidado extends AuthState {}

class SenhaAlterada extends AuthState {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(NaoAutenticado()) {
    on<VerificarAutenticacao>(_onVerificarAutenticacao);
    on<LoginSolicitado>(_onLoginSolicitado);
    on<RegistroSolicitado>(_onRegistroSolicitado);
    on<RecuperacaoSenhaSolicitada>(_onRecuperacaoSenhaSolicitada);
    on<VerificarTokenSenhaSolicitado>(_onVerificarTokenSenhaSolicitado);
    on<AlterarSenhaSolicitada>(_onAlterarSenhaSolicitada);
    on<LogoutSolicitado>(_onLogoutSolicitado);
    on<ValidarTokenAutomatico>(_onValidarTokenAutomatico);
  }

  // Verifica autenticação para solicitar login automático
  Future<void> _onVerificarAutenticacao(
    VerificarAutenticacao event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final temDadosLocais =
          await UserLocalStorage.verificarUsuarioAutenticado();
      final temTokens =
          await UserLocalStorage.obterToken() != null &&
          await UserLocalStorage.obterRefreshToken() != null;

      if (event.fromSplash) {
        if (temDadosLocais && temTokens) {
          add(const ValidarTokenAutomatico());
        } else {
          emit(NaoAutenticado());
        }
      }
    } catch (e) {
      if (event.fromSplash) {
        emit(NaoAutenticado());
      }
    }
  }

  // Faz login automático (sem necessidade de CPF e senha)
  Future<void> _onValidarTokenAutomatico(
    ValidarTokenAutomatico event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());

    try {
      final usuario = await _authRepository.validarTokenERenovar();

      if (usuario != null) {
        emit(Autenticado(usuario));
      } else {
        emit(NaoAutenticado());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro no login automático: $e');
      }
      emit(NaoAutenticado());
    }
  }

  // Login no app
  Future<void> _onLoginSolicitado(
    LoginSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      final usuario = await _authRepository.login(event.cpf, event.senha);
      emit(Autenticado(usuario));
    } catch (e) {
      String mensagem = 'Erro ao fazer login: $e';
      if (e is ApiException) {
        mensagem = e.message;
      }
      emit(AuthErro(mensagem));
    }
  }

  // Registro de conta no app
  Future<void> _onRegistroSolicitado(
    RegistroSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      final usuario = await _authRepository.registrar(
        event.nome,
        event.cpf,
        event.email,
        event.senha,
      );
      emit(Autenticado(usuario));
    } catch (e) {
      String mensagem = 'Erro ao registrar usuário: $e';
      if (e is ApiException) {
        mensagem = e.message;
      }
      emit(AuthErro(mensagem));
    }
  }

  // Solicita recuperação de senha
  Future<void> _onRecuperacaoSenhaSolicitada(
    RecuperacaoSenhaSolicitada event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      await _authRepository.recuperarSenha(event.cpf, event.email);
      emit(RecuperacaoSenhaEnviada());
    } catch (e) {
      String mensagem = 'Erro ao recuperar senha: $e';
      if (e is ApiException) {
        mensagem = e.message;
      }
      emit(AuthErro(mensagem));
    }
  }

  // Verifica se o código enviado pela solicitação de troca de seneha é válido
  Future<void> _onVerificarTokenSenhaSolicitado(
    VerificarTokenSenhaSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      final isValid = await _authRepository.validarTokenSenha(event.token);
      if (isValid) {
        emit(TokenSenhaValidado());
      } else {
        emit(AuthErro('Código inválido ou expirado'));
      }
    } catch (e) {
      String mensagem = 'Erro ao validar código: $e';
      if (e is ApiException) {
        mensagem = e.message;
      }
      emit(AuthErro(mensagem));
    }
  }

  // Altera a senha da conta logada
  Future<void> _onAlterarSenhaSolicitada(
    AlterarSenhaSolicitada event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      final success = await _authRepository.alterarSenha(
        event.senha,
        event.token,
      );
      if (success) {
        emit(SenhaAlterada());
      } else {
        emit(AuthErro('Não foi possível alterar a senha'));
      }
    } catch (e) {
      String mensagem = 'Erro ao alterar senha: $e';
      if (e is ApiException) {
        mensagem = e.message;
      }
      emit(AuthErro(mensagem));
    }
  }

  // Faz logout
  Future<void> _onLogoutSolicitado(
    LogoutSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      await _authRepository.logout();
      await UserLocalStorage.removerUsuario();
      emit(NaoAutenticado());
    } catch (e) {
      await UserLocalStorage.removerUsuario();
      emit(NaoAutenticado());

      if (kDebugMode) {
        print('Erro durante logout: $e');
      }
    }
  }
}
