import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/recent_sessions_list.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation for the start button
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    
    // Load recent sessions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadRecentSessions();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              const SizedBox(height: 40),
              
              // Main start session button
              _buildStartSessionButton(context),
              
              const SizedBox(height: 40),
              
              // Recent sessions section
              Expanded(
                child: _buildRecentSessionsSection(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Harmoniq',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppTheme.primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Your musical companion 🎵',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings),
          iconSize: 28,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryLavender.withOpacity(0.3),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildStartSessionButton(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        final canStart = sessionProvider.canStartSession;
        
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: canStart ? _pulseAnimation.value : 1.0,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: canStart 
                        ? [AppTheme.primaryPink, AppTheme.primaryPurple]
                        : [Colors.grey[400]!, Colors.grey[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: (canStart ? AppTheme.primaryPink : Colors.grey)
                          .withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canStart ? () => _startSession(context) : null,
                    borderRadius: BorderRadius.circular(30),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            canStart ? Icons.mic : Icons.hourglass_empty,
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                canStart ? 'Start Session' : 'Connecting...',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                canStart 
                                    ? 'Begin chord detection'
                                    : 'Please wait',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSessionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            TextButton.icon(
              onPressed: () => context.push('/past-sessions'),
              icon: const Icon(Icons.history),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryPink,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              if (sessionProvider.recentSessions.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return RecentSessionsList(
                sessions: sessionProvider.recentSessions,
                onSessionTap: (session) {
                  if (session.id != null) {
                    context.push('/session-summary/${session.id}');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first session to see\nyour chord progressions here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(BuildContext context) async {
    final sessionProvider = context.read<SessionProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    
    final success = await sessionProvider.startSession(
      confidenceThreshold: settingsProvider.confidenceThreshold,
    );
    
    if (success && mounted) {
      context.push('/live-session');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start session. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
