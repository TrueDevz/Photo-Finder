import '../core/config.dart';

class EventModel {
  final String id;
  final String title;
  final DateTime eventDate;
  final String coverImage;
  final int price;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.coverImage,
    required this.price,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    String coverImage = json['cover_image'] as String? ?? '';
    if (coverImage.isNotEmpty && !coverImage.startsWith('http')) {
      coverImage = '${AppConfig.cdnBaseUrl}/$coverImage';
    }

    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      coverImage: coverImage,
      price: json['price'] as int? ?? 500,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'event_date': eventDate.toIso8601String().split('T').first,
        'cover_image': coverImage,
        'price': price,
        'created_at': createdAt.toIso8601String(),
      };

  EventModel copyWith({
    String? id,
    String? title,
    DateTime? eventDate,
    String? coverImage,
    int? price,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      coverImage: coverImage ?? this.coverImage,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'EventModel(id: $id, title: $title, eventDate: $eventDate)';
}
