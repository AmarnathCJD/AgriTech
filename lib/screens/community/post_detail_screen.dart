import 'package:flutter/material.dart';
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

      setState(() {
        _post = post;
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
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
          );
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    final newComment =
        await _communityService.createComment(widget.postId, content);

    setState(() => _isSubmitting = false);

    if (newComment != null) {
      _commentController.clear();
      setState(() {
        _comments.add(newComment);
        // Update comment count locally
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
          commentCount: _post!.commentCount + 1,
          userVote: _post!.userVote,
        );
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment')),
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
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: [
          if (_post?.isOwner ?? false)
            PopupMenuButton<String>(
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
