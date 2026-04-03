import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/live_score.dart';

/// Bottom-bar button that expands into a scrollable pill row for occasion selection.
class OccasionSelector extends StatefulWidget {
  final LiveOccasion selected;
  final ValueChanged<LiveOccasion> onChanged;

  const OccasionSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<OccasionSelector> createState() => _OccasionSelectorState();
}

class _OccasionSelectorState extends State<OccasionSelector> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scrollable pill row
        if (_expanded)
          Container(
            height: 44,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: LiveOccasion.values.map((o) {
                final isSelected = o == widget.selected;
                return GestureDetector(
                  onTap: () {
                    widget.onChanged(o);
                    setState(() => _expanded = false);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFd4a853)
                          : Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFd4a853)
                            : Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(o.emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          o.label,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Compact trigger button
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.selected.emoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  widget.selected.label,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
