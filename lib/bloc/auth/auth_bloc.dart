import 'dart:async';
import 'package:avisai4/services/user_storage.dart';
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

class VerificarAutenticacao extends AuthEvent {}

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

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(NaoAutenticado()) {
    on<VerificarAutenticacao>(_onVerificarAutenticacao);
    on<LoginSolicitado>(_onLoginSolicitado);
    on<RegistroSolicitado>(_onRegistroSolicitado);
    on<RecuperacaoSenhaSolicitada>(_onRecuperacaoSenhaSolicitada);
    on<LogoutSolicitado>(_onLogoutSolicitado);
    on<LoginAutomaticoSolicitado>(_onLoginAutomaticoSolicitado);
  }

  Future<void> _onVerificarAutenticacao(
    VerificarAutenticacao event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      final usuario = await _authRepository.checarAutenticacao();
      if (usuario != null) {
        emit(Autenticado(usuario));
      } else {
        emit(NaoAutenticado());
      }
    } catch (e) {
      emit(NaoAutenticado());
    }
  }

  Future<void> _onLoginAutomaticoSolicitado(
    LoginAutomaticoSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());

    try {
      // Aqui você pode opcionalmente validar com a API se o token/sessão ainda é válido
      // Se não houver API, simplesmente emita o estado autenticado com o usuário
      emit(Autenticado(event.usuario));
    } catch (e) {
      // Em caso de erro, como token expirado, emitir não autenticado
      emit(NaoAutenticado());
      // E remover os dados locais
      await UserLocalStorage.removerUsuario();
    }
  }

  Future<void> _onLoginSolicitado(
    LoginSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    emit(Carregando());
    try {
      final usuario = Usuario(
        id: "123",
        nome: "lala",
        cpf: "06513872308",
        email: "",
        senha: "senha123",
      );
      // final usuario = await _authRepository.login(
      //   event.cpf,
      //   event.senha,
      // );
      await UserLocalStorage.salvarUsuario(usuario);
      emit(Autenticado(usuario));
    } catch (e) {
      emit(AuthErro(e.toString()));
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
      emit(AuthErro(e.toString()));
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
      emit(AuthErro(e.toString()));
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
      emit(AuthErro(e.toString()));
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
