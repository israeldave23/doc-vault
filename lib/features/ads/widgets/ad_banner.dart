import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's official AdMob *test* banner unit — used in debug so developers
/// never click their own live ads.
const _testBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';

/// TODO(release): replace with the real banner unit from the AdMob console,
/// together with the APPLICATION_ID meta-data in AndroidManifest.xml.
/// Until then release builds simply show no ad (an unknown unit never loads,
/// and this widget collapses to nothing).
const _productionBannerUnitId = 'ca-app-pub-0000000000000000/0000000000';

final bannerAdUnitId =
    kReleaseMode ? _productionBannerUnitId : _testBannerUnitId;

/// Single adaptive-free banner for the dashboard bottom (free tier only).
/// Renders nothing until the ad actually loads, so a missing or rejected unit
/// never leaves an empty reserved strip.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted && identical(_ad, ad)) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
