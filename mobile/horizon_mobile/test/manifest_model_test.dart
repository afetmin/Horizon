import 'package:flutter_test/flutter_test.dart';
import 'package:horizon_mobile/models/manifest.dart';

void main() {
  test('parses manifest items', () {
    final manifest = Manifest.fromJson({
      'version': '1',
      'generated_at': '2026-03-01T09:23:00Z',
      'base_url': 'https://example.com',
      'items': [
        {
          'id': '2026-03-01-zh',
          'date': '2026-03-01',
          'lang': 'zh',
          'title': 'Horizon Summary: 2026-03-01 (ZH)',
          'path': '/_posts/2026-03-01-summary-zh.md',
          'url': 'https://example.com/_posts/2026-03-01-summary-zh.md',
        }
      ]
    });

    expect(manifest.version, '1');
    expect(manifest.items.length, 1);
    expect(manifest.items.first.id, '2026-03-01-zh');
    expect(manifest.items.first.lang, 'zh');
  });
}
