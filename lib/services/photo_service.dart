import '../models/photo_model.dart';
import '../utils/device_helper.dart';
import 'supabase_service.dart';
import 'ads_service.dart';

/// Orchestrates the photo unlock workflow:
///   1. Check if device already viewed photo
///   2. If not → show interstitial ad
///   3. After ad → record view in Supabase
///   4. Return unlocked photo URL
class PhotoService {
  PhotoService._();
  static PhotoService? _instance;

  static PhotoService get instance {
    _instance ??= PhotoService._();
    return _instance!;
  }

  final _supabase = SupabaseService.instance;
  final _ads = AdsService.instance;

  /// Returns paginated photos for an event, annotated with unlock state.
  Future<List<PhotoModel>> getPhotosForEvent(
    String eventId, {
    int page = 0,
    String? deviceId,
  }) async {
    final dId = deviceId ?? await DeviceHelper.getDeviceId();
    final photos = await _supabase.getPhotos(eventId, page: page);

    // Batch-fetch viewed photo IDs to avoid N+1 queries
    final viewedIds = await _supabase.getViewedPhotoIds(dId, eventId);
    for (final photo in photos) {
      photo.isUnlocked = viewedIds.contains(photo.id);
    }

    return photos;
  }

  /// Unlock flow for a single photo.
  /// Returns the signed full-resolution URL on success.
  Future<UnlockResult> unlockPhoto(
    PhotoModel photo, {
    required bool hasEventSubscription,
  }) async {
    final deviceId = await DeviceHelper.getDeviceId();

    // ── Subscribed user: skip ad entirely ──────────────────────────────────
    if (hasEventSubscription) {
      final signedUrl = await _getSignedUrl(photo);
      return UnlockResult(success: true, signedUrl: signedUrl, skippedAd: true);
    }

    // ── Already viewed ─────────────────────────────────────────────────────
    final alreadyViewed = await _supabase.hasViewed(photo.id, deviceId);
    if (alreadyViewed) {
      return const UnlockResult(
        success: false,
        alreadyViewed: true,
      );
    }

    // ── Show interstitial ad ───────────────────────────────────────────────
    final adShown = await _ads.showInterstitial();
    if (!adShown) {
      return const UnlockResult(success: false, adFailed: true);
    }

    // ── Record view + return signed URL ───────────────────────────────────
    await _supabase.recordView(photo.id, deviceId);
    final signedUrl = await _getSignedUrl(photo);
    return UnlockResult(success: true, signedUrl: signedUrl);
  }

  Future<String?> _getSignedUrl(PhotoModel photo) async {
    final filename = photo.imageUrl.split('/').last.split('?').first;
    final path = 'events/${photo.eventId}/full/$filename';
    return _supabase.getSignedUrl(path);
  }
}

/// Result of the [PhotoService.unlockPhoto] operation.
class UnlockResult {
  final bool success;
  final String? signedUrl;
  final bool alreadyViewed;
  final bool adFailed;
  final bool skippedAd;

  const UnlockResult({
    required this.success,
    this.signedUrl,
    this.alreadyViewed = false,
    this.adFailed = false,
    this.skippedAd = false,
  });
}
