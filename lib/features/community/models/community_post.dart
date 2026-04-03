import 'package:uuid/uuid.dart';

/// Represents a single post in the StyleIQ Community feed.
class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userInitials;
  final int avatarColor;
  final String caption;
  final List<String> tags;
  final String? imageUrl;
  final double? score;
  final String? grade;
  final String? headline;
  final int likeCount;
  final bool isLikedByMe;
  final bool isBookmarked;
  final DateTime createdAt;

  /// 'score_card' | 'tip' | 'inspiration'
  final String postType;

  CommunityPost({
    String? id,
    required this.userId,
    required this.userName,
    required this.userInitials,
    required this.avatarColor,
    required this.caption,
    required this.tags,
    this.imageUrl,
    this.score,
    this.grade,
    this.headline,
    required this.likeCount,
    required this.isLikedByMe,
    required this.isBookmarked,
    required this.createdAt,
    required this.postType,
  }) : id = id ?? const Uuid().v4();

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userInitials: json['user_initials'] as String,
      avatarColor: json['avatar_color'] as int,
      caption: json['caption'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []),
      imageUrl: json['image_url'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      grade: json['grade'] as String?,
      headline: json['headline'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      postType: json['post_type'] as String? ?? 'tip',
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'created_at': createdAt.toIso8601String(),
      'post_type': postType,
    };
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userInitials,
    int? avatarColor,
    String? caption,
    List<String>? tags,
    String? imageUrl,
    double? score,
    String? grade,
    String? headline,
    int? likeCount,
    bool? isLikedByMe,
    bool? isBookmarked,
    DateTime? createdAt,
    String? postType,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userInitials: userInitials ?? this.userInitials,
      avatarColor: avatarColor ?? this.avatarColor,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      score: score ?? this.score,
      grade: grade ?? this.grade,
      headline: headline ?? this.headline,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      postType: postType ?? this.postType,
    );
  }
}
