import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/community_post.dart';
import 'auth_service.dart';
import 'dart:developer';

class CommunityService {
  String get baseUrl => dotenv.env['BACKEND_URL']!;

  Future<Map<String, String>> _getHeaders() async {
    final mobileNumber = AuthService().currentMobileNumber;
    return {
      'Content-Type': 'application/json',
      if (mobileNumber != null) 'X-User-Phone': mobileNumber,
    };
  }

  Future<List<CommunityPost>> getPosts({
    int skip = 0,
    int limit = 20,
    String sortBy = 'recent',
  }) async {
    final url = Uri.parse(
        '$baseUrl/community/posts?skip=$skip&limit=$limit&sort_by=$sortBy');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => CommunityPost.fromJson(e)).toList();
      } else {
        log('Failed to load posts: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      log('Error fetching posts: $e');
      return [];
    }
  } // This closing brace was missing for getPosts

  Future<List<CommunityPost>> getMyPosts({
    int skip = 0,
    int limit = 20,
  }) async {
    final url =
        Uri.parse('$baseUrl/community/my-posts?skip=$skip&limit=$limit');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => CommunityPost.fromJson(e)).toList();
      } else {
        log('Failed to load my posts: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      log('Error fetching my posts: $e');
      return [];
    }
  }

  Future<CommunityPost?> updatePost(
      String postId, String title, String content, List<String> tags) async {
    final url = Uri.parse('$baseUrl/community/posts/$postId');
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'title': title,
        'content': content,
        'tags': tags,
      });

      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return CommunityPost.fromJson(json.decode(response.body));
      } else {
        log('Failed to update post: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error updating post: $e');
      return null;
    }
  }

  Future<bool> deletePost(String postId) async {
    final url = Uri.parse('$baseUrl/community/posts/$postId');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        return true;
      } else {
        log('Failed to delete post: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      log('Error deleting post: $e');
      return false;
    }
  }

  Future<CommunityPost?> createPost(
      String title, String content, List<String> tags) async {
    final url = Uri.parse('$baseUrl/community/posts');
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'title': title,
        'content': content,
        'tags': tags,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return CommunityPost.fromJson(json.decode(response.body));
      } else {
        log('Failed to create post: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error creating post: $e');
      return null;
    }
  }

  Future<CommunityPost?> getPost(String postId) async {
    final url = Uri.parse('$baseUrl/community/posts/$postId');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return CommunityPost.fromJson(json.decode(response.body));
      } else {
        log('Failed to load post: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error fetching post: $e');
      return null;
    }
  }

  Future<List<CommunityComment>> getComments(String postId,
      {int skip = 0, int limit = 50}) async {
    final url = Uri.parse(
        '$baseUrl/community/posts/$postId/comments?skip=$skip&limit=$limit');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => CommunityComment.fromJson(e)).toList();
      } else {
        log('Failed to load comments: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error fetching comments: $e');
      return [];
    }
  }

  Future<CommunityComment?> createComment(String postId, String content) async {
    final url = Uri.parse('$baseUrl/community/posts/$postId/comments');
    try {
      final headers = await _getHeaders();
      final body = json.encode({'content': content});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return CommunityComment.fromJson(json.decode(response.body));
      } else {
        log('Failed to create comment: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error creating comment: $e');
      return null;
    }
  }

  Future<bool> votePost(String postId, int voteType) async {
    final url = Uri.parse('$baseUrl/community/posts/$postId/vote');
    log('Voting on post: $postId with url: $url');
    try {
      final headers = await _getHeaders();
      final body = json.encode({'vote_type': voteType});

      final response = await http.post(url, headers: headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      log('Error voting post: $e');
      return false;
    }
  }

  Future<bool> voteComment(String commentId, int voteType) async {
    final url = Uri.parse('$baseUrl/community/comments/$commentId/vote');
    try {
      final headers = await _getHeaders();
      final body = json.encode({'vote_type': voteType});

      final response = await http.post(url, headers: headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      log('Error voting comment: $e');
      return false;
    }
  }
}
