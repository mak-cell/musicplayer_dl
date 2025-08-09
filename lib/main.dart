import 'package:flutter/material.dart';
import 'screens/music_player_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          secondary: Colors.orangeAccent,
        ),
      ),
      home: MusicPlayerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
