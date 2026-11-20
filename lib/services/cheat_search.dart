import '../models/content.dart';

/// Concept groups (NL + EN). A query word that belongs to a group also matches every
/// other word of that group, so "politie", "cops" and "wanted" find the same cheats.
const List<List<String>> synonymGroups = [
  ['wanted', 'heat', 'police', 'cops', 'cop', 'politie', 'agent', 'agenten', 'sterren', 'opsporing', 'gezocht'],
  ['money', 'cash', 'dollar', 'dollars', 'geld', 'bank', 'rijk', 'rich'],
  ['vehicle', 'vehicles', 'car', 'cars', 'auto', 'autos', 'voertuig', 'voertuigen', 'spawn', 'rijden', 'drive'],
  ['weapon', 'weapons', 'gun', 'guns', 'wapen', 'wapens', 'geweer', 'shotgun', 'rocket', 'raket'],
  ['ammo', 'ammunition', 'munitie', 'kogels', 'bullets', 'reload', 'herladen', 'schieten', 'shooting'],
  ['explosive', 'explosives', 'explosief', 'explosieve', 'explosion', 'explosie', 'exploding', 'explodeert', 'bom', 'bomb', 'granaat', 'grenade'],
  ['weather', 'weer', 'rain', 'regen', 'storm', 'sun', 'zon'],
  ['time', 'tijd', 'clock', 'klok', 'day', 'dag', 'night', 'nacht'],
  ['armor', 'armour', 'vest', 'pantser', 'health', 'gezondheid', 'leven', 'life'],
  ['filter', 'filters', 'screen', 'scherm', 'camera', 'beeld', 'effect'],
  ['boat', 'boot', 'airboat', 'ship', 'schip', 'water'],
  ['bike', 'bmx', 'fiets', 'motor', 'motorcycle', 'scooter'],
  ['plane', 'vliegtuig', 'jet', 'helicopter', 'heli', 'fly', 'vliegen'],
  ['fall', 'vallen', 'parachute', 'skydive', 'jump', 'springen'],
  ['drunk', 'dronken', 'alcohol'],
  ['nitro', 'nitrous', 'boost', 'turbo', 'fuel', 'benzine', 'tank'],
  ['fire', 'vuur', 'brand', 'incendiary', 'burn', 'branden'],
  ['repair', 'repareren', 'fix', 'kapot', 'broken'],
  ['focus', 'concentratie'],
];

/// Lower-cases and folds diacritics one-to-one, so character offsets stay valid
/// for highlighting. Anything that is not a letter or digit becomes a space.
String fold(String s) {
  const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final i = from.indexOf(ch);
    if (i >= 0) {
      b.write(to[i]);
    } else if ((r >= 0x61 && r <= 0x7a) || (r >= 0x30 && r <= 0x39)) {
      b.write(ch);
    } else {
      b.write(' ');
    }
  }
  return b.toString();
}

List<String> _words(String folded) => folded.split(' ').where((w) => w.isNotEmpty).toList();

/// Levenshtein distance with an early exit once it exceeds [max].
int _distance(String a, String b, int max) {
  if ((a.length - b.length).abs() > max) return max + 1;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    var rowMin = cur[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final v = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
      cur[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > max) return max + 1;
    prev = cur;
  }
  return prev[b.length];
}

int _typoBudget(int length) => length >= 7 ? 2 : (length >= 4 ? 1 : 0);

class _Doc {
  final Cheat cheat;
  final String title;
  final List<String> titleWords;
  final String extra; // aliases + tags
  final List<String> extraWords;
  final String body; // effect + description + unlock requirement
  final List<String> bodyWords;

  _Doc(this.cheat)
      : title = fold(cheat.name),
        titleWords = _words(fold(cheat.name)),
        extra = fold([...cheat.aliases, ...cheat.tags].join(' ')),
        extraWords = _words(fold([...cheat.aliases, ...cheat.tags].join(' '))),
        body = fold('${cheat.effect} ${cheat.description ?? ''} ${cheat.unlockRequirement}'),
        bodyWords = _words(fold('${cheat.effect} ${cheat.description ?? ''} ${cheat.unlockRequirement}'));
}

class SearchHit {
  final Cheat cheat;
  final double score;
  const SearchHit(this.cheat, this.score);
}

/// Instant, forgiving search: every query word has to match (AND). A word matches by
/// prefix, substring, synonym or a small typo. Results are ranked: title > aliases/tags > text.
class CheatSearch {
  final List<_Doc> _docs;
  CheatSearch(Iterable<Cheat> cheats) : _docs = cheats.map(_Doc.new).toList();

  /// Query words (folded). Words shorter than 2 characters are ignored.
  static List<String> tokens(String query) => _words(fold(query)).where((w) => w.length >= 2 || RegExp(r'\d').hasMatch(w)).toList();

