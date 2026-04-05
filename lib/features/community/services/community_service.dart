import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:styleiq/features/community/models/community_post.dart';

/// Service that manages community posts and comments via local Hive boxes.
class CommunityService {
  static const String _boxName = 'community_posts';
  static const String _commentsBoxName = 'community_comments';

  Box<String> get _box => Hive.box<String>(_boxName);
  Box<String> get _commentsBox => Hive.box<String>(_commentsBoxName);

  // ── Initialisation ─────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    await Hive.openBox<String>(_boxName);
    await Hive.openBox<String>(_commentsBoxName);
  }

  // ── Comments ───────────────────────────────────────────────────────────────

  Future<List<Map<String, String>>> getComments(String postId) async {
    final raw = _commentsBox.get(postId);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    } catch (e, stack) {
      developer.log('Error decoding comments for post $postId', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<void> addComment(
      String postId, String author, String text) async {
    final existing = await getComments(postId);
    existing.insert(0, {
      'author': author,
      'text': text,
      'time': DateTime.now().toIso8601String(),
    });
    await _commentsBox.put(postId, jsonEncode(existing));
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<List<CommunityPost>> getPosts() async {
    final rawValues = _box.values.toList();
    final posts = rawValues.map((raw) {
      try {
        return CommunityPost.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (e) {
        if (kDebugMode) print('Error parsing post: $e');
        return null;
      }
    }).whereType<CommunityPost>().toList();

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<void> addPost(CommunityPost post) async {
    await _box.put(post.id, jsonEncode(post.toJson()));
  }

  Future<void> toggleLike(String postId) async {
    final raw = _box.get(postId);
    if (raw == null) return;

    final post = CommunityPost.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    final updated = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likeCount:
          post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
    );

    await _box.put(postId, jsonEncode(updated.toJson()));
  }

  Future<void> toggleBookmark(String postId) async {
    final raw = _box.get(postId);
    if (raw == null) return;

    final post = CommunityPost.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    final updated = post.copyWith(isBookmarked: !post.isBookmarked);
    await _box.put(postId, jsonEncode(updated.toJson()));
  }

  // ── Demo seed data ─────────────────────────────────────────────────────────

  Future<void> seedDemoPosts() async {
    if (_box.isNotEmpty) return;

    final now = DateTime.now();

    final demos = <CommunityPost>[
      CommunityPost(
        userId: 'demo_aisha',
        userName: 'Aisha Rahman',
        userInitials: 'AR',
        avatarColor: 0xFF9C27B0,
        caption:
            'Finally got my Eid outfit score! The AI nailed the color harmony analysis 🌟',
        tags: ['#eid', '#modest', '#elegant'],
        score: 92.0,
        grade: 'A+',
        headline: 'Elegant Eid Ensemble',
        likeCount: 87,
        isLikedByMe: false,
        isBookmarked: false,
        createdAt: now.subtract(const Duration(hours: 3)),
        postType: 'score_card',
      ),
      CommunityPost(
        userId: 'demo_james',
        userName: 'James Chen',
        userInitials: 'JC',
        avatarColor: 0xFF2196F3,
        caption:
            'Street style meets minimalism. What do you all think of this combo?',
        tags: ['#streetwear', '#minimal', '#korean'],
        score: 78.0,
        grade: 'B+',
        headline: 'Urban Minimalist',
        likeCount: 45,
        isLikedByMe: false,
        isBookmarked: false,
        createdAt: now.subtract(const Duration(hours: 8)),
        postType: 'score_card',
      ),
      CommunityPost(
        userId: 'demo_sofia',
        userName: 'Sofia Mensah',
        userInitials: 'SM',
        avatarColor: 0xFFE91E63,
        caption:
            'Pro tip: The rule of three colors is real. Tried it today and my score jumped 15 points!',
        tags: ['#colortips', '#styling101'],
        likeCount: 120,
        isLikedByMe: false,
        isBookmarked: false,
        createdAt: now.subtract(const Duration(hours: 14)),
        postType: 'tip',
      ),
      CommunityPost(
        userId: 'demo_raj',
        userName: 'Raj Patel',
        userInitials: 'RP',
        avatarColor: 0xFFFF5722,
        caption:
            'Traditional kurta with modern joggers — fusion done right! AI gave me 85/100 🎉',
        tags: ['#fusion', '#indian', '#modern'],
        score: 85.0,
        grade: 'A',
        headline: 'Contemporary Fusion',
        likeCount: 63,
        isLikedByMe: false,
        isBookmarked: false,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        postType: 'score_card',
      ),
      CommunityPost(
        userId: 'demo_emma',
        userName: 'Emma Wilson',
        userInitials: 'EW',
        avatarColor: 0xFF009688,
        caption:
            'Business casual is an art. Here\'s how I approach Monday meetings 💼',
        tags: ['#businesscasual', '#workwear'],
        score: 88.0,
        grade: 'A',
        headline: 'Power Business Casual',
        likeCount: 95,
        isLikedByMe: false,
        isBookmarked: false,
        createdAt: now.subtract(const Duration(days: 2)),
        postType: 'score_card',
      ),
      CommunityPost(
        userId: 'demo_yuki',
        userName: 'Yuki Tanaka',
        userInitials: 'YT',
        avatarColor: 0xFFFF4081,
        caption:
            'Harajuku meets corporate — tried the AI makeover feature and I\'m obsessed 🇯🇵',
        tags: ['#harajuku', '#japanese', '#stylefusion'],
        likeCount: 78,
        isLikedByMe: false,
        isBookmarked: false,
        createdAt: now.subtract(const Duration(days: 3)),
        postType: 'inspiration',
      ),
      CommunityPost(
        userId: 'demo_marcus',
        userName: 'Marcus Johnson',
        userInitials: 'MJ',
        avatarColor: 0xFF4CAF50,
        caption:
            'Fit check! Nigerian Ankara print blazer with black trousers. Culture in every thread ✊🏿',
        tags: ['#ankara', '#nigerian', '#afrofashion'],
        score: 91.0,
        grade: 'A+',
        headline: 'Afrocentric Power Look',
        likeCount: 104,
        isLikedByMe: false,
        isBookmarked: false,
        createdAt: now.subtract(const Duration(days: 4)),
        postType: 'score_card',
      ),
      CommunityPost(
        userId: 'demo_leila',
        userName: 'Leila Ahmadi',
        userInitials: 'LA',
        avatarColor: 0xFF3F51B5,
        caption:
            'Layering is everything in winter. These 3 tips will save your cold-weather outfits ❄️',
        tags: ['#winterstyle', '#layering', '#tips'],
        likeCount: 55,
        isLikedByMe: false,
        isBookmarked: false,
        createdAt: now.subtract(const Duration(days: 6)),
        postType: 'tip',
      ),
    ];

    for (final post in demos) {
      await _box.put(post.id, jsonEncode(post.toJson()));
    }
  }
}
