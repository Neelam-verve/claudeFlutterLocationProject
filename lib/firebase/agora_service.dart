import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/app_constants.dart';

class AgoraService extends GetxService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isBroadcasting = false;
  bool _isListening = false;
  String? _currentChannel;

  bool get isBroadcasting => _isBroadcasting;
  bool get isListening => _isListening;

  Future<void> initAgora() async {
    if (_isInitialized) return;

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: AppConstants.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Audio only — no video
      await _engine!.enableAudio();
      await _engine!.disableVideo();
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQuality,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
      // Keep audio active even when speaker is default route
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);
    } catch (e) {
      debugPrint('Agora: Init failed: $e');
      _engine = null;
      return;
    }

    // Event handlers
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint(
            'Agora: Joined channel ${connection.channelId} (uid=${connection.localUid}) in ${elapsed}ms');
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint('Agora: Remote user $remoteUid joined');
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        debugPrint('Agora: Remote user $remoteUid went offline: $reason');
      },
      onError: (ErrorCodeType err, String msg) {
        debugPrint('Agora: Error $err — $msg');
      },
      onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid,
          RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
        debugPrint(
            'Agora: Remote audio uid=$remoteUid state=$state reason=$reason');
      },
      onConnectionStateChanged: (RtcConnection connection,
          ConnectionStateType state, ConnectionChangedReasonType reason) {
        debugPrint('Agora: Connection state=$state reason=$reason');
      },
    ));

    _isInitialized = true;
    debugPrint('Agora: Engine initialized');
  }

  /// Child side — broadcast mic audio (uid=2)
  Future<void> startBroadcasting(String channelId) async {
    if (_isBroadcasting) return;
    if (!_isInitialized) await initAgora();
    if (_engine == null) return;

    // If already in a channel, leave first
    if (_currentChannel != null) {
      await _engine?.leaveChannel();
      _currentChannel = null;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('Agora: Microphone permission denied');
      return;
    }

    try {
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableLocalAudio(true);
      await _engine!.muteLocalVideoStream(true);

      await _engine!.joinChannel(
        token: '',
        channelId: channelId,
        uid: 2, // Fixed UID for child
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
          publishMicrophoneTrack: true,
          publishCameraTrack: false,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      _currentChannel = channelId;
      _isBroadcasting = true;
      debugPrint('Agora: Broadcasting started on channel $channelId');
    } catch (e) {
      debugPrint('Agora: startBroadcasting failed: $e');
    }
  }

  /// Admin side — listen to child's audio (uid=1)
  Future<void> startListening(String channelId) async {
    if (_isListening) return;
    if (!_isInitialized) await initAgora();
    if (_engine == null) return;

    // If already in a channel, leave first
    if (_currentChannel != null) {
      await _engine?.leaveChannel();
      _currentChannel = null;
    }

    try {
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      await _engine!.joinChannel(
        token: '',
        channelId: channelId,
        uid: 1, // Fixed UID for admin
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
          publishMicrophoneTrack: false,
          publishCameraTrack: false,
          clientRoleType: ClientRoleType.clientRoleAudience,
        ),
      );

      _currentChannel = channelId;
      _isListening = true;
      debugPrint('Agora: Listening started on channel $channelId');
    } catch (e) {
      debugPrint('Agora: startListening failed: $e');
    }
  }

  /// Child side — stop broadcasting
  Future<void> stopBroadcasting() async {
    if (!_isBroadcasting) return;

    try {
      await _engine?.leaveChannel();
      await _engine?.enableLocalAudio(false);
    } catch (e) {
      debugPrint('Agora: stopBroadcasting error: $e');
    }
    _currentChannel = null;
    _isBroadcasting = false;
    debugPrint('Agora: Broadcasting stopped');
  }

  /// Admin side — stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _engine?.leaveChannel();
    } catch (e) {
      debugPrint('Agora: stopListening error: $e');
    }
    _currentChannel = null;
    _isListening = false;
    debugPrint('Agora: Listening stopped');
  }

  @override
  void onClose() {
    _engine?.leaveChannel();
    _engine?.release();
    _engine = null;
    _isInitialized = false;
    _isBroadcasting = false;
    _isListening = false;
    _currentChannel = null;
    super.onClose();
  }
}
