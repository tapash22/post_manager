import 'package:dio/dio.dart';

import 'post.dart';

class PostApi{
  final Dio _dio;

  PostApi(this._dio);

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List<dynamic>>('/posts');

    final data = response.data;

    if (data == null) {
      throw const FormatException('Posts response is empty.');
    }

    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid post data.');
      }

      return Post.fromJson(item);
    }).toList();
  }

  Future<Post> fetchPost(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/posts/$id');
    final data = response.data;

    if (data == null) {
      throw const FormatException('Post response is empty.');
    }

    return Post.fromJson(data);
  }

  Future<Post> createPost({
    required String title,
    required String body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/posts',
      data: {
        'userId': 1,
        'title': title,
        'body': body,
      },
    );
    final data = response.data;

    if (data == null) {
      throw const FormatException('Created post response is empty.');
    }

    return Post.fromJson(data);
  }

  Future<Post> updatePost(Post post) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/posts/${post.id}',
      data: post.toJson(),
    );
    final data = response.data;

    if (data == null) {
      throw const FormatException('Updated post response is empty.');
    }

    return Post.fromJson(data);
  }

  Future<void> deletePost(int id) async {
    await _dio.delete<void>('/posts/$id');
  }
}