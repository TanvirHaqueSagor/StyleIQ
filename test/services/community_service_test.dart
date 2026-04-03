// Community service tests exercise the pure business logic of CommunityService
// (sorting, toggle-like, toggle-bookmark, seed count) via a real in-memory
// Hive box opened with hive_flutter in a temporary directory.
//
// NOTE: `hive_test` is not in dev_dependencies so we initialise Hive manually
// with a temp path and tear it down after every test. Each test gets a fresh
// box so tests are fully independent.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:styleiq/features/community/models/community_post.dart';
import 'package:styleiq/features/community/services/community_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Creates a minimal [CommunityPost] for use in tests.
CommunityPost _post({
  required String id,
  int likeCount = 5,
  bool isLikedByMe = false,
  bool isBookmarked = false,
  DateTime? createdAt,
}) =>
    CommunityPost(
      id: id,
      userId: 'test_user',
      userName: 'Test User',
      userInitials: 'TU',
      avatarColor: 0xFF9C27B0,
      caption: 'Test caption',
      tags: const [],
      likeCount: likeCount,
      isLikedByMe: isLikedByMe,
      isBookmarked: isBookmarked,
      createdAt: createdAt ?? DateTime(2024, 6, 1),
      postType: 'tip',
    );

// ── Setup / teardown ──────────────────────────────────────────────────────────

late Directory _tempDir;

Future<void> _setUp() async {
  _tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(_tempDir.path);
  await CommunityService.initialize();
}

