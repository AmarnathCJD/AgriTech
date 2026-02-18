import 'package:intl/intl.dart';

class CommunityPost {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String authorId;
  final String authorName;
  final String? authorMobile;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final int userVote; // 1, -1, or 0
  final bool isOwner;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.authorId,
    required this.authorName,
    this.authorMobile,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.commentCount,
    this.userVote = 0,
    this.isOwner = false,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    String id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    if (id.isEmpty) {
      print('Warning: CommunityPost ID is empty. JSON: $json');
    }
    return CommunityPost(
      id: id,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      authorId: json['author_id']?.toString() ?? '',
      authorName: json['author_name'] ?? 'Anonymous',
      authorMobile: json['author_mobile'],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      userVote: json['user_vote'] ?? 0,
      isOwner: json['is_owner'] ?? false,
    );
  }

  String get formattedDate {
    return DateFormat.yMMMd().format(createdAt);
  }
}

class CommunityComment {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final int userVote;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    this.userVote = 0,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['_id'] ?? '',
      postId: json['post_id'] ?? '',
      content: json['content'] ?? '',
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? 'Anonymous',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      userVote: json['user_vote'] ?? 0,
    );
  }

  String get formattedDate {
    return DateFormat.yMMMd().format(createdAt);
  }
}
