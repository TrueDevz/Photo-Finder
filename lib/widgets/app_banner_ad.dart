import 'package:flutter/material.dart';
import '../services/ads_service.dart';
import '../services/supabase_service.dart';
import '../utils/device_helper.dart';

/// A wrapper for Banner Ads that automatically checks subscription status.
class AppBannerAd extends StatefulWidget {
  final String? eventId;

  /// If [eventId] is provided, the ad will be hidden if the event is subscribed.
  /// If [eventId] is null, the ad will always show (unless a global subscription check is added).
  const AppBannerAd({super.key, this.eventId});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  bool _shouldShow = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    if (widget.eventId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final isSubscribed = await SupabaseService.instance.isEventSubscribed(deviceId, widget.eventId!);
      if (mounted) {
        setState(() {
          _shouldShow = !isSubscribed;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (!_shouldShow) return const SizedBox.shrink();

    return AdsService.instance.buildBannerAd();
  }
}
