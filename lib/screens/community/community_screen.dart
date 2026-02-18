import 'package:flutter/material.dart';
import '../../models/community_post.dart';
import '../../services/community_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'my_posts_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();
  final ScrollController _scrollController = ScrollController();

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  final int _limit = 20;
  String _sortBy = 'recent'; // 'recent' or 'popular'

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
      final newPosts = await _communityService.getPosts(
        skip: _page * _limit,
        limit: _limit,
        sortBy: _sortBy,
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
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load posts: $e')),
      );
    }
  }

  Future<void> _handleVote(CommunityPost post, int voteType) async {
    // Optimistic update
    final int originalVote = post.userVote;
    final int originalUpvotes = post.upvotes;
    final int originalDownvotes = post.downvotes;

    int newUpvotes = originalUpvotes;
    int newDownvotes = originalDownvotes;

    // Remove old vote
    if (originalVote == 1) newUpvotes--;
    if (originalVote == -1) newDownvotes--;

    // Add new vote
    if (voteType == 1) newUpvotes++;
    if (voteType == -1) newDownvotes++;

    // Toggle check: if clicking same vote, remove it (voteType becomes 0)
    int finalVoteType = voteType;
    if (originalVote == voteType) {
      finalVoteType = 0;
      // Revert the add we just did, essentially removing the vote
      if (voteType == 1) newUpvotes--;
      if (voteType == -1) newDownvotes--;
    }

    final int postIndex = _posts.indexWhere((p) => p.id == post.id);
    if (postIndex != -1) {
      setState(() {
        _posts[postIndex] = CommunityPost(
          id: post.id,
          title: post.title,
          content: post.content,
          tags: post.tags,
          authorId: post.authorId,
          authorName: post.authorName,
          createdAt: post.createdAt,
          upvotes: newUpvotes,
          downvotes: newDownvotes,
          commentCount: post.commentCount,
          userVote: finalVoteType,
        );
      });
    }

    final success = await _communityService.votePost(post.id, finalVoteType);
    if (!success) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _posts[postIndex] = CommunityPost(
            id: post.id,
            title: post.title,
            content: post.content,
            tags: post.tags,
            authorId: post.authorId,
            authorName: post.authorName,
            createdAt: post.createdAt,
            upvotes: originalUpvotes,
            downvotes: originalDownvotes,
            commentCount: post.commentCount,
            userVote: originalVote,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to vote')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Community Forum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPostsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (_sortBy != value) {
                setState(() {
                  _sortBy = value;
                });
                _loadPosts(refresh: true);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recent',
                child: Text('Recent'),
              ),
              const PopupMenuItem(
                value: 'popular',
                child: Text('Popular'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
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
            return CommunityPostCard(
              post: post,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(postId: post.id),
                  ),
                ).then((_) => _loadPosts(refresh: true)); // Refresh on return
              },
              onVote: (voteType) => _handleVote(post, voteType),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          ).then((result) {
            if (result == true) {
              _loadPosts(refresh: true);
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  final Function(int) onVote;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final int score = post.upvotes - post.downvotes;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      post.authorName[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    post.authorName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    post.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Content Preview
              Text(
                post.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                children: [
                  _VoteButton(
                    icon: Icons.arrow_upward,
                    isActive: post.userVote == 1,
                    onTap: () => onVote(1),
                    color: Colors.orange,
                  ),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: post.userVote == 1
                          ? Colors.orange
                          : (post.userVote == -1
                              ? Colors.purple
                              : Colors.grey[700]),
                    ),
                  ),
                  _VoteButton(
                    icon: Icons.arrow_downward,
                    isActive: post.userVote == -1,
                    onTap: () => onVote(-1),
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment_outlined,
                      size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount} Comments',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  if (post.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Text(
                        post.tags.first,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;

  const _VoteButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: isActive ? color : Colors.grey[400],
      iconSize: 20,
      onPressed: onTap,
      splashRadius: 20,
      visualDensity: VisualDensity.compact,
    );
  }
}
