import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_config.dart';

/// Adaptive anchored banner. Collapses to 0px when not loaded (offline/failed).
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});
  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;
  int? _width;
  Orientation? _orientation;
  Timer? _retry;

  String get _unitId {
    final android = Platform.isAndroid;
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
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    _loading = true;
    _retry?.cancel();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(_width!);
    if (!mounted) { _loading = false; return; }
    if (size == null) { _loading = false; _scheduleRetry(); return; }
    final old = _ad;
    final ad = BannerAd(
      adUnitId: _unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (a) {
          _loading = false;
          if (!mounted) { a.dispose(); return; }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (a, _) {
          a.dispose();
          _loading = false;
          if (!mounted) return;
          setState(() { _ad = null; _loaded = false; });
          _scheduleRetry();
        },
      ),
    );
    _ad = ad;
    old?.dispose();
    _loaded = false;
    await ad.load();
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 60), () { if (mounted) _load(); });
  }

  @override
  void dispose() {
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink(); // 0px, no gap
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
