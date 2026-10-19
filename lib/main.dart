import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enables background playback + lock screen / notification controls.
  // Wrapped so a setup problem never blocks the app from opening.
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.musicplayer.channel.audio',
      androidNotificationChannelName: 'Music playback',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint('Background audio init failed: $e');
  }

  await initDependencies();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0B0B12),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MusicApp());
}