  /// All terms (the word itself + synonyms) that [token] stands for.
  static Set<String> expand(String token) {
    final out = <String>{token};
    if (token.length < 3) return out;
    for (final g in synonymGroups) {
      final hit = g.any((w) => w == token || (token.length >= 3 && w.startsWith(token)) || (token.length >= 4 && _distance(w, token, 1) <= 1));
      if (hit) out.addAll(g);
    }
    return out;
  }

  /// Ranked matches among [candidates] (in their given order for equal scores).
  /// With an empty query every candidate is returned unchanged.
  List<Cheat> rank(String query, Iterable<Cheat> candidates) {
    final toks = tokens(query);
    final list = candidates.toList();
    if (toks.isEmpty) return list;
    final byId = {for (final d in _docs) d.cheat.id: d};
    final hits = <SearchHit>[];
    for (var i = 0; i < list.length; i++) {
      final d = byId[list[i].id];
      if (d == null) continue;
      var total = 0.0;
      var ok = true;
      for (final t in toks) {
        final s = _tokenScore(t, d);
        if (s <= 0) {
          ok = false;
          break;
        }
        total += s;
      }
      // Tiny tie-breaker keeps the original order for equal scores.
      if (ok) hits.add(SearchHit(list[i], total - i * 1e-6));
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.map((h) => h.cheat).toList();
  }

  double _tokenScore(String token, _Doc d) {
    var best = _score(token, d, 1.0, fuzzy: true);
    if (best >= 100) return best;
    for (final t in expand(token)) {
      if (t == token) continue;
      // Synonyms match exactly (word start / contains) only: typos apply to what the user typed.
      final s = _score(t, d, 0.8, fuzzy: false);
      if (s > best) best = s;
    }
    return best;
  }

  double _score(String t, _Doc d, double factor, {required bool fuzzy}) {
    double s = 0;
    bool prefix(List<String> ws) => ws.any((w) => w.startsWith(t));
    if (prefix(d.titleWords)) {
      s = 100;
    } else if (t.length >= 3 && d.title.contains(t)) {
      s = 80;
    } else if (prefix(d.extraWords)) {
      s = 70;
    } else if (t.length >= 3 && d.extra.contains(t)) {
      s = 60;
    } else if (prefix(d.bodyWords)) {
      s = 40;
    } else if (t.length >= 3 && d.body.contains(t)) {
      s = 30;
    } else {
      final budget = fuzzy ? _typoBudget(t.length) : 0;
      if (budget > 0) {
        // Whole-word comparison; a half-typed word (>= 5 letters) may also match a word's start.
        bool near(List<String> ws) => ws.any((w) =>
            _distance(w, t, budget) <= budget ||
            (t.length >= 5 && w.length > t.length && _distance(w.substring(0, t.length), t, budget) <= budget));
        if (near(d.titleWords)) {
          s = 25;
        } else if (near(d.extraWords)) {
          s = 20;
        } else if (t.length >= 5 && near(d.bodyWords)) {
          s = 10; // typos in running text only for longer words (no noise like geld ~ gold)
        }
      }
    }
    return s * factor;
  }

  /// Character ranges of [text] to highlight for [query] (tokens and their synonyms,
  /// at word starts or as substrings of the typed word).
  static List<({int start, int end})> highlight(String text, String query) {
    final toks = tokens(query);
    if (toks.isEmpty) return const [];
    final f = fold(text);
    final ranges = <({int start, int end})>[];
    for (final tok in toks) {
      final terms = expand(tok);
      for (final term in terms) {
        final exact = term == tok;
        var from = 0;
        while (true) {
          final i = f.indexOf(term, from);
          if (i < 0) break;
          final atWordStart = i == 0 || f[i - 1] == ' ';
          if (exact ? (term.length >= 2) : atWordStart) ranges.add((start: i, end: i + term.length));
          from = i + term.length;
        }
      }
      // A near-miss word (typo) is highlighted as a whole word.
      final budget = _typoBudget(tok.length);
      if (budget > 0 && !terms.any(f.contains)) {
        var pos = 0;
        for (final w in f.split(' ')) {
          if (w.isNotEmpty && _distance(w, tok, budget) <= budget) ranges.add((start: pos, end: pos + w.length));
          pos += w.length + 1;
        }
      }
    }
    if (ranges.isEmpty) return const [];
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <({int start, int end})>[ranges.first];
    for (final r in ranges.skip(1)) {
      final last = merged.last;
      if (r.start <= last.end) {
        if (r.end > last.end) merged[merged.length - 1] = (start: last.start, end: r.end);
      } else {
        merged.add(r);
      }
    }
    return merged;
  }
}
