import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';
import 'package:styleiq/features/community/models/community_post.dart';
import 'package:styleiq/features/community/services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  final AnalysisService _analysisService = AnalysisService();
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<CommunityPost> _allPosts = [];
  bool _isLoading = true;
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await CommunityService.initialize();
    await _communityService.seedDemoPosts();
    await _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _communityService.getPosts();
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Filtered lists ─────────────────────────────────────────────────────────

  List<CommunityPost> _applySearch(List<CommunityPost> posts) {
    if (_searchQuery.trim().isEmpty) return posts;
    final q = _searchQuery.toLowerCase();
    return posts
        .where(
          (p) =>
              p.caption.toLowerCase().contains(q) ||
              p.userName.toLowerCase().contains(q) ||
              p.tags.any((t) => t.toLowerCase().contains(q)) ||
              (p.headline?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  List<CommunityPost> get _trendingPosts {
    final list = List<CommunityPost>.from(_allPosts);
    list.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return _applySearch(list);
  }

  List<CommunityPost> get _recentPosts {
    final list = List<CommunityPost>.from(_allPosts);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _applySearch(list);
  }

  List<CommunityPost> get _myPosts =>
      _applySearch(_allPosts.where((p) => p.userId == _userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  // ── Like / Bookmark helpers ─────────────────────────────────────────────────

  Future<void> _handleLike(CommunityPost post) async {
    // Optimistic update
    final idx = _allPosts.indexWhere((p) => p.id == post.id);
    if (idx == -1) return;
    setState(() {
      _allPosts[idx] = post.copyWith(
        isLikedByMe: !post.isLikedByMe,
        likeCount: post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
      );
    });
    await _communityService.toggleLike(post.id);
  }

  Future<void> _handleBookmark(CommunityPost post) async {
    final idx = _allPosts.indexWhere((p) => p.id == post.id);
    if (idx == -1) return;
    setState(() {
      _allPosts[idx] = post.copyWith(isBookmarked: !post.isBookmarked);
    });
    await _communityService.toggleBookmark(post.id);
  }

  // ── Time-ago helper ─────────────────────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  // ── Create-post bottom sheet ────────────────────────────────────────────────

  Future<void> _showCreatePostSheet() async {
    List<StyleAnalysis> history = [];
    try {
      history = await _analysisService.getAnalysisHistory(_userId);
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreatePostSheet(
        history: history,
        onPost: (post) async {
          await _communityService.addPost(post);
          await _loadPosts();
        },
      ),
    );
  }

  // ── Post detail sheet ───────────────────────────────────────────────────────

  void _showPostDetail(CommunityPost post, String timeAgo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PostDetailSheet(
        post: post,
        timeAgo: timeAgo,
        service: _communityService,
        onLike: () => _handleLike(post),
        onBookmark: () => _handleBookmark(post),
        onShare: () => _sharePost(post),
      ),
    );
  }

  // ── Comments sheet ─────────────────────────────────────────────────────────

  void _showCommentsSheet(CommunityPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CommentsSheet(post: post, service: _communityService),
    );
  }

  // ── Share ───────────────────────────────────────────────────────────────────

  void _sharePost(CommunityPost post) {
    final score = post.score != null
        ? ' • Score ${post.score!.toStringAsFixed(0)}/100'
        : '';
    final tags = post.tags.join(' ');
    Share.share(
      '${post.caption}$score\n$tags\n\nShared via StyleIQ ✨',
      subject: post.headline ?? 'StyleIQ Style Post',
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFab(),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_showSearch) _buildSearchBar(),
          _buildStickyTabBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildFeed(),
          // Bottom padding so FAB doesn't overlap last card
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B6B), AppTheme.primaryMain],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMain.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _showCreatePostSheet,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Share Style',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: true,
      backgroundColor: const Color(0xFF2D1B6B),
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: false,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            'Preview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Search bar (shown below AppBar when active) ──────────────────────────────

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFF2D1B6B),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(
              color: AppTheme.dark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppTheme.primaryMain,
            decoration: InputDecoration(
              hintText: 'Search posts, people, tags…',
              hintStyle: const TextStyle(
                color: AppTheme.mediumGrey,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.mediumGrey,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.mediumGrey, size: 18),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sticky tab bar ──────────────────────────────────────────────────────────

  SliverPersistentHeader _buildStickyTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        tabController: _tabController,
      ),
    );
  }

  // ── Feed ────────────────────────────────────────────────────────────────────

  SliverList _buildFeed() {
    final posts = switch (_tabController.index) {
      0 => _trendingPosts,
      1 => _recentPosts,
      _ => _myPosts,
    };

    if (posts.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([_buildEmptyState()]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _PostCard(
          post: posts[i],
          index: i,
          timeAgo: _timeAgo(posts[i].createdAt),
          onTap: () => _showPostDetail(posts[i], _timeAgo(posts[i].createdAt)),
          onLike: () => _handleLike(posts[i]),
          onBookmark: () => _handleBookmark(posts[i]),
          onComment: () => _showCommentsSheet(posts[i]),
          onShare: () => _sharePost(posts[i]),
        ),
        childCount: posts.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMyPosts = _tabController.index == 2;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text(
            isMyPosts ? 'No posts yet' : 'Nothing here yet',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMyPosts
                ? 'Share your first style analysis with the community'
                : 'Be the first to post something!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.mediumGrey,
              fontSize: 14,
            ),
          ),
          if (isMyPosts) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreatePostSheet,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('Share your first style analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMain,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sticky tab bar delegate ────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  const _TabBarDelegate({required this.tabController});

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabController != tabController;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      height: 48,
      child: TabBar(
        controller: tabController,
        labelColor: AppTheme.primaryMain,
        unselectedLabelColor: AppTheme.mediumGrey,
        indicatorColor: AppTheme.primaryMain,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Trending 🔥'),
          Tab(text: 'Recent ✨'),
          Tab(text: 'My Posts 👤'),
        ],
      ),
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final int index;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const _PostCard({
    required this.post,
    required this.index,
    required this.timeAgo,
    required this.onTap,
    required this.onLike,
    required this.onBookmark,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (post.postType == 'score_card' && post.score != null)
              _buildScoreCardStrip(),
            _buildCaption(),
            if (post.tags.isNotEmpty) _buildTagsRow(),
            _buildActionRow(),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.06, end: 0);
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          // Letter avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(post.avatarColor),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              post.userInitials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.dark,
                  ),
                ),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    color: AppTheme.mediumGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Post type badge
          _PostTypeBadge(postType: post.postType),
          const SizedBox(width: 6),
          // 3-dot menu
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppTheme.mediumGrey,
              ),
              onPressed: () => _showPostOptions(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Post options menu ────────────────────────────────────────────────────────

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Share post'),
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppTheme.coral),
              title: const Text('Report post',
                  style: TextStyle(color: AppTheme.coral)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Post reported — thank you for your feedback')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Score card strip ─────────────────────────────────────────────────────────

  Widget _buildScoreCardStrip() {
    final scoreColor = AppTheme.getScoreColor(post.score!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDark,
            scoreColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Score number
          Text(
            post.score!.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  post.grade ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '/100',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              post.headline ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Caption ──────────────────────────────────────────────────────────────────

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Text(
        post.caption,
        style: const TextStyle(
          color: AppTheme.darkGrey,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }

  // ── Tags row ─────────────────────────────────────────────────────────────────

  Widget _buildTagsRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        itemCount: post.tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryMain.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              post.tags[i],
              style: const TextStyle(
                color: AppTheme.primaryMain,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Action row ───────────────────────────────────────────────────────────────

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        children: [
          // Like
          _ActionButton(
            icon: post.isLikedByMe
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: post.isLikedByMe ? AppTheme.coral : AppTheme.mediumGrey,
            label: '${post.likeCount}',
            onTap: onLike,
          ),
          // Comment
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: AppTheme.mediumGrey,
            label: 'Comment',
            onTap: onComment,
          ),
          const Spacer(),
          // Bookmark
          _ActionButton(
            icon: post.isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            iconColor:
                post.isBookmarked ? AppTheme.primaryMain : AppTheme.mediumGrey,
            label: '',
            onTap: onBookmark,
          ),
          // Share
          _ActionButton(
            icon: Icons.ios_share_rounded,
            iconColor: AppTheme.mediumGrey,
            label: '',
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

// ── Post type badge ───────────────────────────────────────────────────────────

class _PostTypeBadge extends StatelessWidget {
  final String postType;

  const _PostTypeBadge({required this.postType});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (postType) {
      'score_card' => ('Score Card', AppTheme.primaryMain),
      'tip' => ('Tip', AppTheme.accentMain),
      _ => ('Inspo', AppTheme.amber),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Create-post bottom sheet ──────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  final List<StyleAnalysis> history;
  final Future<void> Function(CommunityPost post) onPost;

  const _CreatePostSheet({
    required this.history,
    required this.onPost,
  });

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  static const _availableTags = [
    'Casual',
    'Formal',
    'Streetwear',
    'Traditional',
    'Business',
    'Minimal',
    'Bold',
    'Fusion',
  ];

  final _captionController = TextEditingController();

  StyleAnalysis? _selectedAnalysis;
  final Set<String> _selectedTags = {};
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption')),
      );
      return;
    }

    setState(() => _isPosting = true);

    final post = CommunityPost(
      userId: AppUserService.currentUserId,
      userName: 'You',
      userInitials: 'YO',
      avatarColor: 0xFF534AB7,
      caption: _captionController.text.trim(),
      tags: _selectedTags.map((t) => '#${t.toLowerCase()}').toList(),
      imageUrl: _selectedAnalysis?.imageUrl,
      score: _selectedAnalysis?.overallScore,
      grade: _selectedAnalysis?.letterGrade,
      headline: _selectedAnalysis?.headline,
      likeCount: 0,
      isLikedByMe: false,
      isBookmarked: false,
      createdAt: DateTime.now(),
      postType: _selectedAnalysis != null ? 'score_card' : 'tip',
    );

    try {
      await widget.onPost(post);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Share Your Style',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.dark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analysis picker
                    if (widget.history.isEmpty)
                      _buildNoAnalysisHint()
                    else
                      _buildAnalysisPicker(),

                    const SizedBox(height: 16),

                    // Caption
                    TextField(
                      controller: _captionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Write a caption…',
                        hintStyle: const TextStyle(
                          color: AppTheme.mediumGrey,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppTheme.lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tag chips
                    const Text(
                      'Style Tags',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final selected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primaryMain
                                  : AppTheme.lightGrey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#${tag.toLowerCase()}',
                              style: TextStyle(
                                color:
                                    selected ? Colors.white : AppTheme.darkGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Post button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D1B6B), AppTheme.primaryMain],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: _isPosting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Post to Community',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAnalysisHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppTheme.mediumGrey, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Analyze an outfit first to attach a Score Card to your post.',
              style: TextStyle(
                color: AppTheme.darkGrey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attach a Score Card (optional)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.history.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final analysis = widget.history[i];
              final isSelected = _selectedAnalysis == analysis;
              final scoreColor = AppTheme.getScoreColor(analysis.overallScore);

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedAnalysis = isSelected ? null : analysis;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 130,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryMain.withValues(alpha: 0.08)
                        : AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryMain
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            analysis.overallScore.toStringAsFixed(0),
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            analysis.letterGrade,
                            style: const TextStyle(
                              color: AppTheme.mediumGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        analysis.headline,
                        style: const TextStyle(
                          color: AppTheme.darkGrey,
                          fontSize: 11,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Comments sheet ────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final CommunityPost post;
  final CommunityService service;
  const _CommentsSheet({required this.post, required this.service});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, String>> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final comments = await widget.service.getComments(widget.post.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _loading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    await widget.service.addComment(widget.post.id, 'You', text);
    await _loadComments();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Comments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _comments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text('No comments yet — be the first!',
                            style: TextStyle(color: AppTheme.mediumGrey)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryMain.withValues(alpha: 0.15),
                              child: Text(
                                c['author']![0],
                                style: const TextStyle(
                                    color: AppTheme.primaryMain,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(c['author']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(c['text']!,
                                style: const TextStyle(fontSize: 13)),
                            trailing: Text(c['time']!,
                                style: const TextStyle(
                                    color: AppTheme.mediumGrey, fontSize: 11)),
                          );
                        },
                      ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      hintStyle: const TextStyle(
                          color: AppTheme.mediumGrey, fontSize: 14),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryMain,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post detail sheet ─────────────────────────────────────────────────────────

class _PostDetailSheet extends StatefulWidget {
  final CommunityPost post;
  final String timeAgo;
  final CommunityService service;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onShare;

  const _PostDetailSheet({
    required this.post,
    required this.timeAgo,
    required this.service,
    required this.onLike,
    required this.onBookmark,
    required this.onShare,
  });

  @override
  State<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<_PostDetailSheet> {
  late CommunityPost _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _post.score != null
        ? AppTheme.getScoreColor(_post.score!)
        : AppTheme.primaryMain;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // Author row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(_post.avatarColor),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(_post.userInitials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_post.userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.dark)),
                          Text(widget.timeAgo,
                              style: const TextStyle(
                                  color: AppTheme.mediumGrey, fontSize: 12)),
                        ],
                      ),
                    ),
                    _PostTypeBadge(postType: _post.postType),
                  ],
                ),
                const SizedBox(height: 16),

                // Score card (if applicable)
                if (_post.postType == 'score_card' && _post.score != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryDark,
                          scoreColor.withValues(alpha: 0.9)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _post.score!.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(_post.grade ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16)),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('/100',
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_post.headline != null &&
                            _post.headline!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_post.headline!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 12),
                        // Score bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _post.score! / 100,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Caption
                Text(_post.caption,
                    style: const TextStyle(
                        color: AppTheme.darkGrey, fontSize: 15, height: 1.5)),
                const SizedBox(height: 12),

                // Tags
                if (_post.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _post.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryMain
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t,
                                  style: const TextStyle(
                                      color: AppTheme.primaryMain,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    _ActionButton(
                      icon: _post.isLikedByMe
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: _post.isLikedByMe
                          ? AppTheme.coral
                          : AppTheme.mediumGrey,
                      label: '${_post.likeCount}',
                      onTap: () {
                        widget.onLike();
                        setState(() {
                          _post = _post.copyWith(
                            isLikedByMe: !_post.isLikedByMe,
                            likeCount: _post.isLikedByMe
                                ? _post.likeCount - 1
                                : _post.likeCount + 1,
                          );
                        });
                      },
                    ),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: AppTheme.mediumGrey,
                      label: 'Comment',
                      onTap: () {
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (context.mounted) {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24)),
                              ),
                              builder: (_) => _CommentsSheet(
                                  post: _post, service: widget.service),
                            );
                          }
                        });
                      },
                    ),
                    const Spacer(),
                    _ActionButton(
                      icon: _post.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      iconColor: _post.isBookmarked
                          ? AppTheme.primaryMain
                          : AppTheme.mediumGrey,
                      label: '',
                      onTap: () {
                        widget.onBookmark();
                        setState(() => _post =
                            _post.copyWith(isBookmarked: !_post.isBookmarked));
                      },
                    ),
                    _ActionButton(
                      icon: Icons.ios_share_rounded,
                      iconColor: AppTheme.mediumGrey,
                      label: '',
                      onTap: widget.onShare,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String get _userId => AppUserService.currentUserId;
