import 'dart:async';

import '../core/config.dart';

/// Placeholder for Start.io interstitial ad integration.
///
/// Integration steps (when Start.io SDK is ready):
/// 1. Download the Start.io Android AAR from https://www.start.io/
/// 2. Add it to android/app/libs/ and update android/app/build.gradle
/// 3. Uncomment and adapt the SDK calls marked with "SDK:" below.
class AdsService {
  AdsService._();
  static AdsService? _instance;

  static AdsService get instance {
    _instance ??= AdsService._();
    return _instance!;
  }

  bool _isInitialized = false;
  bool _isAdReady = false;

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // SDK: StartAppSdk().setTestAdsEnabled(testMode);
    // SDK: StartAppSdk().init(AppConfig.startIoAppId);
    _isInitialized = true;
    await _loadInterstitial();
  }

  // ─── Interstitial ──────────────────────────────────────────────────────────

  Future<void> _loadInterstitial() async {
    if (!_isInitialized) return;
    // SDK: StartAppInterstitial().load(() => _isAdReady = true, (err) {});
    await Future.delayed(const Duration(milliseconds: 300));
    _isAdReady = true;
  }

  /// Shows an interstitial ad and resolves [true] when dismissed.
  /// Falls back to a 2-second simulated delay until Start.io SDK is wired up.
  Future<bool> showInterstitial() async {
    if (!_isAdReady) {
      await Future.delayed(const Duration(seconds: 1));
    }

    // ── SDK integration (uncomment when Start.io AAR is integrated) ──────────
    // final completer = Completer<bool>();
    // StartAppInterstitial().show(
    //   onAdDisplayed: () {},
    //   onAdClicked: () {},
    //   onAdHidden: () {
    //     _isAdReady = false;
    //     _loadInterstitial();
    //     completer.complete(true);
    //   },
    //   onFailedToShowAd: (_) => completer.complete(false),
    // );
    // return completer.future;
    // ─────────────────────────────────────────────────────────────────────────

    // Placeholder: simulate ad playback duration
    await Future.delayed(const Duration(seconds: 2));
    _isAdReady = false;
    await _loadInterstitial();
    return true;
  }

  bool get isReady => _isAdReady;
  bool get isInitialized => _isInitialized;

  /// Switch to false in production.
  static const bool testMode = true;

  static String get appId => AppConfig.startIoAppId;
}
