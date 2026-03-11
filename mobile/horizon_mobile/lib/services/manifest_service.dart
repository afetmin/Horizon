import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/digest_item.dart';
import '../models/manifest.dart';

class ManifestService {
  ManifestService({
    required this.manifestUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String manifestUrl;
  final http.Client _httpClient;

  Future<List<DigestItem>> fetchItems() async {
    final response = await _httpClient.get(Uri.parse(manifestUrl));
    if (response.statusCode != 200) {
      throw HttpException('Manifest request failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final manifest = Manifest.fromJson(data);
    return manifest.items;
  }

  Future<String> fetchMarkdown(DigestItem item) async {
    final response = await _httpClient.get(Uri.parse(item.url));
    if (response.statusCode != 200) {
      throw HttpException('Digest request failed (${response.statusCode})');
    }

    return _sanitizeMarkdown(response.body);
  }

  String _sanitizeMarkdown(String raw) {
    var content = raw;

    // Remove top YAML front matter block, which is not user-facing content.
    final frontMatterPattern = RegExp(r'^\s*---\s*\n[\s\S]*?\n---\s*\n?', multiLine: false);
    content = content.replaceFirst(frontMatterPattern, '');

    // Remove empty HTML anchor tags used for web in-page navigation.
    final anchorPattern = RegExp(r'<a\s+id="[^"]+"\s*>\s*<\/a>\s*\n?', caseSensitive: false);
    content = content.replaceAll(anchorPattern, '');

    return content.trimLeft();
  }
}
