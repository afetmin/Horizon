import 'package:flutter/material.dart';

import '../models/digest_item.dart';
import '../services/favorites_repository.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.favoritesRepository,
    required this.onOpenDigest,
  });

  final FavoritesRepository favoritesRepository;
  final Future<void> Function(DigestItem item) onOpenDigest;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final items = widget.favoritesRepository.items;
    if (items.isEmpty) {
      return const Center(child: Text('No favorites yet.'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _FavoriteTile(
        item: items[index],
        favoritesRepository: widget.favoritesRepository,
        onOpenDigest: widget.onOpenDigest,
        onChanged: _refresh,
      ),
    );
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.item,
    required this.favoritesRepository,
    required this.onOpenDigest,
    required this.onChanged,
  });

  final DigestItem item;
  final FavoritesRepository favoritesRepository;
  final Future<void> Function(DigestItem item) onOpenDigest;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.title),
      subtitle: Text('${item.date} · ${item.lang.toUpperCase()}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await favoritesRepository.remove(item.id);
          onChanged();
        },
      ),
      onTap: () async {
        await onOpenDigest(item);
        onChanged();
      },
    );
  }
}
