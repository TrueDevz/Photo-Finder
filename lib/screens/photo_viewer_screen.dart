import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../core/constants.dart';
import '../models/event_model.dart';
import '../models/photo_model.dart';
import '../services/photo_service.dart';
import '../services/ads_service.dart';
import '../widgets/loading_indicator.dart';

enum _ViewState { idle, loading, success, failed }

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

    // Start loading full image immediately for viewing
    _loadFullImage();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFullImage() async {
    setState(() => _state = _ViewState.loading);

    // Get signed URL for the full image
    final url = await PhotoService.instance.getSignedUrl(
      widget.photo.imageUrl,
      widget.event.id,
    );

    if (!mounted) return;

    if (url != null) {
      setState(() {
        _state = _ViewState.success;
        _signedUrl = url;
      });
      _fadeCtrl.forward();
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
      case _ViewState.loading:
        return const LoadingIndicator(message: 'Loading full quality photo...');

      case _ViewState.success:
        return _SuccessView(
          signedUrl: _signedUrl ?? widget.photo.imageUrl,
          fadeAnimation: _fadeAnim,
          photoId: widget.photo.id,
          isSubscribed: widget.isSubscribed,
        );

      case _ViewState.failed:
        return _FailedView(onRetry: _loadFullImage);
    }
  }
}

// ─── Sub-views ────────────────────────────────────────────────────────────────


class _SuccessView extends StatefulWidget {
  final String signedUrl;
  final Animation<double> fadeAnimation;
  final String photoId;
  final bool isSubscribed;

  const _SuccessView({
    required this.signedUrl,
    required this.fadeAnimation,
    required this.photoId,
    required this.isSubscribed,
  });

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView> {
  bool _isSaving = false;

  Future<void> _saveToGallery(BuildContext context) async {
    setState(() => _isSaving = true);

    try {
      // 0. Show Ad for non-subscribers
      if (!widget.isSubscribed) {
        final adShown = await AdsService.instance.showInterstitial();
        if (!adShown) {
          // Handle ad failure if necessary, or just proceed
        }
      }

      // 1. Check/Request permission
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // 2. Download file to temp
      final response = await http.get(Uri.parse(widget.signedUrl));
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/${widget.photoId}.jpg';
      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);

      // 3. Save to gallery
      await Gal.putImage(path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to Gallery!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.signedUrl,
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
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              onPressed: _isSaving ? null : () => _saveToGallery(context),
              backgroundColor: AppColors.primary,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
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
