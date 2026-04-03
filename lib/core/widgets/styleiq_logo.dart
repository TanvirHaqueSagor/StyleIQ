import 'package:flutter/material.dart';
import 'package:styleiq/core/theme/app_theme.dart';

/// The StyleIQ brand logo widget.
/// Renders a gradient rounded square with a fashion + intelligence icon mark.
/// Use [size] to scale it (default 80). The corner radius scales proportionally.
class StyleIQLogo extends StatelessWidget {
  final double size;
  final bool withShadow;

  const StyleIQLogo({super.key, this.size = 80, this.withShadow = true});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.26;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryMain, AppTheme.accentMain],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: AppTheme.primaryMain.withValues(alpha: 0.35),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.10),
                )
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main fashion icon
          Icon(
            Icons.checkroom,
            size: size * 0.52,
            color: Colors.white,
          ),
          // Intelligence sparkle — top-right accent
          Positioned(
            top: size * 0.10,
            right: size * 0.10,
            child: Icon(
              Icons.auto_awesome,
              size: size * 0.24,
              color: Colors.white.withValues(alpha: 0.90),
            ),
          ),
        ],
      ),
    );
  }
}
