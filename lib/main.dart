import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/supabase_service.dart';
import 'services/ads_service.dart';
import 'utils/device_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ── Initialize Supabase ─────────────────────────────────────────────────
  await SupabaseService.initialize();

  // ── Initialize Ads ──────────────────────────────────────────────────────
  await AdsService.instance.initialize();

  // ── Register device ─────────────────────────────────────────────────────
  final deviceId = await DeviceHelper.getDeviceId();
  await SupabaseService.instance.createUser(deviceId);

  runApp(const PhotoFinderApp());
}
