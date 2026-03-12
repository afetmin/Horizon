import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:webview_flutter/webview_flutter.dart';

import '../models/digest_item.dart';
import '../services/favorites_repository.dart';
import '../services/manifest_service.dart';
import 'in_app_webview_screen.dart';

class DigestDetailScreen extends StatefulWidget {
  const DigestDetailScreen({
    super.key,
    required this.item,
    required this.manifestService,
    required this.favoritesRepository,
  });

  final DigestItem item;
  final ManifestService manifestService;
  final FavoritesRepository favoritesRepository;

  @override
  State<DigestDetailScreen> createState() => _DigestDetailScreenState();
}

class _DigestDetailScreenState extends State<DigestDetailScreen> {
  late Future<String> _markdownFuture;
  late final WebViewController _webViewController;
  String? _loadedMarkdown;
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final requestedUri = Uri.tryParse(request.url);
            if (requestedUri == null) {
              return NavigationDecision.navigate;
            }

            if (_isInPageNavigation(requestedUri)) {
              return NavigationDecision.navigate;
            }

            if (_isExternalHttpLink(requestedUri)) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InAppWebViewScreen(
                    initialUrl: request.url,
                    title: requestedUri.host,
                  ),
                ),
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isPageLoading = true;
            });
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isPageLoading = false;
            });
          },
        ),
      );
    _markdownFuture = _loadMarkdown();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.favoritesRepository.contains(widget.item.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.date),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: () async {
              if (isFavorite) {
                await widget.favoritesRepository.remove(widget.item.id);
              } else {
                final markdown = await _markdownFuture;
                await widget.favoritesRepository
                    .addOrUpdate(widget.item.copyWith(markdown: markdown));
              }
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _markdownFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load digest: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _markdownFuture = _loadMarkdown();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final markdown = snapshot.data ?? '';
          if (_loadedMarkdown != markdown) {
            _loadedMarkdown = markdown;
            final html = _buildHtmlDocument(markdown);
            _webViewController.loadHtmlString(html, baseUrl: widget.item.url);
          }

          return Stack(
            children: [
              WebViewWidget(controller: _webViewController),
              if (_isPageLoading) const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }

  Future<String> _loadMarkdown() async {
    await widget.favoritesRepository.load();
    final cached = widget.favoritesRepository.items
        .where((item) => item.id == widget.item.id)
        .map((item) => item.markdown)
        .whereType<String>()
        .toList();
    if (cached.isNotEmpty && cached.first.isNotEmpty) {
      return cached.first;
    }

    return widget.manifestService.fetchMarkdown(widget.item);
  }

  bool _isInPageNavigation(Uri uri) {
    if (uri.fragment.isEmpty) {
      return false;
    }

    final sourceUri = Uri.tryParse(widget.item.url);
    if (sourceUri == null) {
      return true;
    }

    return uri.scheme == sourceUri.scheme &&
        uri.host == sourceUri.host &&
        uri.path == sourceUri.path;
  }

  bool _isExternalHttpLink(Uri uri) {
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return false;
    }

    final sourceUri = Uri.tryParse(widget.item.url);
    if (sourceUri == null) {
      return true;
    }

    return uri.host != sourceUri.host || uri.path != sourceUri.path;
  }

  String _buildHtmlDocument(String markdown) {
    final body = md.markdownToHtml(
      markdown,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    final title = _escapeHtml(widget.item.date);

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <title>$title</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f5f1e8;
      --paper: #fffdf8;
      --ink: #1f1a17;
      --muted: #6c6258;
      --line: #ddd1c3;
      --accent: #9a3412;
      --quote: #f3e7d8;
      --code: #f2ede6;
    }
    * { box-sizing: border-box; }
    html {
      scroll-behavior: smooth;
    }
    body {
      margin: 0;
      background: linear-gradient(180deg, #efe7da 0%, var(--bg) 100%);
      color: var(--ink);
      font-family: Georgia, "Times New Roman", serif;
      line-height: 1.72;
      padding: 24px 16px 40px;
    }
    main {
      max-width: 860px;
      margin: 0 auto;
      background: var(--paper);
      border: 1px solid var(--line);
      border-radius: 24px;
      padding: 24px 18px 32px;
      box-shadow: 0 18px 50px rgba(64, 45, 24, 0.08);
    }
    h1, h2, h3, h4 {
      line-height: 1.2;
      color: #18120f;
    }
    h1 { font-size: 2rem; margin: 0 0 1rem; }
    h2 {
      margin-top: 2.4rem;
      font-size: 1.45rem;
      padding-top: 1rem;
      border-top: 1px solid var(--line);
    }
    p, li { font-size: 1rem; }
    a {
      color: var(--accent);
      text-decoration-thickness: 1.5px;
      text-underline-offset: 2px;
    }
    blockquote {
      margin: 1rem 0;
      padding: 0.9rem 1rem;
      background: var(--quote);
      border-left: 4px solid #d97706;
      color: #4c3b2b;
      border-radius: 10px;
    }
    code {
      background: var(--code);
      border-radius: 6px;
      padding: 0.12rem 0.35rem;
      font-size: 0.92em;
    }
    pre {
      background: #201815;
      color: #f8eee7;
      overflow-x: auto;
      padding: 1rem;
      border-radius: 14px;
    }
    pre code {
      background: transparent;
      padding: 0;
      color: inherit;
    }
    hr {
      border: 0;
      border-top: 1px solid var(--line);
      margin: 1.6rem 0;
    }
    ul, ol {
      padding-left: 1.4rem;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      display: block;
      overflow-x: auto;
    }
    th, td {
      border: 1px solid var(--line);
      padding: 0.6rem 0.7rem;
      text-align: left;
    }
    details {
      margin: 1rem 0;
      padding: 0.85rem 1rem;
      background: #faf3ea;
      border: 1px solid var(--line);
      border-radius: 14px;
    }
    summary {
      cursor: pointer;
      font-weight: 700;
    }
  </style>
</head>
<body>
  <main>
    $body
  </main>
</body>
</html>
''';
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
