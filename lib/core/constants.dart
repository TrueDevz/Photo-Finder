import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color accent = Color(0xFFFF6584);
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252540);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color divider = Color(0xFF2E2E4E);
  static const Color success = Color(0xFF4CAF82);
  static const Color error = Color(0xFFFF5252);
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Poppins';

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
}

class AppDimensions {
  AppDimensions._();

  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  static const double eventCardHeight = 220.0;
  static const double photoGridItemSize = 120.0;
}

class AppStrings {
  AppStrings._();

  static const String appName = 'Event Photo Finder';
  static const String tagline = 'Find your moments, unlock your memories';

  // Navigation
  static const String home = 'Events';
  static const String gallery = 'Gallery';
  static const String subscription = 'Unlock Event';

  // Actions
  static const String viewPhotos = 'View Photos';
  static const String unlockPhoto = 'Unlock Photo';
  static const String purchaseEvent = 'Purchase Event Access';
  static const String watchAd = 'Watch Ad to Unlock';

  // Messages
  static const String alreadyViewed =
      'You\'ve already viewed this photo once. Purchase event access for unlimited views.';
  static const String adLoading = 'Loading your photo...';
  static const String paymentSuccess = 'Event unlocked! Enjoy unlimited access.';
  static const String noEvents = 'No events yet. Check back soon!';
  static const String noPhotos = 'No photos in this event.';
  static const String loadingEvents = 'Loading events...';
  static const String loadingPhotos = 'Loading photos...';
}

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String event = '/event';
  static const String gallery = '/gallery';
  static const String photoViewer = '/photo-viewer';
  static const String payment = '/payment';
}
