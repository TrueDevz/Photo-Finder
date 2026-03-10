import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/constants.dart';
import 'models/event_model.dart';
import 'models/photo_model.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/event_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/photo_viewer_screen.dart';
import 'screens/payment_screen.dart';

final _router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.event}/:id',
      builder: (context, state) {
        final event = state.extra as EventModel;
        return EventScreen(event: event);
      },
    ),
    GoRoute(
      path: '${AppRoutes.gallery}/:eventId',
      builder: (context, state) {
        final event = state.extra as EventModel;
        return GalleryScreen(event: event);
      },
    ),
    GoRoute(
      path: AppRoutes.photoViewer,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return PhotoViewerScreen(
          photo: args['photo'] as PhotoModel,
          event: args['event'] as EventModel,
          isSubscribed: args['isSubscribed'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.payment,
      builder: (context, state) {
        final event = state.extra as EventModel;
        return PaymentScreen(event: event);
      },
    ),
  ],
);

class PhotoFinderApp extends StatelessWidget {
  const PhotoFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        fontFamily: AppTextStyles.fontFamily,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          contentTextStyle: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
