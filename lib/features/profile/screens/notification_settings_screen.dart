import 'package:flutter/material.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/models/notification_settings.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  static const String _userId = 'guest';
  final LocalStorageService _storage = LocalStorageService();
  NotificationSettings? _settings;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _storage.getNotificationSettings(_userId);
    if (mounted) {
      setState(() => _settings = settings);
    }
  }

  Future<void> _updateSetting(NotificationSettings updated) async {
    setState(() => _saving = true);
    await _storage.saveNotificationSettings(updated);
    if (mounted) {
      setState(() {
        _settings = updated;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      backgroundColor: AppTheme.scaffoldBg,
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      value: settings.pushNotifications,
                      onChanged: (v) => _updateSetting(settings.copyWith(pushNotifications: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Email Notifications'),
                      value: settings.emailNotifications,
                      onChanged: (v) => _updateSetting(settings.copyWith(emailNotifications: v)),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Interest Updates', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SwitchListTile(
                      title: const Text('Daily Style Tips'),
                      value: settings.dailyStyleTips,
                      onChanged: (v) => _updateSetting(settings.copyWith(dailyStyleTips: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Weekly Digest'),
                      value: settings.weeklyDigest,
                      onChanged: (v) => _updateSetting(settings.copyWith(weeklyDigest: v)),
                    ),
                    SwitchListTile(
                      title: const Text('New Features'),
                      value: settings.newFeatures,
                      onChanged: (v) => _updateSetting(settings.copyWith(newFeatures: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Cultural Reminders'),
                      value: settings.culturalReminders,
                      onChanged: (v) => _updateSetting(settings.copyWith(culturalReminders: v)),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Your notification settings are stored locally. Enable these alerts to stay up to date on style guidance and community activity.',
                      ),
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
                if (_saving)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}
