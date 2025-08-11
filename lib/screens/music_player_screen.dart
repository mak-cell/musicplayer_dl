// lib/screens/music_player_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
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
  final List<String> _debugLogs = [];

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  List<double>? bandAmplitudes;
  StreamSubscription<List<double>>? _bandSub;
  StreamSubscription<String>? _debugSub;

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
    if (selectedDirectory != null) {
      await scanMusicFolder(selectedDirectory);
    }
  }

  Future<void> playMusic(String path) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      _processor?.stopProcessing();
      _debugLogs.clear();

      setState(() {
        currentPlayingPath = path;
        isPlaying = true;
      });

      await player.stop();
      await player.play(DeviceFileSource(path));

      _processor = AudioProcessor(sampleRate: 44100, fftSize: 1024);

      // Listen to band amplitudes
      _bandSub?.cancel();
      _bandSub = _processor!.bandStream.listen((bands) {
        setState(() {
          bandAmplitudes = bands;
        });
      });

      // Listen to debug messages
      _debugSub?.cancel();
      _debugSub = _processor!.debugStream.listen((msg) {
        setState(() {
          _debugLogs.add(msg);
        });
      });

      final prefs = await SharedPreferences.getInstance();
      final curCols = prefs.getInt('led_cols') ?? cols;
      final curRows = prefs.getInt('led_rows') ?? rows;
      debugPrint('Starting processor with $curRows rows x $curCols cols');

      unawaited(_processor!.processFileAndPrintBands(path));
    } catch (e) {
      _showMessage('Error playing music: $e');
      debugPrint("Error playing music: $e");
    }
  }

  void pauseMusic() => player.pause();
  void resumeMusic() => player.resume();
  void stopMusic() {
    player.stop();
    setState(() {
      currentPlayingPath = null;
      isPlaying = false;
      currentPosition = Duration.zero;
      totalDuration = null;
      bandAmplitudes = null;
    });
    _processor?.stopProcessing();
    _processor = null;
    _bandSub?.cancel();
    _bandSub = null;
    _debugSub?.cancel();
    _debugSub = null;
    _debugLogs.clear();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _setupListeners() {
    _positionSub = player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => currentPosition = pos);
    });
    _durationSub = player.onDurationChanged.listen((dur) {
      if (!mounted) return;
      setState(() => totalDuration = dur);
    });
    _stateSub = player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state == PlayerState.playing;
        if (state == PlayerState.completed) stopMusic();
      });
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
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _bandSub?.cancel();
    _debugSub?.cancel(); // Cancel the debug stream subscription
    player.dispose();
    super.dispose();
  }

  Widget _buildBandsUI() {
    if (bandAmplitudes == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: bandAmplitudes!
            .map((amp) => Expanded(
                  child: Container(
                    height: amp * 5, // scale for visibility
                    color: Colors.orangeAccent,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDebugLogUI() {
    return Container(
      color: Colors.grey[900],
      height: 200,
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        reverse: true, // Show the latest messages at the bottom
        itemCount: _debugLogs.length,
        itemBuilder: (context, index) {
          return Text(
            _debugLogs[_debugLogs.length - 1 - index],
            style: const TextStyle(color: Colors.white, fontSize: 10),
          );
        },
      ),
    );
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
              await _loadSettings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: musicFiles.isEmpty
                ? const Center(child: Text("No music files found."))
                : ListView.builder(
                    itemCount: musicFiles.length,
                    itemBuilder: (context, index) => buildFileTile(musicFiles[index]),
                  ),
          ),
          _buildBandsUI(),
          _buildDebugLogUI(), // <-- New widget to display the debug logs
        ],
      ),
      bottomNavigationBar: _buildMiniPlayer(),
    );
  }
}