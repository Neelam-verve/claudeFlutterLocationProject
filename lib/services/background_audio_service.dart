import 'dart:async';
import 'dart:ui';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/app_constants.dart';

/// Initialize the background service — call once from main.dart
Future<void> initBackgroundAudioService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: false, // We start it manually when child logs in
      isForegroundMode: true,
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'Safety Monitor',
      initialNotificationContent: 'Running in background for your safety',
      foregroundServiceTypes: [
        AndroidForegroundType.microphone,
        AndroidForegroundType.location,
      ],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onStart,
      onBackground: _onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Initialize Firebase in this isolate
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }

  RtcEngine? engine;
  bool isBroadcasting = false;
  StreamSubscription<DocumentSnapshot>? firestoreSubscription;
  StreamSubscription<Position>? locationSubscription;
  String? watchingUid;

  // Android-specific: set as foreground service
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }

  // Listen for start command from foreground with child UID
  service.on('startWatching').listen((event) async {
    final uid = event?['uid'] as String?;
    if (uid == null || uid.isEmpty) return;
    if (watchingUid == uid) return; // Already watching this uid

    debugPrint('BgAudio: Start watching uid=$uid');
    watchingUid = uid;

    // Cancel previous subscriptions
    await firestoreSubscription?.cancel();
    await locationSubscription?.cancel();

    // Start background location tracking
    locationSubscription = _startLocationTracking(uid);

    // Watch isListening field on this user's doc
    final db = FirebaseFirestore.instance;
    firestoreSubscription = db.collection('users').doc(uid).snapshots().listen((
      snapshot,
    ) async {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final isListening = data['isListening'] ?? false;

      if (isListening && !isBroadcasting) {
        debugPrint('BgAudio: isListening=true, starting broadcast');
        engine = await _initAndBroadcast(engine, uid);
        if (engine != null) {
          isBroadcasting = true;
        }
      } else if (!isListening && isBroadcasting) {
        debugPrint('BgAudio: isListening=false, stopping broadcast');
        try {
          await engine?.leaveChannel();
          await engine?.enableLocalAudio(false);
        } catch (e) {
          debugPrint('BgAudio: Stop error: $e');
        }
        isBroadcasting = false;
      }
    });
  });

  // Listen for stop command
  service.on('stopWatching').listen((_) async {
    debugPrint('BgAudio: Stop watching');
    await firestoreSubscription?.cancel();
    await locationSubscription?.cancel();
    firestoreSubscription = null;
    locationSubscription = null;
    watchingUid = null;
    if (isBroadcasting) {
      try {
        await engine?.leaveChannel();
        await engine?.enableLocalAudio(false);
      } catch (_) {}
      isBroadcasting = false;
    }
  });

  // Listen for stop service command
  service.on('stopService').listen((_) async {
    debugPrint('BgAudio: Stopping service');
    await firestoreSubscription?.cancel();
    await locationSubscription?.cancel();
    if (isBroadcasting) {
      try {
        await engine?.leaveChannel();
      } catch (_) {}
    }
    try {
      engine?.release();
    } catch (_) {}
    engine = null;
    service.stopSelf();
  });
}

/// Start background location tracking and write to Firestore
StreamSubscription<Position> _startLocationTracking(String uid) {
  const settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  return Geolocator.getPositionStream(locationSettings: settings).listen(
    (Position position) async {
      try {
        final db = FirebaseFirestore.instance;
        await db.collection('users').doc(uid).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        debugPrint(
          'BgLocation: Updated ${position.latitude}, ${position.longitude}',
        );
      } catch (e) {
        debugPrint('BgLocation: Update failed: $e');
      }
    },
    onError: (e) {
      debugPrint('BgLocation: Stream error: $e');
    },
  );
}

/// Initialize Agora engine and join channel as broadcaster
Future<RtcEngine?> _initAndBroadcast(
  RtcEngine? existing,
  String channelId,
) async {
  RtcEngine? engine = existing;

  try {
    // Initialize engine if not already done
    if (engine == null) {
      engine = createAgoraRtcEngine();
      await engine.initialize(
        const RtcEngineContext(
          appId: AppConstants.agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
      await engine.enableAudio();
      await engine.disableVideo();
      await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQuality,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
      await engine.setDefaultAudioRouteToSpeakerphone(true);

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint(
              'BgAudio: Joined channel ${connection.channelId} in ${elapsed}ms',
            );
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('BgAudio: Error $err — $msg');
          },
        ),
      );
    }

    // Leave existing channel if any
    try {
      await engine.leaveChannel();
    } catch (_) {}

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.enableLocalAudio(true);
    await engine.muteLocalVideoStream(true);

    await engine.joinChannel(
      token: '',
      channelId: channelId,
      uid: 2, // Same fixed UID as foreground
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
        publishMicrophoneTrack: true,
        publishCameraTrack: false,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    debugPrint('BgAudio: Broadcasting on channel $channelId');
    return engine;
  } catch (e) {
    debugPrint('BgAudio: Init/broadcast failed: $e');
    return engine;
  }
}
