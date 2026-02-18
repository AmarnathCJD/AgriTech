import 'package:flutter/material.dart';
import '../../models/community_post.dart';
import '../../services/community_service.dart';
import 'post_detail_screen.dart';
import 'edit_post_screen.dart';
import 'community_screen.dart'; // For CommunityPostCard

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final CommunityService _communityService = CommunityService();
  final ScrollController _scrollController = ScrollController();

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _posts = [];
        _page = 0;
        _hasMore = true;
      }
    });

    try {
      final newPosts = await _communityService.getMyPosts(
        skip: _page * _limit,
        limit: _limit,
      );

      setState(() {
        if (newPosts.length < _limit) {
          _hasMore = false;
        }
        _posts.addAll(newPosts);
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: $e')),
        );
      }
    }
  }

  Future<void> _deletePost(CommunityPost post) async {
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

    if (confirmed == true && mounted) {
      final success = await _communityService.deletePost(post.id);
      if (mounted) {
        if (success) {
          setState(() {
            _posts.removeWhere((p) => p.id == post.id);
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Post deleted')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete post')));
        }
      }
    }
  }

  void _showOptions(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditPostScreen(post: post)),
                ).then((res) {
                  if (res == true) _loadPosts(refresh: true);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Post',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deletePost(post);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Discussions')),
      body: RefreshIndicator(
        onRefresh: () => _loadPosts(refresh: true),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _posts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _posts.length) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ));
            }

            final post = _posts[index];
            return Stack(
              children: [
                CommunityPostCard(
                  post: post,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(postId: post.id),
                      ),
                    ).then((_) => _loadPosts(refresh: true));
                  },
                  onVote:
                      (voteType) {}, // No voting from here or implement same logic
                ),
                Positioned(
                  top: 8,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptions(post),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
