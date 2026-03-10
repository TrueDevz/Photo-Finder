import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/event_model.dart';
import '../models/photo_model.dart';

/// Singleton wrapper around the Supabase client.
/// Call [SupabaseService.initialize] once in main() before using any methods.
class SupabaseService {
  SupabaseService._();
  static SupabaseService? _instance;

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get client => Supabase.instance.client;

  // ─── Initialization ────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // ─── Events ────────────────────────────────────────────────────────────────

  /// Returns all events ordered by event_date descending.
  Future<List<EventModel>> getEvents() async {
    final response = await client
        .from('events')
        .select()
        .order('event_date', ascending: false);

    return (response as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns a single event by ID.
  Future<EventModel?> getEvent(String id) async {
    final response =
        await client.from('events').select().eq('id', id).single();
    return EventModel.fromJson(response);
  }

  // ─── Photos ────────────────────────────────────────────────────────────────

  /// Returns paginated photos for an event.
  Future<List<PhotoModel>> getPhotos(
    String eventId, {
    int page = 0,
    int limit = 20,
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    final response = await client
        .from('photos')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: true)
        .range(from, to);

    return (response as List)
        .map((p) => PhotoModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  // ─── Views ─────────────────────────────────────────────────────────────────

  /// Checks whether [deviceId] has already viewed [photoId].
  Future<bool> hasViewed(String photoId, String deviceId) async {
    final response = await client
        .from('views')
        .select('id')
        .eq('photo_id', photoId)
        .eq('device_id', deviceId)
        .maybeSingle();

    return response != null;
  }

  /// Records a view for [photoId] by [deviceId].
  Future<void> recordView(String photoId, String deviceId) async {
    await client.from('views').insert({
      'photo_id': photoId,
      'device_id': deviceId,
      'viewed_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns all viewed photo IDs for a device.
  Future<Set<String>> getViewedPhotoIds(
      String deviceId, String eventId) async {
    final response = await client
        .from('views')
        .select('photo_id')
        .eq('device_id', deviceId);

    return (response as List)
        .map((r) => r['photo_id'] as String)
        .toSet();
  }

  // ─── Users ─────────────────────────────────────────────────────────────────

  /// Returns user record for [deviceId], or null if first launch.
  Future<Map<String, dynamic>?> getUser(String deviceId) async {
    return await client
        .from('users')
        .select()
        .eq('device_id', deviceId)
        .maybeSingle();
  }

  /// Creates a user record on first launch.
  Future<void> createUser(String deviceId) async {
    await client.from('users').upsert({
      'device_id': deviceId,
      'is_subscribed': false,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'device_id');
  }

  /// Marks a user as subscribed (purchased event access).
  Future<void> setSubscribed(String deviceId, {required bool value}) async {
    await client
        .from('users')
        .update({'is_subscribed': value})
        .eq('device_id', deviceId);
  }

  /// Returns whether [deviceId] is subscribed.
  Future<bool> isSubscribed(String deviceId) async {
    final user = await getUser(deviceId);
    return user?['is_subscribed'] as bool? ?? false;
  }

  /// Returns whether [deviceId] is subscribed to a specific [eventId].
  Future<bool> isEventSubscribed(String deviceId, String eventId) async {
    // 1. Check global subscription first
    if (await isSubscribed(deviceId)) return true;

    // 2. Check event-specific sub
    final response = await client
        .from('event_subscriptions')
        .select('id')
        .eq('event_id', eventId)
        .eq('device_id', deviceId)
        .maybeSingle();

    return response != null;
  }

  /// Marks a specific event as subscribed for [deviceId].
  Future<void> setEventSubscribed(String deviceId, String eventId) async {
    await client.from('event_subscriptions').upsert({
      'event_id': eventId,
      'device_id': deviceId,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'event_id,device_id');
  }

  // ─── Signed URLs ───────────────────────────────────────────────────────────

  /// Generates a signed URL for a photo stored in Supabase Storage.
  /// Path format: events/{eventId}/full/{filename}
  Future<String?> getSignedUrl(String storagePath) async {
    final response = await client.storage.from('event-photos').createSignedUrl(
          storagePath,
          AppConfig.signedUrlExpiry,
        );
    return response;
  }
}
