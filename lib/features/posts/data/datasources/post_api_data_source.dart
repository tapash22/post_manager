import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/post.dart';

class PostApiDataSource {
  PostApiDataSource({http.Client? client}) : _client = client ?? http.Client();

  static final _postsUri = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  final http.Client _client;

  Future<List<Post>> getPosts() async {
    final response = await _client.get(_postsUri);
    if (response.statusCode != 200) {
      throw PostApiException('Failed to load posts (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const PostApiException('The posts response has an invalid format.');
    }

    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const PostApiException('A post in the response has an invalid format.');
      }
      return Post(
        userId: item['userId'] as int,
        id: item['id'] as int,
        title: item['title'] as String,
        body: item['body'] as String,
      );
    }).toList();
  }

  Future<Post> createPost({required String title, required String body}) async {
    final response = await _client.post(
      _postsUri,
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
    );
    if (response.statusCode != 201) {
      throw PostApiException('Failed to create post (${response.statusCode}).');
    }
    return _toPost(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Post> updatePost(Post post) async {
    final response = await _client.put(
      _postsUri.replace(path: '${_postsUri.path}/${post.id}'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'id': post.id,
        'userId': post.userId,
        'title': post.title,
        'body': post.body,
      }),
    );
    if (response.statusCode != 200) {
      throw PostApiException('Failed to update post (${response.statusCode}).');
    }
    return _toPost(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deletePost(int id) async {
    final response = await _client.delete(
      _postsUri.replace(path: '${_postsUri.path}/$id'),
    );
    if (response.statusCode != 200) {
      throw PostApiException('Failed to delete post (${response.statusCode}).');
    }
  }

  Post _toPost(Map<String, dynamic> item) => Post(
    userId: item['userId'] as int,
    id: item['id'] as int,
    title: item['title'] as String,
    body: item['body'] as String,
  );

  void close() => _client.close();
}

class PostApiException implements Exception {
  const PostApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
