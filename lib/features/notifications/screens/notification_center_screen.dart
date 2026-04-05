import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/features/notifications/services/notification_service.dart';
import 'package:styleiq/models/notification.dart' as siq;

// ── Design tokens ─────────────────────────────────────────────────────────────
const Color _surface = Color(0xFFFAF9FF);
const Color _surfaceLow = Color(0xFFF0EFF9);
const Color _surfaceCard = Color(0xFFFFFFFF);
const Color _onSurface = Color(0xFF1A1528);
const Color _midTone = Color(0xFF6B6882);
const Color _unreadDot = AppTheme.primaryMain;
// ─────────────────────────────────────────────────────────────────────────────

List<siq.Notification> _seedNotifications(String userId) => [
      siq.Notification(
        userId: userId,
        title: 'Welcome to StyleIQ! 🎉',
        message:
            'Your AI style journey starts now. Upload your first outfit and get a score.',
        type: 'welcome',
        category: 'system',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      siq.Notification(
        userId: userId,
        title: 'Style Tip of the Day',
        message:
            'Neutral tones pair effortlessly with bold accessories. Try a statement belt or bag today.',
        type: 'style_tip',
        category: 'tips',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      siq.Notification(
        userId: userId,
        title: 'Cultural Spotlight: Holi',
        message:
            'Holi is around the corner — explore vibrant colour combinations that celebrate the festival.',
        type: 'cultural',
        category: 'cultural',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      siq.Notification(
        userId: userId,
        title: 'New Feature: Live Camera',
        message:
            'Get real-time outfit scores while you dress up. Tap the camera icon on the home screen.',
        type: 'feature',
        category: 'system',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService();

  List<siq.Notification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = AppUserService.currentUserId;
      var list = await _notificationService.getNotifications(userId);
      if (list.isEmpty) {
        for (final n in _seedNotifications(userId)) {
          await _notificationService.addNotification(userId, n);
        }
        list = await _notificationService.getNotifications(userId);
      }
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload() async {
    final list = await _notificationService
        .getNotifications(AppUserService.currentUserId);
    if (mounted) setState(() => _notifications = list);
  }

  Future<void> _markRead(siq.Notification n) async {
    await _notificationService.markAsRead(AppUserService.currentUserId, n.id);
    await _reload();
  }

  Future<void> _markAllRead() async {
    await _notificationService.markAllAsRead(AppUserService.currentUserId);
    await _reload();
  }

  Future<void> _delete(siq.Notification n) async {
    await _notificationService.deleteNotification(
      AppUserService.currentUserId,
      n.id,
    );
    await _reload();
  }

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_notifications.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildTile(_notifications[i], i),
                childCount: _notifications.length,
              ),
            ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 112,
      backgroundColor: const Color(0xFF2D1B6B),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (_unreadCount > 0)
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              'Mark all read',
              style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: const Color(0xFF2D1B6B),
          padding: EdgeInsets.fromLTRB(20, topPad + 56, 20, 16),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.notoSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (_unreadCount > 0)
                Text(
                  '$_unreadCount unread',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(siq.Notification n, int index) {
    final isUnread = n.isUnread;
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.coral.withValues(alpha: 0.12),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.coral, size: 22),
      ),
      onDismissed: (_) => _delete(n),
      child: GestureDetector(
        onTap: () {
          if (isUnread) _markRead(n);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: isUnread
                ? AppTheme.primaryMain.withValues(alpha: 0.04)
                : _surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? AppTheme.primaryMain.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _typeIcon(n.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: _onSurface,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _unreadDot,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.message,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _midTone,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _relativeTime(n.createdAt),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _midTone.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 40 * index))
            .fadeIn(duration: 280.ms)
            .slideX(begin: 0.04, end: 0),
      ),
    );
  }

  Widget _typeIcon(String type) {
    final (icon, color) = switch (type) {
      'welcome' => (Icons.celebration_rounded, AppTheme.accentMain),
      'style_tip' => (Icons.auto_awesome_rounded, AppTheme.amber),
      'cultural' => (Icons.language_rounded, AppTheme.primaryMain),
      'feature' => (Icons.new_releases_rounded, AppTheme.coral),
      _ => (Icons.notifications_rounded, _midTone),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _surfaceLow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 36, color: _midTone),
          ),
          const SizedBox(height: 20),
          Text(
            'All caught up',
            style: GoogleFonts.notoSerif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No notifications right now.',
            style: GoogleFonts.inter(fontSize: 14, color: _midTone),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
