/// Minimal in-app translations (nl / en). Anything that is not Dutch falls back to English.
class Strings {
  final bool nl;
  const Strings(String lang) : nl = lang == 'nl';

  String _(String en, String nlText) => nl ? nlText : en;

  // Navigation
  String get tabCheats => _('CHEATS', 'CHEATS');
  String get tabTracker => _('TRACKER', 'VOORTGANG');
  String get tabSettings => _('SETTINGS', 'INSTELLINGEN');

  // Header
  String get searchHint => _('Search cheats, effects, unlocks…', 'Zoek cheats, effecten, eisen…');
  String get clearSearch => _('Clear search', 'Zoekopdracht wissen');
  String phoneHint(bool ps5) => ps5
      ? _('Open Phone (↑) + Hold L1 & R1', 'Open telefoon (↑) + houd L1 & R1 ingedrukt')
      : _('Open Phone (↑) + Hold LB & RB', 'Open telefoon (↑) + houd LB & RB ingedrukt');
  String get note => _(
        'Note: Cheats unlock in the Pause Menu (Progress > Cheats) only after completing the main story. Activating cheats disables Trophies/Achievements.',
        'Let op: cheats ontgrendel je in het pauzemenu (Progress > Cheats) pas na het uitspelen van het verhaal. Cheats activeren schakelt Trophies/Achievements uit.');
  String get showNote => _('Show note', 'Toon opmerking');
  String get hideNote => _('Hide note', 'Verberg opmerking');

  // Cheats tab
  String get pinned => _('PINNED', 'VASTGEPIND');
  String get allCheats => _('ALL CHEATS', 'ALLE CHEATS');
  String get filterAll => _('All', 'Alles');
  String get noMatch => _('No cheats match your search.', 'Geen cheats gevonden.');
  String get clearFilters => _('Clear filters', 'Filters wissen');
  String get howToUnlock => _('HOW TO UNLOCK', 'ZO ONTGRENDEL JE HEM');
  String get addFavorite => _('Add to favorites', 'Toevoegen aan favorieten');
  String get removeFavorite => _('Remove from favorites', 'Verwijderen uit favorieten');
  String get markUnlocked => _('Mark as unlocked', 'Markeer als ontgrendeld');
  String get markLocked => _('Mark as locked', 'Markeer als vergrendeld');
  String get tapForInfo => _('Tap for unlock info', 'Tik voor unlock-info');
  String get codeTba => 'CODE TBA — COMMUNITY HUNTING';
  String get codeTbaLabel => _('Code to be announced, community hunting', 'Code nog niet bekend, de community zoekt');
  String codeLabel(String c) => _('Code: $c', 'Code: $c');

  // Badges & status
  String get badgeNew => _('NEW', 'NIEUW');
  String get badgeUpdated => _('UPDATED', 'BIJGEWERKT');
  String get statusVerified => _('VERIFIED', 'GEVERIFIEERD');
  String get statusUnverified => _('UNVERIFIED', 'NIET GEVERIFIEERD');
  String get statusRumor => _('RUMOR', 'GERUCHT');

  // Tracker
  String get cheatsUnlocked => _('Cheats Unlocked', 'Cheats ontgrendeld');
  String get filterTodo => _('To-Do', 'Te doen');
  String get filterUnlocked => _('Unlocked', 'Ontgrendeld');
  String get trackerEmptyTodo => _('All unlocked. Nothing left to do!', 'Alles ontgrendeld. Niets meer te doen!');
  String get trackerEmpty => _('Nothing here yet.', 'Hier staat nog niets.');

  // Settings
  String get settingsTitle => _('Settings', 'Instellingen');
  String get contentTitle => _('Content', 'Content');
  String get lastUpdated => _('Last updated', 'Laatst bijgewerkt');
  String get contentVersion => _('Content version', 'Contentversie');
  String get lastChecked => _('Last checked', 'Laatst gecontroleerd');
  String get never => _('never', 'nog niet');
  String get refreshNow => _('Refresh now', 'Nu verversen');
  String get resetProgress => _('Reset progress', 'Voortgang resetten');
  String get resetTitle => _('Reset progress?', 'Voortgang resetten?');
  String get resetBody => _(
      'This clears all unlocked checkmarks and favorites. It cannot be undone.',
      'Hiermee wis je alle ontgrendelde cheats en favorieten. Dit kan niet ongedaan worden gemaakt.');
  String get cancel => _('Cancel', 'Annuleren');
  String get reset => _('Reset', 'Resetten');
  String get resetDone => _('Progress reset.', 'Voortgang gereset.');
  String get disclaimer => _(
      'Unofficial fan-made companion app. Not affiliated with, endorsed, or sponsored by Rockstar Games or Take-Two Interactive.',
      'Onofficiële fan-app. Niet verbonden aan, goedgekeurd door of gesponsord door Rockstar Games of Take-Two Interactive.');
  String get cheatsWord => _('cheats', 'cheats');

