import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/shared.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  registerHiveAdapters();

  await Hive.openBox<User>('users');
  await Hive.openBox('settings');

  runApp(const TrainerApp());
}

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => apiService),
        RepositoryProvider(create: (_) => AuthService(apiService)),
        RepositoryProvider(create: (_) => ChatService(apiService)),
        RepositoryProvider(create: (_) => CallService(apiService)),
        RepositoryProvider(create: (_) => LogService(apiService)),
      ],
      child: MaterialApp(
        title: 'Trainer App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE50914),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    final settingsBox = Hive.box('settings');
    final isLoggedIn = settingsBox.get('isLoggedIn', defaultValue: false) as bool;
    if (isLoggedIn) return const TrainerHomeScreen();
    return const LoginScreen();
  }
}
