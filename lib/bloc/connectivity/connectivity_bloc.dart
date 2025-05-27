import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/connectivity_service.dart';

abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object> get props => [];
}

class ConnectivityStatusChanged extends ConnectivityEvent {
  final bool isConnected;

  const ConnectivityStatusChanged({required this.isConnected});

  @override
  List<Object> get props => [isConnected];
}

class CheckConnectivity extends ConnectivityEvent {}

abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object> get props => [];
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityConnected extends ConnectivityState {}

class ConnectivityDisconnected extends ConnectivityState {}

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService _connectivityService;
  StreamSubscription? _connectionSubscription;

  ConnectivityBloc({required ConnectivityService connectivityService})
    : _connectivityService = connectivityService,
      super(ConnectivityInitial()) {
    on<ConnectivityStatusChanged>(_onConnectivityStatusChanged);
    on<CheckConnectivity>(_onCheckConnectivity);

    _connectionSubscription = _connectivityService.connectionStatusStream
        .listen((isConnected) {
          add(ConnectivityStatusChanged(isConnected: isConnected));
        });

    add(CheckConnectivity());
  }

  // Verifica mudança de conexão
  void _onConnectivityStatusChanged(
    ConnectivityStatusChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    if (event.isConnected) {
      emit(ConnectivityConnected());
    } else {
      emit(ConnectivityDisconnected());
    }
  }

  // Checa se está conectado
  void _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<ConnectivityState> emit,
  ) {
    if (_connectivityService.isOnline) {
      emit(ConnectivityConnected());
    } else {
      emit(ConnectivityDisconnected());
    }
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    return super.close();
  }
}