  // Sync feedback
  String updatedTo(int v) => _('Updated to content version $v.', 'Bijgewerkt naar contentversie $v.');
  String get upToDate => _('You already have the latest content.', 'Je hebt al de nieuwste content.');
  String get needsAppUpdate => _('Update the app for new features.', 'Update de app voor nieuwe functies.');
  String get notConfigured => _('No content URL set. Using bundled content.', 'Geen content-URL ingesteld. Gebundelde content wordt gebruikt.');
  String get offline => _('No connection. Using saved content.', 'Geen verbinding. Opgeslagen content wordt gebruikt.');

  // Banners
  String get close => _('Close', 'Sluiten');
  String get appUpdateTitle => _('Update the app for new features', 'Update de app voor nieuwe functies');
  String get appUpdateBody => _(
      'There is new content this version does not support yet.',
      'Er is nieuwe content die deze versie nog niet ondersteunt.');

  // --- Redesign: header, filters, rows, sheets ---
  String get infoTooltip => _('How it works', 'Uitleg');
  String get filterWithCode => _('With code', 'Met code');
  String get filterFavorites => _('Favorites', 'Favorieten');
  String get quickFavorites => _('FAVORITES', 'FAVORIETEN');
  String get quickRecent => _('RECENT', 'RECENT');
  String noCodeSection(int n) => _('No code known yet ($n)', 'Nog geen code bekend ($n)');
  String groupHeader(String name, int n) => '$name · $n';
  String noResultFor(String q) => _('No result for "$q"', 'Geen resultaat voor "$q"');
  String get noFavorites => _('No favorites yet. Tap the star on a cheat.', 'Nog geen favorieten. Tik op de ster bij een cheat.');
  String get reportMissing => _('Missing a cheat? Report it', 'Mis je een cheat? Meld het');
  String get reportCopied => _('Address copied. Send us your cheat idea.', 'Adres gekopieerd. Stuur ons je cheat-tip.');
  String get copyCode => _('Copy code', 'Kopieer code');
  String get codeCopied => _('Code copied', 'Code gekopieerd');
  String get markUsed => _('Mark as unlocked', 'Markeer als ontgrendeld');
  String get unmarkUsed => _('Unlocked', 'Ontgrendeld');
  String get unlockedTag => _('Unlocked in-game', 'In de game ontgrendeld');
  String get statusWord => _('Status', 'Status');
  String get statusVerifiedInfo => _('Tested in-game and confirmed.', 'In de game getest en bevestigd.');
  String get statusUnverifiedInfo => _('Reported by guides, not tested by us yet.', 'Gemeld door gidsen, nog niet door ons getest.');
  String get statusRumorInfo => _('Unconfirmed rumor. Treat with care.', 'Onbevestigd gerucht. Wees voorzichtig.');
  String get legend => _('Status legend', 'Statuslegenda');

  // Info sheet
  String get infoTitle => _('How it works', 'Zo werkt het');
  String get infoEnter => _('Entering a code', 'Een code invoeren');
  String get infoPs5 => _('PS5: open the phone with D-pad Up, hold L1, press R1, then enter the D-pad code.', 'PS5: open de telefoon met D-pad omhoog, houd L1 ingedrukt, druk op R1 en voer de D-pad-code in.');
  String get infoXbox => _('Xbox: open the phone with D-pad Up, hold LB, press RB, then enter the D-pad code.', 'Xbox: open de telefoon met D-pad omhoog, houd LB ingedrukt, druk op RB en voer de D-pad-code in.');
  String get infoMore => _('Good to know', 'Goed om te weten');

  // First start
  String get pickPlatformTitle => _('Which console do you play on?', 'Op welke console speel je?');
  String get pickPlatformBody => _('We show the right button hints. You can change this any time.', 'Zo tonen we de juiste knop-uitleg. Je kunt dit altijd wijzigen.');
  String get gotIt => _('Got it', 'Begrepen');

  // Settings
  String get settingsListTitle => _('List', 'Lijst');
  String get settingsNoCode => _('Collapse cheats without a code', 'Cheats zonder code inklappen');
  String get settingsNoCodeHint => _(
      'Cheats whose code is not known yet go in a collapsed section at the bottom.',
      'Cheats waarvan de code nog niet bekend is komen in een ingeklapte sectie onderaan.');
  String get showHowItWorks => _('How it works', 'Uitleg bekijken');

  // Console button sequence
  String get stepOpenPhone => _('Open the phone', 'Open de telefoon');
  String get stepHoldPs5 => _('Hold L1, then press R1', 'Houd L1 vast en druk op R1');
  String get stepHoldXbox => _('Hold LB, then press RB', 'Houd LB vast en druk op RB');
  String stepEnterCode(int n) => _('Enter the code ($n buttons)', 'Voer de code in ($n knoppen)');
  String get hold => _('HOLD', 'HOUD VAST');
  String get press => _('PRESS', 'DRUK');
}
