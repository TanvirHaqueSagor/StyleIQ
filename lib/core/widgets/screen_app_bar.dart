import 'package:flutter/material.dart';

/// Standard StyleIQ app bar — deep purple background, white text, left-aligned.
/// Drop-in replacement for [AppBar] in any screen's [Scaffold.appBar].
class ScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const ScreenAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2D1B6B),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      automaticallyImplyLeading: automaticallyImplyLeading,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.2,
        ),
      ),
      actions: actions,
    );
  }
}
