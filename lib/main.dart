import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:crypto_assistant/l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/services/notification_service.dart';
import 'features/crypto/data/datasources/crypto_remote_data_source.dart';
import 'features/crypto/data/repositories/crypto_repository_impl.dart';
import 'features/crypto/domain/repositories/i_crypto_repository.dart';
import 'features/crypto/presentation/pages/home_screen.dart';
import 'features/crypto/presentation/viewmodels/home_viewmodel.dart';
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'features/settings/presentation/pages/settings_screen.dart';
import 'features/news/data/datasources/news_remote_data_source.dart';
import 'features/news/data/repositories/news_repository_impl.dart';
import 'features/news/domain/repositories/i_news_repository.dart';
import 'features/news/presentation/viewmodels/news_viewmodel.dart';
import 'features/main_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found. Using mock news data.');
  }

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

        // News Data Sources
        ProxyProvider<http.Client, INewsRemoteDataSource>(
          update: (_, client, __) => NewsRemoteDataSource(client: client),
        ),

        // News Repositories
        ProxyProvider<INewsRemoteDataSource, INewsRepository>(
          update: (_, newsDataSource, __) => NewsRepositoryImpl(
            remoteDataSource: newsDataSource,
          ),
        ),

        // ViewModels
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProxyProvider2<ICryptoRepository, SettingsViewModel, HomeViewModel>(
          create: (context) => HomeViewModel(
              repository: Provider.of<ICryptoRepository>(context, listen: false)),
          update: (_, repository, settings, viewModel) {
            final vm = viewModel ?? HomeViewModel(repository: repository);
            vm.updateCurrency(settings.currency);
            return vm;
          },
        ),
        ChangeNotifierProxyProvider3<INewsRepository, SettingsViewModel, HomeViewModel, NewsViewModel>(
          create: (context) {
            final newsRepo = Provider.of<INewsRepository>(context, listen: false);
            final settings = Provider.of<SettingsViewModel>(context, listen: false);
            final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
            
            // Update repository with current coins
            if (newsRepo is NewsRepositoryImpl) {
              newsRepo.updateCoins(homeViewModel.coins);
            }
            
            return NewsViewModel(
              repository: newsRepo,
              locale: settings.locale.languageCode,
            );
          },
          update: (_, newsRepo, settings, homeViewModel, viewModel) {
            // Update repository with latest coins
            if (newsRepo is NewsRepositoryImpl) {
              newsRepo.updateCoins(homeViewModel.coins);
            }
            
            if (viewModel == null || viewModel.locale != settings.locale.languageCode) {
              return NewsViewModel(repository: newsRepo, locale: settings.locale.languageCode);
            }
            return viewModel;
          },
        ),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, child) {
          return MaterialApp(
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
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ru'),
            ],
            home: const MainScreen(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
