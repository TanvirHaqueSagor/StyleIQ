import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/live_score.dart';

/// State-aware frosted-glass pill shown at the top-center of the camera screen.
///
/// Colors: gold = analyzing, teal = updated, gray = monitoring, red = error.
class StatusPill extends StatelessWidget {
  final LiveState state;

  const StatusPill({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(state);

    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: config.color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              shadows: const [
                Shadow(color: Colors.black45, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );

    // Pulsing glow for analyzing state
    if (state == LiveState.analyzing || state == LiveState.firstScan) {
      pill = pill
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.04,
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }

    return pill;
  }

  _PillConfig _configFor(LiveState state) {
    switch (state) {
      case LiveState.initializing:
        return const _PillConfig(
          label: 'Setting up camera...',
          icon: Icons.videocam_rounded,
          color: Color(0xFF888888),
        );
      case LiveState.firstScan:
        return const _PillConfig(
          label: 'Analyzing your outfit...',
          icon: Icons.auto_awesome,
          color: Color(0xFFd4a853),
        );
      case LiveState.scored:
        return const _PillConfig(
          label: 'Score Updated!',
          icon: Icons.check_circle_rounded,
          color: Color(0xFF4ecdc4),
        );
      case LiveState.monitoring:
        return const _PillConfig(
          label: 'Watching for changes...',
          icon: Icons.remove_red_eye_rounded,
          color: Color(0xFF555566),
        );
      case LiveState.analyzing:
        return const _PillConfig(
          label: 'Re-analyzing...',
          icon: Icons.auto_awesome,
          color: Color(0xFFd4a853),
        );
      case LiveState.error:
        return const _PillConfig(
          label: "Couldn't analyze — retrying...",
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFe06b7a),
        );
      case LiveState.rateLimited:
        return const _PillConfig(
          label: 'Taking a breather...',
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFF888888),
        );
    }
  }
}

class _PillConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _PillConfig(
      {required this.label, required this.icon, required this.color});
}
