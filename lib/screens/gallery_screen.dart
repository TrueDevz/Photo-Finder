import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../models/event_model.dart';
import '../models/photo_model.dart';
import '../services/photo_service.dart';
import '../services/supabase_service.dart';
import '../utils/device_helper.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/photo_grid_item.dart';

class GalleryScreen extends StatefulWidget {
  final EventModel event;

  const GalleryScreen({super.key, required this.event});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<PhotoModel> _photos = [];
  final ScrollController _scroll = ScrollController();

  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _init();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final deviceId = await DeviceHelper.getDeviceId();
    _isSubscribed = await SupabaseService.instance.isSubscribed(deviceId);
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    try {
      final newPhotos = await PhotoService.instance.getPhotosForEvent(
        widget.event.id,
        page: _page,
      );
      setState(() {
        _photos.addAll(newPhotos);
        _page++;
        if (newPhotos.length < 20) _hasMore = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load photos: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.event.title,
                style: AppTextStyles.heading3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(
              '${_photos.length} photos',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          if (!_isSubscribed)
            TextButton.icon(
              icon: const Icon(Icons.lock_open_rounded,
                  size: 16, color: AppColors.primary),
              label: Text('Unlock All',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary)),
              onPressed: () => context.push(AppRoutes.payment, extra: widget.event),
            ),
        ],
      ),
      body: _photos.isEmpty && _loading
          ? const GalleryShimmer()
          : _photos.isEmpty
              ? const _EmptyGallery()
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _photos.clear();
                      _page = 0;
                      _hasMore = true;
                    });
                    await _init();
                  },
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: GridView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: _photos.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, idx) {
                      if (idx == _photos.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                      final photo = _photos[idx];
                      return PhotoGridItem(
                        photo: photo,
                        onTap: () {
                          context.push(
                            AppRoutes.photoViewer,
                            extra: {
                              'photo': photo,
                              'event': widget.event,
                              'isSubscribed': _isSubscribed,
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_outlined,
              size: 72, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(AppStrings.noPhotos, style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}
