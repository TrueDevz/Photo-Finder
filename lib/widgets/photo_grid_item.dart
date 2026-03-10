import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants.dart';
import '../models/photo_model.dart';

class PhotoGridItem extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback onTap;

  const PhotoGridItem({
    super.key,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Thumbnail ───────────────────────────────────────────────────
            CachedNetworkImage(
              imageUrl: photo.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _ShimmerPlaceholder(),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surfaceLight,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // ── Blur overlay if locked ───────────────────────────────────
            if (!photo.isUnlocked)
              _LockedOverlay(),

            // ── Unlocked badge ───────────────────────────────────────────
            if (photo.isUnlocked)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockedOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.1),
            Colors.black.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.divider,
      child: Container(color: AppColors.surfaceLight),
    );
  }
}
