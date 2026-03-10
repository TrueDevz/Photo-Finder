import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../models/event_model.dart';
import '../models/photo_model.dart';
import '../services/photo_service.dart';
import '../widgets/loading_indicator.dart';

enum _ViewState { idle, unlocking, unlocked, alreadyViewed, failed }

class PhotoViewerScreen extends StatefulWidget {
  final PhotoModel photo;
  final EventModel event;
  final bool isSubscribed;

  const PhotoViewerScreen({
    super.key,
    required this.photo,
    required this.event,
    required this.isSubscribed,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen>
    with SingleTickerProviderStateMixin {
  _ViewState _state = _ViewState.idle;
  String? _signedUrl;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    // Auto-start unlock if photo not yet unlocked
    if (widget.photo.isUnlocked || widget.isSubscribed) {
      _unlockPhoto();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlockPhoto() async {
    setState(() => _state = _ViewState.unlocking);

    final result = await PhotoService.instance.unlockPhoto(
      widget.photo,
      hasEventSubscription: widget.isSubscribed,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _state = _ViewState.unlocked;
        _signedUrl = result.signedUrl;
      });
      _fadeCtrl.forward();
    } else if (result.alreadyViewed) {
      setState(() => _state = _ViewState.alreadyViewed);
    } else {
      setState(() => _state = _ViewState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.event.title, style: AppTextStyles.body),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ViewState.idle:
        return _UnlockPrompt(onUnlock: _unlockPhoto);

      case _ViewState.unlocking:
        return _UnlockingView(isSubscribed: widget.isSubscribed);

      case _ViewState.unlocked:
        return _UnlockedView(
          signedUrl: _signedUrl ?? widget.photo.imageUrl,
          fadeAnimation: _fadeAnim,
        );

      case _ViewState.alreadyViewed:
        return _AlreadyViewedView(
          thumbnailUrl: widget.photo.thumbnailUrl,
          onPurchase: () => context.push(AppRoutes.payment, extra: widget.event),
        );

      case _ViewState.failed:
        return _FailedView(onRetry: _unlockPhoto);
    }
  }
}

// ─── Sub-views ────────────────────────────────────────────────────────────────

class _UnlockPrompt extends StatelessWidget {
  final VoidCallback onUnlock;

  const _UnlockPrompt({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_fill_rounded,
              size: 72, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(AppStrings.unlockPhoto, style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(AppStrings.watchAd, style: AppTextStyles.bodySecondary),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onUnlock,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Watch Ad & Unlock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockingView extends StatelessWidget {
  final bool isSubscribed;

  const _UnlockingView({required this.isSubscribed});

  @override
  Widget build(BuildContext context) {
    final msg = isSubscribed ? 'Loading your photo...' : AppStrings.adLoading;
    return LoadingIndicator(message: msg);
  }
}

class _UnlockedView extends StatelessWidget {
  final String signedUrl;
  final Animation<double> fadeAnimation;

  const _UnlockedView({
    required this.signedUrl,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: signedUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const LoadingIndicator(message: 'Loading full image...'),
            errorWidget: (_, __, ___) => const Icon(
              Icons.broken_image_rounded,
              color: AppColors.textSecondary,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlreadyViewedView extends StatelessWidget {
  final String thumbnailUrl;
  final VoidCallback onPurchase;

  const _AlreadyViewedView({
    required this.thumbnailUrl,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred thumbnail
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: CachedNetworkImage(
            imageUrl: thumbnailUrl,
            fit: BoxFit.cover,
          ),
        ),
        Container(color: Colors.black.withOpacity(0.6)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded,
                    size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text('Already Viewed',
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  AppStrings.alreadyViewed,
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: onPurchase,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text('Unlock Event – ₹500'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _FailedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Something went wrong', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text('Ad failed to load. Please try again.',
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
