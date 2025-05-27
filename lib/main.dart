import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/registro_repository.dart';
import 'data/providers/api_provider.dart';
import 'services/connectivity_service.dart';
import 'services/local_storage_service.dart';
import 'services/location_service.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/registro/registro_bloc.dart';
import 'bloc/connectivity/connectivity_bloc.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'presentation/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final connectivityService = ConnectivityService();
  connectivityService.initialize();

  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs, connectivityService: connectivityService));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final ConnectivityService connectivityService;

  const MyApp({
    super.key,
    required this.prefs,
    required this.connectivityService,
  });

  @override
  Widget build(BuildContext context) {
    final apiProvider = ApiProvider();
    final localStorageService = LocalStorageService();
    final locationService = LocationService();

    final authRepository = AuthRepository(
      apiProvider: apiProvider,
      localStorageService: localStorageService,
      prefs: prefs,
    );

    final registroRepository = RegistroRepository(
      apiProvider: apiProvider,
      localStorageService: localStorageService,
      locationService: locationService,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (context) => authRepository),
        RepositoryProvider<RegistroRepository>(
          create: (context) => registroRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create:
                (context) =>
                    AuthBloc(authRepository: authRepository)
                      ..add(VerificarAutenticacao()),
          ),
          BlocProvider<RegistroBloc>(
            create:
                (context) => RegistroBloc(
                  localStorageService,
                  registroRepository: registroRepository,
                  locationService: locationService,
                  connectivityService: connectivityService,
                ),
          ),
          BlocProvider<ConnectivityBloc>(
            create:
                (context) =>
                    ConnectivityBloc(connectivityService: connectivityService),
          ),
        ],
        child: MaterialApp(
          title: 'Avisaí',
          theme: appTheme(),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: appRoutes,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
        ),
      ),
    );
  }
}
