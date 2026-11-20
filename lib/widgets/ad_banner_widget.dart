import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_config.dart';
import 'theme.dart';

/// Adaptive anchored banner in a fixed strip above the nav bar (never over the list).
/// The height is reserved while the ad loads, so nothing shifts when it appears; if the
/// ad fails (offline, no fill) the strip collapses to 0px.
class AdBannerWidget extends StatefulWidget {
  /// Tests/screenshots only: draw a placeholder strip of this height where an ad would be.
  @visibleForTesting
  static double? debugPlaceholderHeight;

  const AdBannerWidget({super.key});
  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  bool _failed = false;
  bool _loading = false;
  int? _width;
  Orientation? _orientation;
  Timer? _retry;

  String get _unitId {
    final android = defaultTargetPlatform == TargetPlatform.android;
    if (kDebugMode) return android ? AdConfig.testAndroidBanner : AdConfig.testIosBanner;
    return android ? AdConfig.prodAndroidBanner : AdConfig.prodIosBanner;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    final w = mq.size.width.truncate();
    if (w != _width || mq.orientation != _orientation) {
      _width = w;
      _orientation = mq.orientation;
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading || _width == null) return;
    if (!adsSupported) return;
    _loading = true;
    _retry?.cancel();
    try {
      final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(_width!);
      if (!mounted) {
        _loading = false;
        return;
      }
      if (size == null) {
        _loading = false;
        _scheduleRetry();
        return;
      }
      final old = _ad;
      final ad = BannerAd(
        adUnitId: _unitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (a) {
            _loading = false;
            if (!mounted) {
              a.dispose();
              return;
            }
            setState(() {
              _loaded = true;
              _failed = false;
            });
          },
          onAdFailedToLoad: (a, _) {
            a.dispose();
            _loading = false;
            if (!mounted) return;
            setState(() {
              _ad = null;
              _loaded = false;
              _failed = true;
            });
            _scheduleRetry();
          },
        ),
      );
      setState(() {
        _ad = ad;
        _size = size; // reserve the strip now, so the ad does not push the list when it loads
        _loaded = false;
        _failed = false;
      });
      old?.dispose();
      await ad.load();
    } catch (_) {
      // Ads must never break the app: collapse and try again later.
      _loading = false;
      if (mounted) {
        setState(() {
          _ad = null;
          _loaded = false;
          _failed = true;
        });
        _scheduleRetry();
      }
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 60), () {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = AdBannerWidget.debugPlaceholderHeight;
    if (!adsSupported && placeholder != null) {
      return Container(height: placeholder, color: Vice.surfaceHi, alignment: Alignment.center, child: const Text('AD', style: TextStyle(color: Vice.muted)));
    }
    final ad = _ad;
    final size = _size;
    // Reserve the strip from the start (50dp until the adaptive size is known).
    final show = adsSupported && !_failed;
    final height = (size?.height ?? 50).toDouble();
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.topCenter,
      child: show
          ? SizedBox(
              width: double.infinity,
              height: height,
              child: Center(
                child: (_loaded && ad != null && size != null)
                    ? SizedBox(width: size.width.toDouble(), height: size.height.toDouble(), child: AdWidget(ad: ad))
                    : const SizedBox.shrink(),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
