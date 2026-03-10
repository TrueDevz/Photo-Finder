import 'package:flutter/material.dart';
import 'dart:async';

import '../core/config.dart';

/// Placeholder for Start.io interstitial ad integration.
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
    _isInitialized = true;
    await _loadInterstitial();
  }

  // ─── Interstitial ──────────────────────────────────────────────────────────

  Future<void> _loadInterstitial() async {
    if (!_isInitialized) return;
    await Future.delayed(const Duration(milliseconds: 300));
    _isAdReady = true;
  }

  /// Shows a simulated interstitial ad.
  Future<bool> showInterstitial(BuildContext context) async {
    if (!_isInitialized) await initialize();
    if (!context.mounted) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SimulatedAdDialog(type: 'Interstitial'),
    );

    _isAdReady = false;
    await _loadInterstitial();
    return result ?? true;
  }

  /// Shows a simulated video (rewarded) ad.
  Future<bool> showVideoAd(BuildContext context) async {
    if (!_isInitialized) await initialize();
    if (!context.mounted) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SimulatedAdDialog(type: 'Video/Rewarded', duration: 5),
    );

    return result ?? true;
  }

  /// Returns a simulated Banner Ad widget.
  Widget buildBannerAd() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ad_units_rounded, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Text('Simulated Banner Ad', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('AD', style: TextStyle(color: Colors.white, fontSize: 8)),
            ),
          ),
        ],
      ),
    );
  }

  bool get isReady => _isAdReady;
  bool get isInitialized => _isInitialized;

  static const bool testMode = true;
  static String get appId => AppConfig.startIoAppId;
}

class _SimulatedAdDialog extends StatefulWidget {
  final String type;
  final int duration;

  const _SimulatedAdDialog({required this.type, this.duration = 3});

  @override
  State<_SimulatedAdDialog> createState() => _SimulatedAdDialogState();
}

class _SimulatedAdDialogState extends State<_SimulatedAdDialog> {
  late int _secondsRemaining;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer.cancel();
        if (mounted) Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
      },
      child: Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.type == 'Video/Rewarded' 
                        ? Icons.stars_rounded 
                        : Icons.play_circle_fill_rounded, 
                    size: 80, 
                    color: Colors.blueAccent
                  ),
                  const SizedBox(height: 24),
                  Text('${widget.type} Ad Playing...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Reward in $_secondsRemaining seconds', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(color: Colors.blueAccent),
                ],
              ),
            ),
            if (_secondsRemaining == 0)
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
