import 'dart:async';
import 'package:avisai4/data/providers/api_provider.dart';
import 'package:avisai4/services/user_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

class LoginAutomaticoSolicitado extends AuthEvent {
  final Usuario usuario;

  const LoginAutomaticoSolicitado({required this.usuario});

  @override
  List<Object> get props => [usuario];
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
    on<LoginAutomaticoSolicitado>(_onLoginAutomaticoSolicitado);
  }

  Future<void> _onVerificarAutenticacao(
    VerificarAutenticacao event,
    Emitter<AuthState> emit,
  ) async {
    // Não emitir Carregando aqui para não acionar a transição na SplashScreen
    // Apenas verificar silenciosamente
    try {
      final usuario = await _authRepository.checarAutenticacao();
      if (usuario != null) {
        // Verificamos se o evento tem um flag para sinalizar que veio da SplashScreen
        // Se for silencioso, não emitimos o estado Autenticado ainda
        if (event.fromSplash) {
          emit(Autenticado(usuario));
        }
      } else {
        if (event.fromSplash) {
          emit(NaoAutenticado());
        }
      }
    } catch (e) {
      if (event.fromSplash) {
        emit(NaoAutenticado());
      }
    }
  }

  Future<void> _onLoginAutomaticoSolicitado(
    LoginAutomaticoSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());

    try {
      // Já temos todos os dados necessários no evento
      emit(Autenticado(event.usuario));
    } catch (e) {
      emit(NaoAutenticado());
      // Limpar dados locais em caso de erro
      await UserLocalStorage.removerUsuario();
    }
  }

  Future<void> _onLoginSolicitado(
    LoginSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      final usuario = await _authRepository.login(event.cpf, event.senha);
      emit(Autenticado(usuario));
    } catch (e) {
      // Personalizar mensagem baseada no tipo de erro
      String mensagem = 'Erro ao fazer login: $e';
      if (e is ApiException) {
        mensagem = e.message; // Usa a mensagem específica do servidor
      }
      emit(AuthErro(mensagem));
    }
  }

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
      // Personalizar mensagem baseada no tipo de erro
      String mensagem = 'Erro ao registrar usuário: $e';
      if (e is ApiException) {
        mensagem = e.message; // Usa a mensagem específica do servidor
      }
      emit(AuthErro(mensagem));
    }
  }

  Future<void> _onRecuperacaoSenhaSolicitada(
    RecuperacaoSenhaSolicitada event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      await _authRepository.recuperarSenha(event.cpf, event.email);
      emit(RecuperacaoSenhaEnviada());
    } catch (e) {
      // Personalizar mensagem baseada no tipo de erro
      String mensagem = 'Erro ao recuperar senha: $e';
      if (e is ApiException) {
        mensagem = e.message; // Usa a mensagem específica do servidor
      }
      emit(AuthErro(mensagem));
    }
  }

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
      // Personalizar mensagem baseada no tipo de erro
      String mensagem = 'Erro ao validar código: $e';
      if (e is ApiException) {
        mensagem = e.message; // Usa a mensagem específica do servidor
      }
      emit(AuthErro(mensagem));
    }
  }

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
      // Personalizar mensagem baseada no tipo de erro
      String mensagem = 'Erro ao alterar senha: $e';
      if (e is ApiException) {
        mensagem = e.message; // Usa a mensagem específica do servidor
      }
      emit(AuthErro(mensagem));
    }
  }

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
      // Para logout, mesmo com erro, limpa os dados locais
      await UserLocalStorage.removerUsuario();
      emit(NaoAutenticado());

      // Log do erro mas não mostra para o usuário
      if (kDebugMode) {
        print('Erro durante logout: $e');
      }
    }
  }

  // Método utilitário que pode ser usado em qualquer parte do app
  Usuario? getUsuarioAtual(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Autenticado) {
      return authState.usuario;
    }
    return null;
  }
}
