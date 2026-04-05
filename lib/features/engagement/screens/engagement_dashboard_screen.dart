import 'package:flutter/material.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/features/engagement/services/engagement_service.dart';
import 'package:styleiq/models/engagement_state.dart';

class EngagementDashboardScreen extends StatefulWidget {
  const EngagementDashboardScreen({super.key});

  @override
  State<EngagementDashboardScreen> createState() =>
      _EngagementDashboardScreenState();
}

class _EngagementDashboardScreenState extends State<EngagementDashboardScreen> {
  final _engagementService = EngagementService();

  EngagementState? _state;
  bool _isSaving = false;

  String get _userId => AppUserService.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final state = await _engagementService.prepareDailyChallenge(_userId);
    if (mounted) {
      setState(() => _state = state);
    }
  }

  Future<void> _completeChallenge() async {
    if (_state == null || _isSaving) return;

    setState(() => _isSaving = true);
    final updated = await _engagementService.checkInToday(_userId);
    if (mounted) {
      setState(() {
        _state = updated;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated.isCheckedInToday
              ? 'Challenge completed! +20 points'
              : 'Already checked in today.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('StyleIQ Challenge'),
        backgroundColor: AppTheme.primaryMain,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Daily Style Challenge',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Keep your style streak alive by completing one quick action every day.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _StatTile(
                        label: 'Current Streak',
                        value: '${_state!.currentStreak} days'),
                    const SizedBox(height: 8),
                    _StatTile(
                        label: 'Total Points',
                        value: '${_state!.totalPoints} pts'),
                    const SizedBox(height: 8),
                    _StatTile(
                        label: 'Style Level', value: 'Level ${_state!.level}'),
                    const SizedBox(height: 8),
                    _StatTile(
                      label: 'Next Reward',
                      value:
                          'Level ${_state!.level + 1} at ${(_state!.level < 7 ? ([
                                0,
                                80,
                                180,
                                300,
                                500,
                                800,
                                1200
                              ][_state!.level] - _state!.totalPoints) : 0)} pts',
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSaving || _state!.isCheckedInToday
                    ? null
                    : _completeChallenge,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_state!.isCheckedInToday
                    ? 'Challenge Completed Today'
                    : 'Complete Today’s Challenge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMain,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 20),
              if (_state!.badges.isNotEmpty) ...[
                const Text('Badges',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _state!.badges
                      .map((badge) => Chip(label: Text(badge)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
