import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horizon_mobile/models/digest_item.dart';
import 'package:horizon_mobile/services/manifest_service.dart';
import 'package:http/testing.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final text = _assets[key];
    if (text == null) {
      throw Exception('Missing test asset: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(text));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _assets[key];
    if (value == null) {
      throw Exception('Missing test asset: $key');
    }
    return value;
  }
}

void main() {
  test('falls back to asset manifest when remote manifest request fails', () async {
    final service = ManifestService(
      manifestUrl: 'https://example.com/api/manifest.json',
      httpClient: MockClient((_) async => throw const SocketException('offline')),
      assetBundle: _FakeAssetBundle({
        'assets/fallback/manifest.json': '''
{
  "version": "1",
  "generated_at": "2026-03-01T00:00:00Z",
  "base_url": "local",
  "items": [
    {
      "id": "2026-03-01-zh",
      "date": "2026-03-01",
      "lang": "zh",
      "title": "Fallback ZH",
      "path": "/_posts/2026-03-01-summary-zh.md",
      "url": "https://example.com/_posts/2026-03-01-summary-zh.md"
    }
  ]
}
''',
      }),
    );

    final items = await service.fetchItems();

    expect(items, hasLength(1));
    expect(items.first.id, '2026-03-01-zh');
    expect(items.first.lang, 'zh');
  });

  test('falls back to asset markdown when remote digest request fails', () async {
    final service = ManifestService(
      manifestUrl: 'https://example.com/api/manifest.json',
      httpClient: MockClient((_) async => throw const SocketException('offline')),
      assetBundle: _FakeAssetBundle({
        'assets/fallback/_posts/2026-03-01-summary-zh.md': '''
---
layout: default
title: "Horizon Summary: 2026-03-01 (ZH)"
date: 2026-03-01
lang: zh
---

<a id="item-1"></a>
# Local digest
''',
      }),
    );

    final markdown = await service.fetchMarkdown(
      DigestItem(
        id: '2026-03-01-zh',
        date: '2026-03-01',
        lang: 'zh',
        title: 'Fallback ZH',
        path: '/_posts/2026-03-01-summary-zh.md',
        url: 'https://example.com/_posts/2026-03-01-summary-zh.md',
      ),
    );

    expect(markdown.trim(), '# Local digest');
  });
}
