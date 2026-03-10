import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Provides a stable device identifier that persists across app sessions.
class DeviceHelper {
  DeviceHelper._();

  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'photo_finder_device_id';
  static String? _cachedDeviceId;

  /// Returns a persistent, unique device ID.
  /// Generates a UUID on first run and stores it securely.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    String? stored = await _storage.read(key: _deviceIdKey);
    if (stored != null && stored.isNotEmpty) {
      _cachedDeviceId = stored;
      return stored;
    }

    // Try to get real device identifier
    final info = DeviceInfoPlugin();
    String rawId;
    try {
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        rawId = android.id;
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        rawId = ios.identifierForVendor ?? const Uuid().v4();
      } else {
        rawId = const Uuid().v4();
      }
    } catch (_) {
      rawId = const Uuid().v4();
    }

    await _storage.write(key: _deviceIdKey, value: rawId);
    _cachedDeviceId = rawId;
    return rawId;
  }

  /// Clears the cached device ID (for testing).
  static void clearCache() => _cachedDeviceId = null;
}
