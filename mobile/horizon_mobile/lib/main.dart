import 'package:flutter/material.dart';

import 'models/digest_item.dart';
import 'screens/digest_list_screen.dart';
import 'services/favorites_repository.dart';
import 'services/manifest_settings_repository.dart';
import 'services/manifest_service.dart';
import 'screens/digest_detail_screen.dart';
import 'screens/favorites_screen.dart';
import 'widgets/manifest_url_dialog.dart';

const defaultManifestUrl = String.fromEnvironment(
  'MANIFEST_URL',
  defaultValue: 'https://github.com/afetmin/Horizon/releases/download/mobile-feed/manifest.json',
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
  final ManifestSettingsRepository _manifestSettingsRepository =
      ManifestSettingsRepository();
  late ManifestService _manifestService = ManifestService(
    manifestUrl: _manifestUrl,
  );

  int _tabIndex = 0;
  String _language = 'zh';
  String _manifestUrl = defaultManifestUrl;
  int _manifestVersion = 0;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabIndex == 0 ? 'Horizon Digest' : 'Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _editManifestUrl,
            tooltip: 'Set manifest URL',
          ),
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
            key: ValueKey('digest-$_manifestVersion-$_language'),
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

  Future<void> _initializeState() async {
    final savedManifestUrl = await _manifestSettingsRepository.load();
    await _favoritesRepository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      if (savedManifestUrl != null) {
        _manifestUrl = savedManifestUrl;
        _manifestService = ManifestService(manifestUrl: _manifestUrl);
      }
    });
  }

  Future<void> _editManifestUrl() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ManifestUrlDialog(initialValue: _manifestUrl),
    );
    if (result == null || result == _manifestUrl) {
      return;
    }

    await _manifestSettingsRepository.save(result);
    if (!mounted) {
      return;
    }
    setState(() {
      _manifestUrl = result;
      _manifestService = ManifestService(manifestUrl: _manifestUrl);
      _manifestVersion += 1;
    });
  }
}
