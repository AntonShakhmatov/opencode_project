import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/job_provider.dart';
import 'services/socket_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.restore();
  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final socketService = SocketService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider.value(value: socketService),
        ProxyProvider<SocketService, ChatProvider>(
          update: (_, socket, __) => ChatProvider(socket),
        ),
      ],
      child: MaterialApp(
        title: 'Handyman App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isRestoring) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (auth.isAuthenticated) {
                return const HomeScreen();
              }
              return const LoginScreen();
            },
          ),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}