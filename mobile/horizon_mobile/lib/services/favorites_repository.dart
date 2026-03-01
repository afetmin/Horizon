import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/digest_item.dart';

class FavoritesRepository {
  static const _favoritesKey = 'favorite_items_v1';

  bool _loaded = false;
  final List<DigestItem> _items = [];

  List<DigestItem> get items => List.unmodifiable(_items);

  bool contains(String id) => _items.any((item) => item.id == id);

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) {
      _loaded = true;
      return;
    }

    final parsed = jsonDecode(raw) as List<dynamic>;
    _items
      ..clear()
      ..addAll(parsed.cast<Map<String, dynamic>>().map(DigestItem.fromJson));
    _loaded = true;
  }

  Future<void> addOrUpdate(DigestItem item) async {
    await load();
    _items.removeWhere((existing) => existing.id == item.id);
    _items.insert(0, item);
    await _save();
  }

  Future<void> remove(String id) async {
    await load();
    _items.removeWhere((item) => item.id == id);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_favoritesKey, raw);
  }
}
