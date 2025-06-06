import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/confidence_slider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Audio Settings Section
              _buildSectionHeader(context, 'Audio Settings', Icons.mic),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Confidence Threshold',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      ConfidenceSlider(
                        value: settings.confidenceThreshold,
                        onChanged: settings.setConfidenceThreshold,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Display Settings Section
              _buildSectionHeader(context, 'Display Settings', Icons.display_settings),
              
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Use dark theme'),
                      value: settings.isDarkMode,
                      onChanged: settings.setDarkMode,
                      activeColor: AppTheme.primaryPink,
                    ),
                    
                    const Divider(height: 1),
                    
                    SwitchListTile(
                      title: const Text('Show Roman Numerals'),
                      subtitle: const Text('Display chord analysis in Roman numerals'),
                      value: settings.showRomanNumerals,
                      onChanged: settings.setShowRomanNumerals,
                      activeColor: AppTheme.primaryPink,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Session Settings Section
              _buildSectionHeader(context, 'Session Settings', Icons.settings),
              
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto-save Sessions'),
                      subtitle: const Text('Automatically save session data'),
                      value: settings.autoSaveSessions,
                      onChanged: settings.setAutoSaveSessions,
                      activeColor: AppTheme.primaryPink,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // About Section
              _buildSectionHeader(context, 'About', Icons.info),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.music_note, color: AppTheme.primaryPink),
                      title: const Text('Harmoniq'),
                      subtitle: const Text('Version 1.0.0'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAboutDialog(context),
                    ),
                    
                    const Divider(height: 1),
                    
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: AppTheme.primaryBlue),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showHelpDialog(context),
                    ),
                    
                    const Divider(height: 1),
                    
                    ListTile(
                      leading: const Icon(Icons.refresh, color: AppTheme.primaryPurple),
                      title: const Text('Reset to Defaults'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showResetConfirmation(context, settings),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryPink),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.music_note, color: AppTheme.primaryPink),
              SizedBox(width: 8),
              Text('About Harmoniq'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Harmoniq is a real-time chord progression detector and analyzer for aspiring pianists and composers.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Real-time chord detection'),
              Text('• Key signature analysis'),
              Text('• Roman numeral notation'),
              Text('• Session history'),
              Text('• Pattern recognition'),
              SizedBox(height: 16),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use Harmoniq:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('1. Tap "Start Session" on the home screen'),
              Text('2. Play chords clearly on your piano'),
              Text('3. Watch real-time chord detection'),
              Text('4. Adjust confidence threshold as needed'),
              Text('5. Stop session to view analysis'),
              SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Play chords clearly and hold them'),
              Text('• Ensure good microphone quality'),
              Text('• Adjust confidence threshold for accuracy'),
              Text('• Use in a quiet environment'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text(
            'Are you sure you want to reset all settings to their default values?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                settings.resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults'),
                    backgroundColor: AppTheme.primaryPink,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
