import 'digest_item.dart';

class Manifest {
  Manifest({
    required this.version,
    required this.generatedAt,
    required this.baseUrl,
    required this.items,
  });

  final String version;
  final DateTime generatedAt;
  final String baseUrl;
  final List<DigestItem> items;

  factory Manifest.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    return Manifest(
      version: (json['version'] ?? '').toString(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      baseUrl: (json['base_url'] ?? '').toString(),
      items: rawItems.map(DigestItem.fromJson).toList(growable: false),
    );
  }
}
