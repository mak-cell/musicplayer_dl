import 'dart:io';
import 'package:flutter/material.dart';

class MusicFileTile extends StatelessWidget {
  final FileSystemEntity file;
  final String? currentPlayingPath;
  final bool isPlaying;
  final Duration? totalDuration;
  final Duration currentPosition;
  final Function(String) onPlay;
  final VoidCallback onPause;
  final VoidCallback onResume;

  MusicFileTile({
    required this.file,
    required this.currentPlayingPath,
    required this.isPlaying,
    required this.totalDuration,
    required this.currentPosition,
    required this.onPlay,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    String name = file.path.split(Platform.pathSeparator).last;
    bool isCurrent = file.path == currentPlayingPath;

    return ListTile(
      title: Text(name,
          style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
      subtitle: isCurrent && totalDuration != null
          ? Text(
          "${currentPosition.toString().split('.').first} / ${totalDuration?.toString().split('.').first ?? ''}")
          : null,
      leading: Icon(
        isCurrent && isPlaying
            ? Icons.pause_circle_filled
            : isCurrent
            ? Icons.play_circle_filled
            : Icons.audiotrack,
        color: isCurrent ? Theme.of(context).colorScheme.secondary : null,
      ),
      onTap: () {
        if (isCurrent) {
          isPlaying ? onPause() : onResume();
        } else {
          onPlay(file.path);
        }
      },
    );
  }
}
