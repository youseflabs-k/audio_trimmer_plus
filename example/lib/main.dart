import 'package:audio_trimmer_plus/audio_trimmer.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
  
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Trimmer Plus Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AudioTrimmerExamplePage(),
    );
  }
}

class AudioTrimmerExamplePage extends StatefulWidget {
  const AudioTrimmerExamplePage({super.key});

  @override
  State<AudioTrimmerExamplePage> createState() =>
      _AudioTrimmerExamplePageState();
}

class _AudioTrimmerExamplePageState extends State<AudioTrimmerExamplePage>
    with TickerProviderStateMixin {
  String? _audioPath;
  bool _isLoadingAudio = false;
  bool _isTrimming = false;
  int? _startMs;
  int? _endMs;
  bool _isPlaying = false;
  
  final _trimmerController = AudioTrimmerController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _trimmerController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    try {
      setState(() => _isLoadingAudio = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        
        // Use the controller's importFile method
        await _trimmerController.importFile(filePath);
        
        setState(() {
          _audioPath = filePath;
          _startMs = null;
          _endMs = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing audio: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingAudio = false);
    }
  }

  void _handleTrimRangeChanged(int startMs, int endMs) {
    setState(() {
      _startMs = startMs;
      _endMs = endMs;
    });
    debugPrint('Trim range: ${startMs}ms - ${endMs}ms');
  }

  Future<void> _trimAudio() async {
    if (_startMs == null || _endMs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trim range selected')),
      );
      return;
    }

    try {
      setState(() => _isTrimming = true);

      // Call the controller's trim function
      final trimmedFilePath = await _trimmerController.trim();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio trimmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Load the trimmed file back into the controller
        await _trimmerController.importFile(trimmedFilePath);

        setState(() {
          _audioPath = trimmedFilePath;
          _startMs = null;
          _endMs = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error trimming audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTrimming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Audio Trimmer Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: File Picker Integration
            const Text(
              'Audio Trimmer with Player',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select an audio file, trim it, and play it back.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoadingAudio
                  ? const Center(child: CircularProgressIndicator())
                  : AudioTrimWidget(
                      onTap: _pickAudio,
                      trimmerController: _trimmerController,
                      onPlayerStateChanged: (state) {
                        setState(() {
                          _isPlaying = state == PlayerState.playing;
                        });
                      },
                      config: AudioTrimmerConfig(
                        borderColor: Colors.deepPurple,
                        handleColor: Colors.deepPurple,
                        progressColor: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                      ),
                      scaleFactor: 500.0,
                      fixedWaveColor: Colors.deepPurple.withOpacity(0.2),
                      waveSpacing: 4.0,
                      onTrimRangeChanged: _handleTrimRangeChanged,
                    ),
            ),

            // Trim range info
            if (_startMs != null && _endMs != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Trim Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Start',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_startMs! / 1000).toStringAsFixed(2)}s',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'End',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_endMs! / 1000).toStringAsFixed(2)}s',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Duration',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${((_endMs! - _startMs!) / 1000).toStringAsFixed(2)}s',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Play button
            if (_audioPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_isPlaying) {
                        _trimmerController.pause();
                      } else {
                        _trimmerController.play();
                      }
                    },
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Pause' : 'Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),

            // Trim button
            if (_audioPath != null && _startMs != null && _endMs != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _isTrimming ? null : _trimAudio,
                    icon: _isTrimming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.content_cut),
                    label: Text(_isTrimming ? 'Trimming...' : 'Trim Audio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
