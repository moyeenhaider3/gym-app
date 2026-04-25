import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared/shared.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VideoCallScreen extends StatefulWidget {
  final CallRequest callRequest;

  const VideoCallScreen({super.key, required this.callRequest});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> implements HMSUpdateListener {
  late HMSSDK _hmsSDK;
  final _apiService = ApiService();
  late final CallService _callService;
  late final LogService _logService;

  bool _isJoining = true;
  bool _isMicMuted = false;
  bool _isVideoOff = false;
  bool _hasLeft = false;
  bool _remotePeerLeft = false;
  String? _errorMsg;

  HMSVideoTrack? _localVideoTrack;
  HMSVideoTrack? _remoteVideoTrack;
  HMSPeer? _remotePeer;

  late final DateTime _callStartTime;
  late final String _myUserId;
  late final String _myRole;

  @override
  void initState() {
    super.initState();
    _callService = CallService(_apiService);
    _logService = LogService(_apiService);
    final settings = Hive.box('settings');
    _myUserId = settings.get('userId', defaultValue: '') as String;
    _myRole = settings.get('userRole', defaultValue: 'member') as String;
    _callStartTime = DateTime.now();
    _requestPermissionsAndJoin();
  }

  // ─── Bug 1 fix: Request permissions before SDK init ─────────────────────────

  Future<void> _requestPermissionsAndJoin() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();

    if (!cam.isGranted || !mic.isGranted) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMsg = 'Camera and microphone access is required to join the call.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera and microphone access is required.'),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    _initHMS();
  }

  Future<void> _initHMS() async {
    _hmsSDK = HMSSDK();
    await _hmsSDK.build();
    _hmsSDK.addUpdateListener(listener: this);

    try {
      final roomMeta = widget.callRequest.roomMeta!;
      final role = _myRole == 'trainer' ? roomMeta.hmsRoleTrainer : roomMeta.hmsRoleMember;

      final token = await _callService.getToken(
        userId: _myUserId,
        role: role,
        roomId: roomMeta.hmsRoomId,
      );

      final settings = Hive.box('settings');
      final userName = settings.get('userName', defaultValue: 'User') as String;

      final config = HMSConfig(authToken: token, userName: userName);
      _hmsSDK.join(config: config);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMsg = 'Failed to join: $e';
        });
      }
    }
  }

  // ─── HMSUpdateListener ──────────────────────────────────────────────────────

  @override
  void onJoin({required HMSRoom room}) {
    if (mounted) setState(() => _isJoining = false);
  }

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {}

  // ─── Bug 2 fix: Peer leaving does NOT auto-leave or disable controls ────────
  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    if (!mounted) return;
    if (!peer.isLocal) {
      if (update == HMSPeerUpdate.peerJoined) {
        setState(() {
          _remotePeer = peer;
          _remotePeerLeft = false;
        });
      } else if (update == HMSPeerUpdate.peerLeft) {
        setState(() {
          _remotePeerLeft = true;
          _remoteVideoTrack = null;
        });
        // Show snackbar but keep controls active
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${peer.name} has left the call.')),
        );
      }
    }
  }

  @override
  void onTrackUpdate({required HMSTrack track, required HMSTrackUpdate trackUpdate, required HMSPeer peer}) {
    if (!mounted) return;
    if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
      if (peer.isLocal) {
        setState(() => _localVideoTrack = trackUpdate == HMSTrackUpdate.trackRemoved ? null : track as HMSVideoTrack);
      } else {
        setState(() => _remoteVideoTrack = trackUpdate == HMSTrackUpdate.trackRemoved ? null : track as HMSVideoTrack);
      }
    }
  }

  @override
  void onRemovedFromRoom({required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer}) {
    _leaveCall(showSheet: false);
  }

  @override
  void onHMSError({required HMSException error}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.message}')),
      );
    }
  }

  @override
  void onMessage({required HMSMessage message}) {}
  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}
  @override
  void onReconnecting() {}
  @override
  void onReconnected() {}
  @override
  void onChangeTrackStateRequest({required HMSTrackChangeRequest hmsTrackChangeRequest}) {}
  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}
  @override
  void onAudioDeviceChanged({HMSAudioDevice? currentAudioDevice, List<HMSAudioDevice>? availableAudioDevice}) {}
  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}
  @override
  void onPeerListUpdate({required List<HMSPeer> addedPeers, required List<HMSPeer> removedPeers}) {}

  // ─── Controls ───────────────────────────────────────────────────────────────

  void _toggleMic() {
    _hmsSDK.toggleMicMuteState();
    setState(() => _isMicMuted = !_isMicMuted);
  }

  void _toggleVideo() {
    _hmsSDK.toggleCameraMuteState();
    setState(() => _isVideoOff = !_isVideoOff);
  }

  void _flipCamera() {
    _hmsSDK.switchCamera();
  }

  // Bug 2 fix: Both roles can leave independently — no role check
  Future<void> _leaveCall({bool showSheet = true}) async {
    if (_hasLeft) return;
    _hasLeft = true;
    await _hmsSDK.leave();

    final endTime = DateTime.now();

    // Write session log
    try {
      final log = await _logService.createLog(
        memberId: widget.callRequest.memberId,
        trainerId: widget.callRequest.trainerId,
        startedAt: _callStartTime.toIso8601String(),
        endedAt: endTime.toIso8601String(),
      );

      if (mounted && showSheet) {
        _showPostCallSheet(log);
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  // ─── Bug 3 fix: isScrollControlled + keyboard inset padding ─────────────────
  void _showPostCallSheet(SessionLog log) {
    final isMember = _myRole == 'member';
    int rating = 5;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true, // Bug 3 fix: allows sheet to resize for keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, // Bug 3 fix: shift up for keyboard
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Call Ended', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Duration: ${log.durationFormatted}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              if (isMember) ...[
                const Text('Rate this session', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                    onPressed: () => setSheetState(() => rating = i + 1),
                  )),
                ),
              ],
              const SizedBox(height: 12),
              Text(isMember ? 'Add a note (optional)' : 'Session notes', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: isMember ? 'How was the session?' : 'Training notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    try {
                      if (isMember) {
                        await _logService.updateLog(log.id, rating: rating, memberNotes: notesController.text.trim());
                      } else {
                        await _logService.updateLog(log.id, trainerNotes: notesController.text.trim());
                      }
                    } catch (_) {}
                    if (mounted) {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!_hasLeft) {
      _hmsSDK.leave();
    }
    _hmsSDK.removeUpdateListener(listener: this);
    super.dispose();
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_errorMsg!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    if (_isJoining) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Joining call...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen) — Bug 2 fix: shows "left" state if peer departed
            _remotePeerLeft
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade800,
                          child: Text(
                            _remotePeer?.name[0].toUpperCase() ?? '?',
                            style: const TextStyle(fontSize: 32, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_remotePeer?.name ?? "Participant"} has left',
                          style: const TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : _remoteVideoTrack != null
                    ? SizedBox.expand(
                        child: HMSVideoView(track: _remoteVideoTrack!),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey.shade800,
                              child: Text(
                                _remotePeer?.name[0].toUpperCase() ?? '?',
                                style: const TextStyle(fontSize: 32, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _remotePeer?.name ?? 'Waiting for other participant...',
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),

            // Local video (PiP)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _localVideoTrack != null && !_isVideoOff
                    ? HMSVideoView(track: _localVideoTrack!)
                    : Container(
                        color: Colors.grey.shade900,
                        child: Center(
                          child: Icon(Icons.videocam_off, color: Colors.grey.shade600, size: 32),
                        ),
                      ),
              ),
            ),

            // Controls bar — Bug 2 fix: always active regardless of peer state
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    icon: _isMicMuted ? Icons.mic_off : Icons.mic,
                    label: _isMicMuted ? 'Unmute' : 'Mute',
                    color: _isMicMuted ? Colors.red : Colors.white24,
                    onTap: _toggleMic,
                  ),
                  _controlButton(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    label: _isVideoOff ? 'Start' : 'Stop',
                    color: _isVideoOff ? Colors.red : Colors.white24,
                    onTap: _toggleVideo,
                  ),
                  _controlButton(
                    icon: Icons.flip_camera_ios,
                    label: 'Flip',
                    color: Colors.white24,
                    onTap: _flipCamera,
                  ),
                  _controlButton(
                    icon: Icons.call_end,
                    label: 'End',
                    color: Colors.red,
                    onTap: () => _leaveCall(),
                  ),
                ],
              ),
            ),

            // Name label for remote peer
            if (_remotePeer != null && !_remotePeerLeft)
              Positioned(
                bottom: 100,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _remotePeer!.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
