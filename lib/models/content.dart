enum CheatStatus { verified, unverified, rumor }

class CheatCategory {
  final String id;
  final String name;
  const CheatCategory(this.id, this.name);
}

/// A cheat code for one platform: a D-pad sequence or a typed string.
class CheatCode {
  final List<String>? dpad;
  final String? text;
  const CheatCode.dpad(List<String> this.dpad) : text = null;
  const CheatCode.text(String this.text) : dpad = null;
}

class Cheat {
  final String id;
  final String name;
  final String categoryId;
  final String? description;
  final String effect;
  final String unlockRequirement;
  final Map<String, CheatCode> codes;
  final CheatStatus status;
  final DateTime addedAt;
  final DateTime updatedAt;
  final List<String> tags;
  final bool isNew;

  const Cheat({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.effect,
    required this.unlockRequirement,
    required this.status,
    required this.addedAt,
    required this.updatedAt,
    this.description,
    this.codes = const {},
    this.tags = const [],
    this.isNew = false,
  });

  CheatCode? codeFor(String platform) => codes[platform];
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final bool active;
  const Announcement({required this.id, required this.title, required this.message, required this.active});
}

class ContentData {
  final int schemaVersion;
  final int contentVersion;
  final String updatedAt;
  final List<CheatCategory> categories;
  final List<Cheat> cheats;
  final Announcement? announcement;
  final String rawJson;

  const ContentData({
    required this.schemaVersion,
    required this.contentVersion,
    required this.updatedAt,
    required this.categories,
    required this.cheats,
    required this.announcement,
    required this.rawJson,
  });

  /// Last-resort content so the UI can never be null or crash.
  const ContentData.empty()
      : schemaVersion = 0,
        contentVersion = 0,
        updatedAt = '',
        categories = const [],
        cheats = const [],
        announcement = null,
        rawJson = '';
}
