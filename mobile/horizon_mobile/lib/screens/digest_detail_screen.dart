import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/digest_item.dart';
import '../services/favorites_repository.dart';
import '../services/manifest_service.dart';

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

  @override
  void initState() {
    super.initState();
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

          return Markdown(
            data: snapshot.data ?? '',
            selectable: true,
            padding: const EdgeInsets.all(16),
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
}
