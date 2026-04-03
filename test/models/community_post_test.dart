import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/community/models/community_post.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

CommunityPost _post({
  String? id,
  String userId = 'user_1',
  String userName = 'Alex Kim',
  String userInitials = 'AK',
  int avatarColor = 0xFF9C27B0,
  String caption = 'Love this outfit!',
  List<String> tags = const ['#casual'],
  String? imageUrl,
  double? score,
  String? grade,
  String? headline,
  int likeCount = 10,
  bool isLikedByMe = false,
  bool isBookmarked = false,
  DateTime? createdAt,
  String postType = 'tip',
}) =>
    CommunityPost(
      id: id,
      userId: userId,
      userName: userName,
      userInitials: userInitials,
      avatarColor: avatarColor,
      caption: caption,
      tags: tags,
      imageUrl: imageUrl,
      score: score,
      grade: grade,
      headline: headline,
      likeCount: likeCount,
      isLikedByMe: isLikedByMe,
      isBookmarked: isBookmarked,
      createdAt: createdAt ?? DateTime(2024, 6, 1, 12),
      postType: postType,
    );

Map<String, dynamic> _postJson({
  String id = 'post-abc',
  String userId = 'user_1',
  String userName = 'Alex Kim',
  String userInitials = 'AK',
  int avatarColor = 0xFF9C27B0,
  String caption = 'Love this outfit!',
  List<String> tags = const ['#casual'],
  String? imageUrl,
  double? score,
  String? grade,
  String? headline,
  int likeCount = 10,
  bool isLikedByMe = false,
  bool isBookmarked = false,
  String createdAt = '2024-06-01T12:00:00.000',
  String postType = 'tip',
}) =>
    {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_initials': userInitials,
      'avatar_color': avatarColor,
      'caption': caption,
      'tags': tags,
      'image_url': imageUrl,
      'score': score,
      'grade': grade,
      'headline': headline,
      'like_count': likeCount,
      'is_liked_by_me': isLikedByMe,
      'is_bookmarked': isBookmarked,
      'created_at': createdAt,
      'post_type': postType,
    };

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CommunityPost construction', () {
    test('auto-generates UUID id when id is null', () {
      final a = _post(id: null);
      final b = _post(id: null);
      expect(a.id, isNotEmpty);
      expect(b.id, isNotEmpty);
      expect(a.id, isNot(equals(b.id)));
    });

    test('preserves provided id', () {
      final post = _post(id: 'fixed-id-123');
      expect(post.id, 'fixed-id-123');
    });
  });

  group('CommunityPost.fromJson', () {
    test('parses all required fields', () {
      final json = _postJson();
      final post = CommunityPost.fromJson(json);
      expect(post.id, 'post-abc');
      expect(post.userId, 'user_1');
      expect(post.userName, 'Alex Kim');
      expect(post.userInitials, 'AK');
      expect(post.avatarColor, 0xFF9C27B0);
      expect(post.caption, 'Love this outfit!');
      expect(post.tags, ['#casual']);
      expect(post.likeCount, 10);
      expect(post.isLikedByMe, isFalse);
      expect(post.isBookmarked, isFalse);
      expect(post.postType, 'tip');
    });

    test('parses createdAt as DateTime', () {
      final post = CommunityPost.fromJson(_postJson(createdAt: '2024-06-01T12:00:00.000'));
      expect(post.createdAt.year, 2024);
      expect(post.createdAt.month, 6);
      expect(post.createdAt.day, 1);
    });

    test('handles null imageUrl', () {
      final post = CommunityPost.fromJson(_postJson(imageUrl: null));
      expect(post.imageUrl, isNull);
    });

    test('handles null score', () {
      final post = CommunityPost.fromJson(_postJson(score: null));
      expect(post.score, isNull);
    });

    test('handles null grade', () {
      final post = CommunityPost.fromJson(_postJson(grade: null));
      expect(post.grade, isNull);
    });

    test('handles null headline', () {
      final post = CommunityPost.fromJson(_postJson(headline: null));
      expect(post.headline, isNull);
    });

    test('parses a score_card post with all optional fields', () {
      final json = _postJson(
        imageUrl: 'data:image/jpeg;base64,abc',
        score: 92.0,
        grade: 'A+',
        headline: 'Elegant Eid Ensemble',
        postType: 'score_card',
      );
      final post = CommunityPost.fromJson(json);
      expect(post.imageUrl, 'data:image/jpeg;base64,abc');
      expect(post.score, 92.0);
      expect(post.grade, 'A+');
      expect(post.headline, 'Elegant Eid Ensemble');
      expect(post.postType, 'score_card');
    });

    test('coerces integer score to double', () {
      final json = _postJson()..['score'] = 85;
      final post = CommunityPost.fromJson(json);
      expect(post.score, isA<double>());
      expect(post.score, 85.0);
    });

    test('defaults likeCount to 0 when missing', () {
      final json = Map<String, dynamic>.from(_postJson())..remove('like_count');
      final post = CommunityPost.fromJson(json);
      expect(post.likeCount, 0);
    });

    test('defaults postType to "tip" when missing', () {
      final json = Map<String, dynamic>.from(_postJson())..remove('post_type');
      final post = CommunityPost.fromJson(json);
      expect(post.postType, 'tip');
    });
  });

  group('CommunityPost.toJson', () {
    test('serialises all fields', () {
      final post = _post(id: 'post-xyz', score: 85.0, grade: 'A', headline: 'Power Look');
      final json = post.toJson();
      expect(json['id'], 'post-xyz');
      expect(json['user_id'], post.userId);
      expect(json['user_name'], post.userName);
      expect(json['user_initials'], post.userInitials);
      expect(json['avatar_color'], post.avatarColor);
      expect(json['caption'], post.caption);
      expect(json['tags'], post.tags);
      expect(json['score'], 85.0);
      expect(json['grade'], 'A');
      expect(json['headline'], 'Power Look');
      expect(json['like_count'], post.likeCount);
      expect(json['is_liked_by_me'], post.isLikedByMe);
      expect(json['is_bookmarked'], post.isBookmarked);
      expect(json['created_at'], isA<String>());
      expect(json['post_type'], post.postType);
    });

    test('toJson / fromJson round-trip preserves all fields', () {
      final original = _post(
        id: 'round-trip-id',
        score: 78.0,
        grade: 'B+',
        headline: 'Urban Minimalist',
        imageUrl: 'data:image/jpeg;base64,xyz',
        postType: 'score_card',
        likeCount: 45,
        isLikedByMe: true,
        isBookmarked: true,
      );
      final copy = CommunityPost.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.userId, original.userId);
      expect(copy.userName, original.userName);
      expect(copy.score, original.score);
      expect(copy.grade, original.grade);
      expect(copy.headline, original.headline);
      expect(copy.imageUrl, original.imageUrl);
      expect(copy.likeCount, original.likeCount);
      expect(copy.isLikedByMe, original.isLikedByMe);
      expect(copy.isBookmarked, original.isBookmarked);
      expect(copy.postType, original.postType);
    });

    test('toJson / fromJson round-trip with all nulls preserved', () {
      final original = _post(imageUrl: null, score: null, grade: null, headline: null);
      final copy = CommunityPost.fromJson(original.toJson());
      expect(copy.imageUrl, isNull);
      expect(copy.score, isNull);
      expect(copy.grade, isNull);
      expect(copy.headline, isNull);
    });
  });

  group('CommunityPost.copyWith', () {
    test('overrides only specified fields', () {
      final original = _post(likeCount: 10, isLikedByMe: false);
      final updated = original.copyWith(likeCount: 11, isLikedByMe: true);
      expect(updated.likeCount, 11);
      expect(updated.isLikedByMe, isTrue);
      // Unchanged
      expect(updated.userId, original.userId);
      expect(updated.caption, original.caption);
      expect(updated.tags, original.tags);
    });

    test('preserves id when not specified', () {
      final original = _post(id: 'keep-me');
      final updated = original.copyWith(caption: 'Updated caption');
      expect(updated.id, 'keep-me');
    });

    test('can flip isBookmarked', () {
      final original = _post(isBookmarked: false);
      final updated = original.copyWith(isBookmarked: true);
      expect(updated.isBookmarked, isTrue);
      expect(original.isBookmarked, isFalse); // original unchanged
    });

    test('can update postType', () {
      final original = _post(postType: 'tip');
      final updated = original.copyWith(postType: 'inspiration');
      expect(updated.postType, 'inspiration');
      expect(original.postType, 'tip'); // original unchanged
    });

    test('preserves createdAt when not specified', () {
      final ts = DateTime(2024, 3, 15, 9, 30);
      final original = _post(createdAt: ts);
      final updated = original.copyWith(caption: 'New caption');
      expect(updated.createdAt, ts);
    });
  });
}
