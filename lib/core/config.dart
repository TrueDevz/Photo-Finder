/// Application configuration.
/// Replace the placeholder values with your actual keys before running.
class AppConfig {
  AppConfig._();

  // ─── Supabase ──────────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // ─── Cloudflare R2 / CDN ───────────────────────────────────────────────────
  static const String cdnBaseUrl = 'https://cdn.yourdomain.com';
  static const String r2BucketName = 'event-photos';

  // ─── Razorpay ──────────────────────────────────────────────────────────────
  static const String razorpayKeyId = 'rzp_test_YOUR_KEY';
  static const int eventUnlockPrice = 500; // INR

  // ─── Start.io (Ads) ────────────────────────────────────────────────────────
  static const String startIoAppId = 'YOUR_STARTIO_APP_ID';

  // ─── Signed URL ────────────────────────────────────────────────────────────
  /// Signed URL expiry in seconds (5 minutes).
  static const int signedUrlExpiry = 300;

  // ─── Gallery ───────────────────────────────────────────────────────────────
  static const int galleryPageSize = 20;

  // ─── Image Optimization ────────────────────────────────────────────────────
  static const int fullImageWidth = 1280;
  static const int thumbnailWidth = 400;
  static const int fullImageQuality = 75;
}
