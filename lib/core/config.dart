/// Application configuration.
/// Replace the placeholder values with your actual keys before running.
class AppConfig {
  AppConfig._();

  // ─── Supabase ──────────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://whlunyumdvqphtgkkvvw.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_zaMqWw_LQ1wTwkiqWMNX_Q_f2VqWf0_';

  // ─── Cloudflare R2 / CDN ───────────────────────────────────────────────────
  static const String cdnBaseUrl = 'https://1b586e3c9f0f679c86769d573fb4167b.r2.cloudflarestorage.com/photo-finder';
  static const String r2BucketName = 'photo-finder';

  // ─── Razorpay ──────────────────────────────────────────────────────────────
  static const String razorpayKeyId = 'rzp_live_RErLXYqlik8ARX';
  static const int eventUnlockPrice = 500; // INR

  // ─── Start.io (Ads) ────────────────────────────────────────────────────────
  static const String startIoAppId = '201398462';

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
