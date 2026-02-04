import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:flutter/foundation.dart';

class JitsiMeetService {
  static final JitsiMeetService _instance = JitsiMeetService._internal();
  static JitsiMeetService get instance => _instance;

  JitsiMeetService._internal();

  final _jitsiMeet = JitsiMeet();

  Future<void> joinMeeting({
    required String roomName,
    required String userName,
    String? userEmail,
    String? userAvatar,
    bool isAudioOnly = false,
    bool isVideoMuted = false,
    bool isAudioMuted = false,
  }) async {
    try {
      debugPrint('🚀 Joining Jitsi Meeting: $roomName as $userName');

      var options = JitsiMeetConferenceOptions(
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": isAudioMuted,
          "startWithVideoMuted": isVideoMuted,
        },
        featureFlags: {
          "unwelcome_page_enabled": false,
          "resolution": 360,
          "audio-only.enabled": isAudioOnly,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: userName,
          email: userEmail,
          avatar: userAvatar,
        ),
      );

      await _jitsiMeet.join(options);
    } catch (error) {
      debugPrint('❌ Jitsi Meet Error: $error');
      rethrow;
    }
  }

  void hangUp() {
    _jitsiMeet.hangUp();
  }
}
