// lib/screens/music_player_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/audio_processor.dart';
import '../screens/settings_page.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  List<FileSystemEntity> musicFiles = [];
  final player = AudioPlayer();
  String? currentPlayingPath;
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration? totalDuration;

  AudioProcessor? _processor;
  int rows = 14;
  int cols = 11;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _loadSettings();
    if (Platform.isAndroid) {
      requestStoragePermission();
      scanMusicFolder("/storage/emulated/0/Music");
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rows = prefs.getInt('led_rows') ?? 14;
      cols = prefs.getInt('led_cols') ?? 11;
    });
  }

  Future<void> requestStoragePermission() async {
    var status = await Permission.storage.status;
    print("Storage permission status: $status");
    if (!status.isGranted) await Permission.storage.request();
  }

  Future<void> scanMusicFolder(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        final files = await dir
            .list()
            .where((f) =>
        f is File &&
            (f.path.endsWith(".mp3") ||
                f.path.endsWith(".wav") ||
                f.path.endsWith(".m4a")))
            .toList();
        setState(() => musicFiles = files);
      }
    } catch (e) {
      _showMessage("Error scanning folder: $e");
    }
  }

  Future<void> pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) await scanMusicFolder(selectedDirectory);
  }

  Future<void> playMusic(String path) async {
    try {
      setState(() {
        currentPlayingPath = path;
        isPlaying = true;
      });
      await player.setFilePath(path);

      // start audio processing in background (non-blocking)
      _processor?.stopProcessing();
      _processor = AudioProcessor(sampleRate: 44100, fftSize: 1024);

      // make sure latest settings are loaded
      final prefs = await SharedPreferences.getInstance();
      final curCols = prefs.getInt('led_cols') ?? cols;
      final curRows = prefs.getInt('led_rows') ?? rows;
      // we only need cols for banding; rows used later for scaling if needed
      debugPrint('Starting processor with $curRows rows x $curCols cols');

      // processing runs async and prints results
      unawaited(_processor!.processFileAndPrintBands(path));

      await player.play();
    } catch (e) {
      _showMessage('Error playing music: $e');
      print("Error playing music: $e");
    }
  }

  void pauseMusic() => player.pause();

  void resumeMusic() => player.play();

  void stopMusic() {
    player.stop();
    setState(() {
      currentPlayingPath = null;
      isPlaying = false;
      currentPosition = Duration.zero;
      totalDuration = null;
    });
    _processor?.stopProcessing();
    _processor = null;
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _setupListeners() {
    player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) stopMusic();
      });
    });

    player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => currentPosition = pos);
    });
    player.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() => totalDuration = dur);
    });
  }

  Widget _buildMiniPlayer() {
    if (currentPlayingPath == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: (totalDuration != null && totalDuration!.inMilliseconds > 0)
                ? (currentPosition.inMilliseconds /
                totalDuration!.inMilliseconds)
                .clamp(0.0, 1.0)
                : 0.0,
            onChanged: (value) {
              if (totalDuration == null) return;
              final newPos = Duration(
                  milliseconds: (totalDuration!.inMilliseconds * value).toInt());
              player.seek(newPos);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentPosition.toString().split('.').first,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                totalDuration?.toString().split('.').first ?? "--:--",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  currentPlayingPath!.split(Platform.pathSeparator).last,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (isPlaying) {
                    pauseMusic();
                  } else {
                    resumeMusic();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: stopMusic,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFileTile(FileSystemEntity file) {
    String name = file.path.split(Platform.pathSeparator).last;
    bool isCurrentlySelected = (file.path == currentPlayingPath);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isCurrentlySelected ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          name,
          style: TextStyle(
              fontWeight:
              isCurrentlySelected ? FontWeight.bold : FontWeight.normal),
        ),
        leading: Icon(
          isCurrentlySelected && isPlaying
              ? Icons.pause_circle_filled
              : Icons.play_circle_fill,
          color:
          isCurrentlySelected ? Theme.of(context).colorScheme.secondary : null,
        ),
        onTap: () {
          if (isCurrentlySelected) {
            if (isPlaying) {
              pauseMusic();
            } else {
              resumeMusic();
            }
          } else {
            playMusic(file.path);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _processor?.stopProcessing();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Music Player"),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: pickFolder,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingPage()));
              await _loadSettings(); // reload saved settings
            },
          ),
        ],
      ),
      body: musicFiles.isEmpty
          ? const Center(child: Text("No music files found."))
          : ListView.builder(
        itemCount: musicFiles.length,
        itemBuilder: (context, index) => buildFileTile(musicFiles[index]),
      ),
      bottomNavigationBar: _buildMiniPlayer(),
    );
  }
}
