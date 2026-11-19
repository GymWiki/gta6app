class Cheat {
  final String id;
  final String name;
  final String category;
  final String effect;
  final List<String>? dpadSequence;
  final String unlockRequirement;

  const Cheat({
    required this.id,
    required this.name,
    required this.category,
    required this.effect,
    required this.dpadSequence,
    required this.unlockRequirement,
  });

  factory Cheat.fromJson(Map<String, dynamic> j) => Cheat(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        effect: (j['effect'] as String?) ?? '',
        dpadSequence: (j['dpad_sequence'] as List?)?.map((e) => e.toString().toUpperCase()).toList(),
        unlockRequirement: (j['unlock_requirement'] as String?) ?? '',
      );
}

class CheatData {
  final int dataVersion;
  final String lastUpdated;
  final List<Cheat> cheats;
  final String rawJson;

  const CheatData({
    required this.dataVersion,
    required this.lastUpdated,
    required this.cheats,
    required this.rawJson,
  });
}