Future<void> _tearDown() async {
  await Hive.deleteBoxFromDisk('community_posts');
  await Hive.close();
  await _tempDir.delete(recursive: true);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CommunityService', () {
    setUp(_setUp);
    tearDown(_tearDown);

    // ── getPosts ─────────────────────────────────────────────────────────────

    group('getPosts', () {
      test('returns empty list when no posts exist', () async {
        final service = CommunityService();
        final posts = await service.getPosts();
        expect(posts, isEmpty);
      });

      test('returns posts sorted by createdAt descending', () async {
        final service = CommunityService();

        final older = _post(id: 'old', createdAt: DateTime(2024, 1, 1));
        final newer = _post(id: 'new', createdAt: DateTime(2024, 6, 1));
        final newest = _post(id: 'newest', createdAt: DateTime(2024, 12, 31));

        // Add in non-chronological order
        await service.addPost(newer);
        await service.addPost(older);
        await service.addPost(newest);

        final posts = await service.getPosts();
        expect(posts.length, 3);
        expect(posts[0].id, 'newest');
        expect(posts[1].id, 'new');
        expect(posts[2].id, 'old');
      });

      test('returns all added posts', () async {
        final service = CommunityService();
        await service.addPost(_post(id: 'a'));
        await service.addPost(_post(id: 'b'));
        await service.addPost(_post(id: 'c'));
        final posts = await service.getPosts();
        expect(posts.length, 3);
        expect(posts.map((p) => p.id), containsAll(['a', 'b', 'c']));
      });
    });

    // ── addPost ───────────────────────────────────────────────────────────────

    group('addPost', () {
      test('persists a post that can be retrieved', () async {
        final service = CommunityService();
        final post = _post(id: 'persist-me');
        await service.addPost(post);
        final posts = await service.getPosts();
        expect(posts.any((p) => p.id == 'persist-me'), isTrue);
      });
    });

    // ── toggleLike ────────────────────────────────────────────────────────────

    group('toggleLike', () {
      test('sets isLikedByMe to true and increments likeCount', () async {
        final service = CommunityService();
        await service.addPost(_post(id: 'like-1', likeCount: 10, isLikedByMe: false));

        await service.toggleLike('like-1');

        final posts = await service.getPosts();
        final updated = posts.firstWhere((p) => p.id == 'like-1');
        expect(updated.isLikedByMe, isTrue);
        expect(updated.likeCount, 11);
      });

      test('sets isLikedByMe to false and decrements likeCount', () async {
        final service = CommunityService();
        await service.addPost(_post(id: 'like-2', likeCount: 10, isLikedByMe: true));

        await service.toggleLike('like-2');

        final posts = await service.getPosts();
        final updated = posts.firstWhere((p) => p.id == 'like-2');
        expect(updated.isLikedByMe, isFalse);
        expect(updated.likeCount, 9);
      });

      test('double-toggle restores original state', () async {
        final service = CommunityService();
        await service.addPost(_post(id: 'like-3', likeCount: 5, isLikedByMe: false));

        await service.toggleLike('like-3');
        await service.toggleLike('like-3');

        final posts = await service.getPosts();
        final updated = posts.firstWhere((p) => p.id == 'like-3');
        expect(updated.isLikedByMe, isFalse);
        expect(updated.likeCount, 5);
      });

      test('does nothing for unknown postId', () async {
        final service = CommunityService();
        // Should not throw
        await expectLater(service.toggleLike('non-existent'), completes);
      });
    });

    // ── toggleBookmark ────────────────────────────────────────────────────────

    group('toggleBookmark', () {
      test('sets isBookmarked to true', () async {
        final service = CommunityService();
        await service.addPost(_post(id: 'bm-1', isBookmarked: false));

        await service.toggleBookmark('bm-1');

        final posts = await service.getPosts();
        final updated = posts.firstWhere((p) => p.id == 'bm-1');
        expect(updated.isBookmarked, isTrue);
      });

      test('sets isBookmarked to false', () async {
        final service = CommunityService();
        await service.addPost(_post(id: 'bm-2', isBookmarked: true));

        await service.toggleBookmark('bm-2');

        final posts = await service.getPosts();
        final updated = posts.firstWhere((p) => p.id == 'bm-2');
        expect(updated.isBookmarked, isFalse);
      });

      test('double-toggle restores original bookmark state', () async {
        final service = CommunityService();
        await service.addPost(_post(id: 'bm-3', isBookmarked: false));

        await service.toggleBookmark('bm-3');
        await service.toggleBookmark('bm-3');

        final posts = await service.getPosts();
        final updated = posts.firstWhere((p) => p.id == 'bm-3');
        expect(updated.isBookmarked, isFalse);
      });

      test('does nothing for unknown postId', () async {
        final service = CommunityService();
        await expectLater(service.toggleBookmark('non-existent'), completes);
      });
    });

    // ── seedDemoPosts ─────────────────────────────────────────────────────────

    group('seedDemoPosts', () {
      test('populates exactly 8 demo posts', () async {
        final service = CommunityService();
        await service.seedDemoPosts();
        final posts = await service.getPosts();
        expect(posts.length, 8);
      });

      test('does not add duplicates when called twice', () async {
        final service = CommunityService();
        await service.seedDemoPosts();
        await service.seedDemoPosts(); // second call must be a no-op
        final posts = await service.getPosts();
        expect(posts.length, 8);
      });

      test('demo posts are sorted newest first', () async {
        final service = CommunityService();
        await service.seedDemoPosts();
        final posts = await service.getPosts();
        for (var i = 0; i < posts.length - 1; i++) {
          expect(
            posts[i].createdAt.isAfter(posts[i + 1].createdAt) ||
                posts[i].createdAt.isAtSameMomentAs(posts[i + 1].createdAt),
            isTrue,
            reason: 'Post at index $i should not be older than post at index ${i + 1}',
          );
        }
      });

      test('all demo posts have non-empty captions', () async {
        final service = CommunityService();
        await service.seedDemoPosts();
        final posts = await service.getPosts();
        for (final post in posts) {
          expect(post.caption, isNotEmpty, reason: 'Post ${post.id} has empty caption');
        }
      });

      test('demo posts have valid postType values', () async {
        final service = CommunityService();
        await service.seedDemoPosts();
        final posts = await service.getPosts();
        const validTypes = {'score_card', 'tip', 'inspiration'};
        for (final post in posts) {
          expect(validTypes, contains(post.postType),
              reason: 'Post ${post.id} has invalid postType: ${post.postType}');
        }
      });
    });
  });
}
