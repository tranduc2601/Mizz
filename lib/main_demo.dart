import 'package:flutter/material.dart';
import 'examples/smart_audio_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mizz Audio Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SmartAudioDemo(),
    );
  }
}
