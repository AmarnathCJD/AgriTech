import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../models/community_post.dart';
import '../../services/community_service.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  CommunityPost? _post;
  List<CommunityComment> _comments = [];
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final post = await _communityService.getPost(widget.postId);
      final comments = await _communityService.getComments(widget.postId);

      // Load local comments
      final prefs = await SharedPreferences.getInstance();
      final List<String> localCommentsJson =
          prefs.getStringList('local_comments_${widget.postId}') ?? [];

      final localComments = localCommentsJson.map((str) {
        final json = jsonDecode(str);
        return CommunityComment(
          id: json['id'],
          postId: widget.postId,
          content: json['content'],
          authorId: 'local_user',
          authorName: 'You',
          createdAt: DateTime.parse(json['created_at']),
          upvotes: 0,
          downvotes: 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _post = post;
          // specific sort or append?
          // Local comments on top for now
          _comments = [...localComments.reversed, ...comments];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _handlePostVote(int voteType) async {
    if (_post == null) return;

    // Optimistic update
    final int originalVote = _post!.userVote;
    final int originalUpvotes = _post!.upvotes;
    final int originalDownvotes = _post!.downvotes;

    int newUpvotes = originalUpvotes;
    int newDownvotes = originalDownvotes;

    if (originalVote == 1) newUpvotes--;
    if (originalVote == -1) newDownvotes--;

    if (voteType == 1) newUpvotes++;
    if (voteType == -1) newDownvotes++;

    int finalVoteType = voteType;
    if (originalVote == voteType) {
      finalVoteType = 0;
      if (voteType == 1) newUpvotes--;
      if (voteType == -1) newDownvotes--;
    }

    setState(() {
      _post = CommunityPost(
        id: _post!.id,
        title: _post!.title,
        content: _post!.content,
        tags: _post!.tags,
        authorId: _post!.authorId,
        authorName: _post!.authorName,
        createdAt: _post!.createdAt,
        upvotes: newUpvotes,
        downvotes: newDownvotes,
        commentCount: _post!.commentCount,
        userVote: finalVoteType,
        isOwner: _post!.isOwner,
      );
    });

    final success = await _communityService.votePost(_post!.id, finalVoteType);
    if (!success) {
      if (mounted) {
        setState(() {
          _post = CommunityPost(
            id: _post!.id,
            title: _post!.title,
            content: _post!.content,
            tags: _post!.tags,
            authorId: _post!.authorId,
            authorName: _post!.authorName,
            createdAt: _post!.createdAt,
            upvotes: originalUpvotes,
            downvotes: originalDownvotes,
            commentCount: _post!.commentCount,
            userVote: originalVote,
            isOwner: _post!.isOwner,
          );
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final newComment = CommunityComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.postId,
      content: content,
      authorId: 'local_user',
      authorName: 'You',
      createdAt: DateTime.now(),
      upvotes: 0,
      downvotes: 0,
    );

    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> localComments =
          prefs.getStringList('local_comments_${widget.postId}') ?? [];

      final commentJson = {
        'id': newComment.id,
        'content': newComment.content,
        'created_at': newComment.createdAt.toIso8601String(),
      };

      localComments.add(jsonEncode(commentJson));
      await prefs.setStringList(
          'local_comments_${widget.postId}', localComments);

      if (mounted) {
        setState(() {
          _comments.insert(0, newComment);
          _commentController.clear();
          _isSubmitting = false;

          if (_post != null) {
            _post = CommunityPost(
              id: _post!.id,
              title: _post!.title,
              content: _post!.content,
              tags: _post!.tags,
              authorId: _post!.authorId,
              authorName: _post!.authorName,
              createdAt: _post!.createdAt,
              upvotes: _post!.upvotes,
              downvotes: _post!.downvotes,
              commentCount: _post!.commentCount + 1, // Optimistic count update
              userVote: _post!.userVote,
              isOwner: _post!.isOwner,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save comment: $e')),
        );
      }
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && _post != null) {
      final success = await _communityService.deletePost(_post!.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Post deleted')));
          Navigator.pop(context, true); // Return true to refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete post')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Post not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(
          'Discussion',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_post?.isOwner ?? false)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditPostScreen(post: _post!)),
                  ).then((res) {
                    if (res == true) _loadData();
                  });
                } else if (value == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Post Content
                Text(
                  _post!.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(_post!.authorName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Posted by ${_post!.authorName} • ${_post!.formattedDate}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _post!.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                // Tags
                Wrap(
                  spacing: 8,
                  children: _post!.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Colors.green.shade50,
                            labelStyle: TextStyle(color: Colors.green.shade800),
                          ))
                      .toList(),
                ),
                const Divider(height: 32),

                // Vote Actions Row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      color: _post!.userVote == 1 ? Colors.orange : Colors.grey,
                      onPressed: () => _handlePostVote(1),
                    ),
                    Text('${_post!.upvotes - _post!.downvotes}'),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      color:
                          _post!.userVote == -1 ? Colors.purple : Colors.grey,
                      onPressed: () => _handlePostVote(-1),
                    ),
                    const Spacer(),
                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${_post!.commentCount} comments'),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Comments List
                if (_comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child:
                        Center(child: Text('No comments yet. Be the first!')),
                  )
                else
                  ..._comments
                      .map((comment) => _CommentTile(comment: comment))
                      .toList(),
              ],
            ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: InputBorder.none,
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                IconButton(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.green),
                  onPressed: _isSubmitting ? null : _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommunityComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: const AssetImage(
                'assets/images/placeholder_user.png'), // Placeholder
            // Fallback if asset missing
            onBackgroundImageError: (_, __) {},
            backgroundColor: Colors.grey.shade200,
            child: Text(comment.authorName[0].toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.formattedDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content),
                const SizedBox(height: 4),
                // Comment actions (vote, reply - simplified for now)
                Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${comment.upvotes - comment.downvotes}',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 16),
                    // Reply button placeholder
                    Text('Reply',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
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
