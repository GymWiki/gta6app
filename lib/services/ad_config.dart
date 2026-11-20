import 'package:flutter/foundation.dart';

/// Production AdMob banner unit IDs. Currently Google's sample IDs —
/// replace with your real units before release. In debug builds the
/// widget always uses the official test IDs below.
class AdConfig {
  static const testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const testIosBanner = 'ca-app-pub-3940256099942544/2934735716';

  static const prodAndroidBanner = 'ca-app-pub-3940256099942544/6300978111'; // TODO replace
  static const prodIosBanner = 'ca-app-pub-3940256099942544/2934735716'; // TODO replace
}

/// Ads only exist on Android/iOS; web, desktop and the test VM skip them.
bool get adsSupported =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
