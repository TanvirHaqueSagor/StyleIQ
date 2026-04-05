import 'package:flutter/material.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/models/privacy_settings.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final LocalStorageService _storage = LocalStorageService();
  PrivacySettings? _settings;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings =
        await _storage.getPrivacySettings(AppUserService.currentUserId);
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _update(PrivacySettings updated) async {
    setState(() => _saving = true);
    await _storage.savePrivacySettings(updated);
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
      appBar: AppBar(title: const Text('Privacy Settings')),
      backgroundColor: AppTheme.scaffoldBg,
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    SwitchListTile(
                      title: const Text('Analytics Enabled'),
                      value: settings.analyticsEnabled,
                      onChanged: (value) =>
                          _update(settings.copyWith(analyticsEnabled: value)),
                    ),
                    SwitchListTile(
                      title: const Text('Crash Reporting'),
                      value: settings.crashReporting,
                      onChanged: (value) =>
                          _update(settings.copyWith(crashReporting: value)),
                    ),
                    SwitchListTile(
                      title: const Text('Personalized Ads'),
                      value: settings.personalizedAds,
                      onChanged: (value) =>
                          _update(settings.copyWith(personalizedAds: value)),
                    ),
                    SwitchListTile(
                      title: const Text('Data Sharing'),
                      value: settings.dataSharing,
                      onChanged: (value) =>
                          _update(settings.copyWith(dataSharing: value)),
                    ),
                    SwitchListTile(
                      title: const Text('Profile Visibility'),
                      value: settings.profileVisibility,
                      onChanged: (value) =>
                          _update(settings.copyWith(profileVisibility: value)),
                    ),
                    SwitchListTile(
                      title: const Text('Show Wardrobe Items Publicly'),
                      value: settings.wardrobePublic,
                      onChanged: (value) =>
                          _update(settings.copyWith(wardrobePublic: value)),
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text('Data Rights'),
                      subtitle: Text(
                          'Request data export or deletion through support@styleiq.com.'),
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
