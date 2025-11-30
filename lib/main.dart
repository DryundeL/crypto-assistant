import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'core/services/notification_service.dart';
import 'features/crypto/data/datasources/crypto_remote_data_source.dart';
import 'features/crypto/data/repositories/crypto_repository_impl.dart';
import 'features/crypto/domain/repositories/i_crypto_repository.dart';
import 'features/crypto/presentation/pages/home_screen.dart';
import 'features/crypto/presentation/viewmodels/home_viewmodel.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.init((payload) {
    if (payload == 'daily_recommendation') {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  });
  
  await notificationService.scheduleDailyNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => http.Client()),
        
        // Data Sources
        ProxyProvider<http.Client, ICryptoRemoteDataSource>(
          update: (_, client, __) => CryptoRemoteDataSource(client: client),
        ),

        // Repositories
        ProxyProvider<ICryptoRemoteDataSource, ICryptoRepository>(
          update: (_, dataSource, __) => CryptoRepositoryImpl(remoteDataSource: dataSource),
        ),

        // ViewModels
        ChangeNotifierProxyProvider<ICryptoRepository, HomeViewModel>(
          create: (context) => HomeViewModel(
              repository: Provider.of<ICryptoRepository>(context, listen: false)),
          update: (_, repository, viewModel) => 
              viewModel ?? HomeViewModel(repository: repository),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Crypto Assistant',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
