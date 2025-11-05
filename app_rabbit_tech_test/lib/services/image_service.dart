import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageService {
  static const String _apiKey = 'owyYTtIlN8NJ9pHGL9W2O4g3DKoNLaJ7YJNpmwythFbwvmUF2Vx3avn5';

  static const String _baseURL = 'https://api.pexels.com/v1';

  Future<List<ImageModel>> searchImages (String query, int page) async {
    final url = Uri.parse('$_baseURL/search?query=$query&page=$page&per_page=20'
    );

    try {
      final response = await http.get(url,
                        headers: {
                          'Authorization': _apiKey,
                        });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['photos'] as List;

        return results.map((json) => ImageModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load images');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

class ImageModel {
  final String id;
  final String smallUrl;
  final String regularUrl;
  final String description;

  ImageModel({
    required this.id,
    required this.smallUrl,
    required this.regularUrl,
    required this.description,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'].toString(), 
    smallUrl: json['src']['small'], 
    regularUrl: json['src']['large'],
    description: json['alt'] ?? 'No description',
    );
  }
}