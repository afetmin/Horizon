import 'package:flutter/material.dart';

import 'models/digest_item.dart';
import 'services/favorites_repository.dart';
import 'services/manifest_service.dart';
import 'screens/digest_detail_screen.dart';

const defaultManifestUrl = String.fromEnvironment(
  'MANIFEST_URL',
  defaultValue: 'https://afetmin.github.io/Horizon/api/manifest.json',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HorizonMobileApp());
}

class HorizonMobileApp extends StatelessWidget {
  const HorizonMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horizon Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  late final ManifestService _manifestService = ManifestService(
    manifestUrl: defaultManifestUrl,
  );

  int _tabIndex = 0;
  String _language = 'zh';

  @override
  void initState() {
    super.initState();
    _favoritesRepository.load().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabIndex == 0 ? 'Horizon Digest' : 'Favorites'),
        actions: [
          if (_tabIndex == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _language,
                  items: const [
                    DropdownMenuItem(value: 'zh', child: Text('中文')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _language = value;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          DigestListScreen(
            language: _language,
            manifestService: _manifestService,
            favoritesRepository: _favoritesRepository,
          ),
          FavoritesScreen(
            favoritesRepository: _favoritesRepository,
            onOpenDigest: _openDigest,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (value) {
          setState(() {
            _tabIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Digest'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), label: 'Favorites'),
        ],
      ),
    );
  }

  Future<void> _openDigest(DigestItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DigestDetailScreen(
          item: item,
          manifestService: _manifestService,
          favoritesRepository: _favoritesRepository,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }
}

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
    if (oldWidget.language != widget.language) {
      _futureItems = _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _futureItems = _loadItems();
        });
        await _futureItems;
      },
      child: FutureBuilder<List<DigestItem>>(
        future: _futureItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load digests: ${snapshot.error}'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _futureItems = _loadItems();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
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
            itemBuilder: (context, index) {
              final item = items[index];
              final isFavorite = widget.favoritesRepository.contains(item.id);
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
                        manifestService: widget.manifestService,
                        favoritesRepository: widget.favoritesRepository,
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(() {});
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<DigestItem>> _loadItems() async {
    final items = await widget.manifestService.fetchItems();
    return items.where((item) => item.lang == widget.language).toList();
  }
}

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
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.title),
          subtitle: Text('${item.date} · ${item.lang.toUpperCase()}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await widget.favoritesRepository.remove(item.id);
              if (mounted) {
                setState(() {});
              }
            },
          ),
          onTap: () async {
            await widget.onOpenDigest(item);
            if (mounted) {
              setState(() {});
            }
          },
        );
      },
    );
  }
}
