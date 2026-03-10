import '../core/config.dart';

class PhotoModel {
  final String id;
  final String eventId;
  final String imageUrl;
  final String thumbnailUrl;
  final DateTime createdAt;

  /// Whether the current device has already unlocked / viewed this photo.
  bool isUnlocked;

  PhotoModel({
    required this.id,
    required this.eventId,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.createdAt,
    this.isUnlocked = false,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    final eventId = json['event_id'] as String;
    String imageUrl = json['image_url'] as String? ?? '';
    String thumbnailUrl = json['thumbnail_url'] as String? ?? '';

    // If paths are relative, reconstruct using CDN base URL
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      print('PhotoModel.fromJson: imageUrl is relative: $imageUrl');
      // If it's just a filename, prepend eventId/
      if (!imageUrl.contains('/')) {
        imageUrl = '$eventId/$imageUrl';
      }
      imageUrl = '${AppConfig.cdnBaseUrl}/$imageUrl';
      print('PhotoModel.fromJson: reconstructed imageUrl: $imageUrl');
    }

    if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
      if (!thumbnailUrl.contains('/')) {
        thumbnailUrl = '$eventId/$thumbnailUrl';
      }
      thumbnailUrl = '${AppConfig.cdnBaseUrl}/$thumbnailUrl';
    }

    return PhotoModel(
      id: json['id'] as String,
      eventId: eventId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_id': eventId,
        'image_url': imageUrl,
        'thumbnail_url': thumbnailUrl,
        'created_at': createdAt.toIso8601String(),
      };

  PhotoModel copyWith({
    String? id,
    String? eventId,
    String? imageUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    bool? isUnlocked,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  @override
  String toString() =>
      'PhotoModel(id: $id, eventId: $eventId, isUnlocked: $isUnlocked)';
}
