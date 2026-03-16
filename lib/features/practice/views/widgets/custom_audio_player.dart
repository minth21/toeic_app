import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final bool autoPlay;

  const CustomAudioPlayer({
    super.key,
    required this.audioUrl,
    this.autoPlay = true,
  });

  @override
  State<CustomAudioPlayer> createState() => _CustomAudioPlayerState();
}

class _CustomAudioPlayerState extends State<CustomAudioPlayer> {
  late AudioPlayer _player;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setUrl(widget.audioUrl);
      if (widget.autoPlay) {
        _player.play();
      }
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _changeSpeed() {
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.25;
      } else if (_speed == 1.25) {
        _speed = 1.5;
      } else if (_speed == 1.5) {
        _speed = 2.0;
      } else if (_speed == 2.0) {
        _speed = 0.75;
      } else {
        _speed = 1.0;
      }
      _player.setSpeed(_speed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek Slider
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player.duration ?? Duration.zero;

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: primaryColor,
                      inactiveTrackColor: primaryColor.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: position.inMilliseconds.toDouble(),
                      max: duration.inMilliseconds.toDouble().clamp(0.0, double.infinity),
                      onChanged: (value) {
                        _player.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 8),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed Control
              TextButton(
                onPressed: _changeSpeed,
                child: Text(
                  "${_speed}x",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),

              // Seek Back 5s
              IconButton(
                icon: const Icon(Icons.replay_5_rounded),
                onPressed: () {
                  final newPos = _player.position - const Duration(seconds: 5);
                  _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),

              // Play/Pause
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      width: 48.0,
                      height: 48.0,
                      child: const CircularProgressIndicator(),
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      iconSize: 56,
                      color: primaryColor,
                      onPressed: _player.play,
                    );
                  } else if (processingState != ProcessingState.completed) {
                    return IconButton(
                      icon: const Icon(Icons.pause_circle_filled_rounded),
                      iconSize: 56,
                      color: primaryColor,
                      onPressed: _player.pause,
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(Icons.replay_circle_filled_rounded),
                      iconSize: 56,
                      color: primaryColor,
                      onPressed: () => _player.seek(Duration.zero),
                    );
                  }
                },
              ),

              // Seek Forward 5s (Optional but good UX)
              IconButton(
                icon: const Icon(Icons.forward_5_rounded),
                onPressed: () {
                  final newPos = _player.position + const Duration(seconds: 5);
                  final duration = _player.duration ?? Duration.zero;
                  _player.seek(newPos > duration ? duration : newPos);
                },
              ),

              // Volume/Mute (Optional)
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: () {
                  // Volume logic if needed
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
