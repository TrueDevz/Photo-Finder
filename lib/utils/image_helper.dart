import '../core/config.dart';

/// Helper utilities for constructing and manipulating image URLs.
class ImageHelper {
  ImageHelper._();

  /// Builds the CDN URL for a WebP thumbnail.
  static String buildThumbnailUrl(String eventId, String filename) {
    return '${AppConfig.cdnBaseUrl}/events/$eventId/thumb/$filename';
  }

  /// Builds the CDN URL for a full-size WebP photo.
  static String buildFullImageUrl(String eventId, String filename) {
    return '${AppConfig.cdnBaseUrl}/events/$eventId/full/$filename';
  }

  /// Appends a signed-URL token + expiry to an existing CDN URL.
  static String withSignedToken(String url, String token) {
    return '$url?token=$token&expire=${AppConfig.signedUrlExpiry}';
  }

  /// Extracts filename from a full URL.
  static String filenameFromUrl(String url) {
    return url.split('/').last.split('?').first;
  }

  /// Returns a blurred / locked placeholder URL (via CDN transform params).
  static String blurredUrl(String cdnUrl) {
    // Append blur transform – works if your CDN supports query transforms.
    return '$cdnUrl?blur=20&quality=10';
  }
}
