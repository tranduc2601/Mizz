import 'package:flutter/material.dart';
import 'chat_audio_player.dart';

void main() {
  runApp(const ChatAudioPlayerDemo());
}

class ChatAudioPlayerDemo extends StatelessWidget {
  const ChatAudioPlayerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Audio Player Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const ChatAudioPlayerDemoScreen(),
    );
  }
}

class ChatAudioPlayerDemoScreen extends StatefulWidget {
  const ChatAudioPlayerDemoScreen({super.key});

  @override
  State<ChatAudioPlayerDemoScreen> createState() =>
      _ChatAudioPlayerDemoScreenState();
}

class _ChatAudioPlayerDemoScreenState extends State<ChatAudioPlayerDemoScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('🎵 Chat Audio Player'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0D0D1A),
              Colors.teal.shade900.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                const Text(
                  'Local Audio File Player',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Select an audio file from your device',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // The ChatAudioPlayer widget
                ChatAudioPlayer(
                  primaryColor: Colors.teal,
                  backgroundColor: const Color(0xFF1E1E2E),
                  onFileSelected: (path, name) {
                    setState(() {
                      _selectedFilePath = path;
                      _selectedFileName = name;
                    });
                    debugPrint('✅ File selected: $name');
                    debugPrint('📂 Path: $path');
                  },
                ),

                const SizedBox(height: 24),

                // Info card showing selected file
                if (_selectedFilePath != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'File Loaded Successfully',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Name: $_selectedFileName',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Path: $_selectedFilePath',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Features list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✨ Features:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _featureItem('🎵 Pick audio files from device'),
                      _featureItem('▶️ Play/Pause/Stop controls'),
                      _featureItem('📊 Progress slider with seek'),
                      _featureItem('📱 Android 13+ permission handling'),
                      _featureItem('🚫 No internet required'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
      ),
    );
  }
}
