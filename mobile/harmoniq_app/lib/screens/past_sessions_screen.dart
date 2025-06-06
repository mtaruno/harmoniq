import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../widgets/recent_sessions_list.dart';
import '../theme/app_theme.dart';

class PastSessionsScreen extends StatefulWidget {
  const PastSessionsScreen({super.key});

  @override
  State<PastSessionsScreen> createState() => _PastSessionsScreenState();
}

class _PastSessionsScreenState extends State<PastSessionsScreen> {
  List<Session> _sessions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final databaseService = context.read<DatabaseService>();
      final sessions = await databaseService.getAllSessions();
      
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sessions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Session> get _filteredSessions {
    if (_searchQuery.isEmpty) return _sessions;
    
    return _sessions.where((session) {
      final name = session.displayName.toLowerCase();
      final key = session.detectedKey?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || key.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Sessions'),
        actions: [
          IconButton(
            onPressed: _showSortOptions,
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search sessions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Sessions list
          Expanded(
            child: _buildSessionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryPink,
        ),
      );
    }
    
    final filteredSessions = _filteredSessions;
    
    if (filteredSessions.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: AppTheme.primaryPink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: RecentSessionsList(
          sessions: filteredSessions,
          onSessionTap: (session) {
            if (session.id != null) {
              context.push('/session-summary/${session.id}');
            }
          },
          onSessionDelete: _deleteSession,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearchQuery = _searchQuery.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchQuery ? Icons.search_off : Icons.music_note_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchQuery ? 'No sessions found' : 'No sessions yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchQuery 
                ? 'Try adjusting your search terms'
                : 'Start your first session to see\nyour chord progressions here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          
          if (hasSearchQuery) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _searchQuery = '');
              },
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort Sessions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Most Recent'),
                onTap: () {
                  _sortSessions(SortOption.mostRecent);
                  Navigator.pop(context);
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.access_time_filled),
                title: const Text('Oldest First'),
                onTap: () {
                  _sortSessions(SortOption.oldest);
                  Navigator.pop(context);
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Longest Duration'),
                onTap: () {
                  _sortSessions(SortOption.longestDuration);
                  Navigator.pop(context);
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Most Chords'),
                onTap: () {
                  _sortSessions(SortOption.mostChords);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sortSessions(SortOption option) {
    setState(() {
      switch (option) {
        case SortOption.mostRecent:
          _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
          break;
        case SortOption.oldest:
          _sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
          break;
        case SortOption.longestDuration:
          _sessions.sort((a, b) {
            final aDuration = a.totalDuration ?? 0;
            final bDuration = b.totalDuration ?? 0;
            return bDuration.compareTo(aDuration);
          });
          break;
        case SortOption.mostChords:
          _sessions.sort((a, b) {
            final aChords = a.chordCount ?? 0;
            final bChords = b.chordCount ?? 0;
            return bChords.compareTo(aChords);
          });
          break;
      }
    });
  }

  Future<void> _deleteSession(Session session) async {
    try {
      final databaseService = context.read<DatabaseService>();
      await databaseService.deleteSession(session.id!);
      
      setState(() {
        _sessions.removeWhere((s) => s.id == session.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${session.displayName}"'),
            backgroundColor: AppTheme.primaryPink,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Implement undo functionality
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

enum SortOption {
  mostRecent,
  oldest,
  longestDuration,
  mostChords,
}
