import 'package:flutter/material.dart';

import '../models/digest_item.dart';
import '../services/favorites_repository.dart';
import '../services/manifest_service.dart';
import 'digest_detail_screen.dart';

class DigestListScreen extends StatefulWidget {
  const DigestListScreen({
    super.key,
    required this.language,
    required this.manifestService,
    required this.favoritesRepository,
  });

  final String language;
  final ManifestService manifestService;
  final FavoritesRepository favoritesRepository;

  @override
  State<DigestListScreen> createState() => _DigestListScreenState();
}

class _DigestListScreenState extends State<DigestListScreen> {
  late Future<List<DigestItem>> _futureItems;

  @override
  void initState() {
    super.initState();
    _futureItems = _loadItems();
  }

  @override
  void didUpdateWidget(covariant DigestListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language ||
        oldWidget.manifestService != widget.manifestService) {
      _futureItems = _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshItems,
      child: FutureBuilder<List<DigestItem>>(
        future: _futureItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: 'Failed to load digests: ${snapshot.error}',
              onRetry: _reloadItems,
            );
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No digest items in this language yet.')),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _DigestListTile(
              item: items[index],
              manifestService: widget.manifestService,
              favoritesRepository: widget.favoritesRepository,
              onReturn: _refreshState,
            ),
          );
        },
      ),
    );
  }

  Future<List<DigestItem>> _loadItems() async {
    final items = await widget.manifestService.fetchItems();
    return items.where((item) => item.lang == widget.language).toList();
  }

  Future<void> _refreshItems() async {
    _reloadItems();
    await _futureItems;
  }

  void _reloadItems() {
    setState(() {
      _futureItems = _loadItems();
    });
  }

  void _refreshState() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _DigestListTile extends StatelessWidget {
  const _DigestListTile({
    required this.item,
    required this.manifestService,
    required this.favoritesRepository,
    required this.onReturn,
  });

  final DigestItem item;
  final ManifestService manifestService;
  final FavoritesRepository favoritesRepository;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final isFavorite = favoritesRepository.contains(item.id);
    return ListTile(
      title: Text(item.title),
      subtitle: Text('${item.date} · ${item.lang.toUpperCase()}'),
      trailing: Icon(
        isFavorite ? Icons.bookmark : Icons.bookmark_outline,
      ),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DigestDetailScreen(
              item: item,
              manifestService: manifestService,
              favoritesRepository: favoritesRepository,
            ),
          ),
        );
        onReturn();
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
