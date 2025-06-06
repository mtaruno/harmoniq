import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';
import 'services/websocket_service.dart';
import 'screens/home_screen.dart';
import 'screens/live_session_screen.dart';
import 'screens/session_summary_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/past_sessions_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final databaseService = DatabaseService();
  await databaseService.initDatabase();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(HarmoniqApp(
    databaseService: databaseService,
    prefs: prefs,
  ));
}

class HarmoniqApp extends StatelessWidget {
  final DatabaseService databaseService;
  final SharedPreferences prefs;

  const HarmoniqApp({
    super.key,
    required this.databaseService,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(databaseService),
        ),
        Provider.value(value: databaseService),
        Provider.value(value: WebSocketService()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'Harmoniq',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/live-session',
        name: 'live-session',
        builder: (context, state) => const LiveSessionScreen(),
      ),
      GoRoute(
        path: '/session-summary/:sessionId',
        name: 'session-summary',
        builder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          return SessionSummaryScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/past-sessions',
        name: 'past-sessions',
        builder: (context, state) => const PastSessionsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
