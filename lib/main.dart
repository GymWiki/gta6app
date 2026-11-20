import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'services/ad_config.dart';
import 'services/cheat_repository.dart';
import 'widgets/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (adsSupported) {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {}
  }
  final prefs = await SharedPreferences.getInstance();
  final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final repo = CheatRepository(prefs, lang: lang);
  final data = await repo.loadLocal();
  final state = AppState(repo, data);
  runApp(ChangeNotifierProvider.value(value: state, child: const ViceCodesApp()));
  state.refresh(); // non-blocking, throttled background check
}

class ViceCodesApp extends StatelessWidget {
  const ViceCodesApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Vice Codes',
        debugShowCheckedModeBanner: false,
        theme: Vice.theme(),
        home: const HomeShell(),
      );
}
