import 'digest_item.dart';

class Manifest {
  Manifest({
    required this.version,
    required this.generatedAt,
    required this.source,
    required this.releaseTag,
    required this.items,
  });

  final String version;
  final DateTime generatedAt;
  final String source;
  final String releaseTag;
  final List<DigestItem> items;

  factory Manifest.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    return Manifest(
      version: (json['version'] ?? '').toString(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      source: (json['source'] ?? '').toString(),
      releaseTag: (json['release_tag'] ?? '').toString(),
      items: rawItems.map(DigestItem.fromJson).toList(growable: false),
    );
  }
}
