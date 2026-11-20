import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/content.dart';

/// Highest content.json schemaVersion this app build understands.
const int supportedSchemaVersion = 1;

const _platforms = ['ps5', 'xbox', 'pc', 'phone'];
const _dirs = {'UP', 'DOWN', 'LEFT', 'RIGHT'};

class ContentException implements Exception {
  final String message;
  const ContentException(this.message);
  @override
  String toString() => 'ContentException: $message';
}

class UnsupportedSchemaException extends ContentException {
  final int schemaVersion;
  UnsupportedSchemaException(this.schemaVersion)
      : super('schemaVersion $schemaVersion is newer than supported $supportedSchemaVersion');
}

Never _bad(String message) => throw FormatException(message);

class ContentParser {
  /// Picks [lang], falls back to 'en'. A plain string is accepted as-is.
  static String? localize(Object? v, String lang) {
    if (v is String) return v.trim().isEmpty ? null : v;
    if (v is Map) {
      for (final k in [lang, 'en']) {
        final t = v[k];
        if (t is String && t.trim().isNotEmpty) return t;
      }
    }
    return null;
  }

  /// Parses and validates [raw]. Throws [ContentException] when the document as a
  /// whole is unusable; individual broken cheats/categories are skipped and reported
  /// through [onSkip] (default: debugPrint).
  static ContentData parse(String raw, {String lang = 'en', void Function(String)? onSkip}) {
    void skip(String m) => (onSkip ?? (s) => debugPrint('[content] $s'))(m);

    if (raw.trim().isEmpty) throw const ContentException('empty document');
    final Object? root;
    try {
      root = jsonDecode(raw);
    } on FormatException catch (e) {
      throw ContentException('invalid JSON: ${e.message}');
    }
    if (root is! Map) throw const ContentException('root is not an object');

    final schema = root['schemaVersion'];
    if (schema is! int || schema < 1) throw const ContentException('schemaVersion missing or invalid');
    if (schema > supportedSchemaVersion) throw UnsupportedSchemaException(schema);

    final version = root['contentVersion'];
    if (version is! int || version < 0) throw const ContentException('contentVersion missing or invalid');
    final updatedAt = root['updatedAt'];
    if (updatedAt is! String) throw const ContentException('updatedAt missing');
    final rawCats = root['categories'];
    final rawCheats = root['cheats'];
    if (rawCats is! List) throw const ContentException('categories missing');
    if (rawCheats is! List) throw const ContentException('cheats missing');

    final categories = <Category>[];
    for (final c in rawCats) {
      try {
        if (c is! Map) _bad('not an object');
        final id = c['id'];
        final name = localize(c['name'], lang);
        if (id is! String || id.isEmpty || name == null) _bad('id or name missing');
        if (categories.any((x) => x.id == id)) _bad('duplicate id');
        categories.add(Category(id, name));
      } catch (e) {
        skip('skipped category ($e): $c');
      }
    }

    final ids = <String>{};
    final cheats = <Cheat>[];
    for (final c in rawCheats) {
      try {
        final cheat = _parseCheat(c, lang, categories);
        if (!ids.add(cheat.id)) _bad('duplicate id ${cheat.id}');
        cheats.add(cheat);
      } catch (e) {
        skip('skipped cheat ($e): ${c is Map ? c['id'] : c}');
      }
    }
    if (cheats.isEmpty) throw const ContentException('no valid cheats');

    return ContentData(
      schemaVersion: schema,
      contentVersion: version,
      updatedAt: updatedAt,
      categories: categories,
      cheats: cheats,
      announcement: _parseAnnouncement(root['announcement'], lang, skip),
      rawJson: raw,
    );
  }

  static Cheat _parseCheat(Object? c, String lang, List<Category> categories) {
    if (c is! Map) _bad('not an object');
    final id = c['id'];
    if (id is! String || id.isEmpty) _bad('id missing');
    final name = localize(c['title'], lang);
    final effect = localize(c['effect'], lang);
    final req = localize(c['unlockRequirement'], lang);
    if (name == null || effect == null || req == null) _bad('title/effect/unlockRequirement missing');
    final categoryId = c['categoryId'];
    if (categoryId is! String || !categories.any((x) => x.id == categoryId)) _bad('unknown categoryId');
    final addedAt = DateTime.tryParse('${c['addedAt']}');
    final updatedAt = DateTime.tryParse('${c['updatedAt']}');
    if (addedAt == null || updatedAt == null) _bad('invalid addedAt/updatedAt');

    final codes = <String, CheatCode>{};
    final rawCodes = c['codes'];
    if (rawCodes is Map) {
      for (final p in _platforms) {
        final v = rawCodes[p];
        if (v is List && v.isNotEmpty && v.every((e) => e is String && _dirs.contains(e.toUpperCase()))) {
          codes[p] = CheatCode.dpad(v.map((e) => (e as String).toUpperCase()).toList());
        } else if (v is String && v.trim().isNotEmpty) {
          codes[p] = CheatCode.text(v);
        }
      }
    }

    return Cheat(
      id: id,
      name: name,
      categoryId: categoryId,
      description: localize(c['description'], lang),
      effect: effect,
      unlockRequirement: req,
      codes: codes,
      status: switch (c['status']) {
        'verified' => CheatStatus.verified,
        'rumor' => CheatStatus.rumor,
        _ => CheatStatus.unverified,
      },
      addedAt: addedAt,
      updatedAt: updatedAt,
      tags: (c['tags'] is List) ? (c['tags'] as List).whereType<String>().toList() : const [],
      isNew: c['isNew'] == true,
    );
  }

  static Announcement? _parseAnnouncement(Object? a, String lang, void Function(String) skip) {
    if (a == null) return null;
    try {
      if (a is! Map) _bad('not an object');
      final id = a['id'];
      final title = localize(a['title'], lang);
      final message = localize(a['message'], lang);
      if (id is! String || id.isEmpty || title == null || message == null) _bad('incomplete');
      return Announcement(id: id, title: title, message: message, active: a['active'] == true);
    } catch (e) {
      skip('ignored announcement ($e)');
      return null;
    }
  }
}
