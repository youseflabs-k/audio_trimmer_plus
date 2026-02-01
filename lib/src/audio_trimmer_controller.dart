import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'audio_trimmer_utils.dart';

/// Controller for managing audio playback and trimming operations.
///
/// Use this controller to control playback from outside the widget.
/// The controller notifies listeners when play or pause is requested.
///
/// Example usage:
/// ```dart
/// final controller = AudioTrimmerController();
///
/// // Listen to play/pause commands
/// controller.onPlayPauseCommand.listen((shouldPlay) {
///   if (shouldPlay) {
///     print('Play requested');
///   } else {
///     print('Pause requested');
///   }
/// });
///
/// // Trigger play
/// controller.play();
///
/// // Trigger pause
/// controller.pause();
///
/// // Import audio file
/// await controller.importFile('/path/to/audio.mp3');
/// ```
class AudioTrimmerController {
  final StreamController<bool> _playPauseController =
      StreamController<bool>.broadcast();
  final StreamController<String> _fileImportController =
      StreamController<String>.broadcast();

  String? _currentFilePath;
  int _startMs = 0;
  int _endMs = 0;
  int _trimDurationMs = 0;

  /// Get the current trim start position in milliseconds.
  int get startMs => _startMs;

  /// Get the current trim end position in milliseconds.
  int get endMs => _endMs;

  /// Get the current trim duration in milliseconds.
  int get trimDurationMs => _trimDurationMs;

  /// Get the current audio file path.
  String? get currentFilePath => _currentFilePath;

  /// Stream that emits `true` when play is requested, `false` when pause is requested.
  Stream<bool> get onPlayPauseCommand => _playPauseController.stream;

  /// Stream that emits the audio file path when a file is imported.
  Stream<String> get onFileImport => _fileImportController.stream;

  /// Request to start playback.
  void play() {
    if (!_playPauseController.isClosed) {
      _playPauseController.add(true);
    }
  }

  /// Request to pause playback.
  void pause() {
    if (!_playPauseController.isClosed) {
      _playPauseController.add(false);
    }
  }

  /// Toggle between play and pause.
  ///
  /// If currently playing, this will pause. If paused, this will play.
  /// Note: The actual playing state is maintained by [AudioTrimWaveformPanel].
  /// This method will always trigger a play command. Use with caution or track
  /// the state externally.
  void toggle() {
    // This is a simple toggle that always requests play.
    // The actual state tracking should be done by listening to the player controller.
    play();
  }

  /// Update the trim range.
  ///
  /// Call this method to update the internal trim start and end positions.
  /// These values will be used when calling [trim()].
  ///
  /// Example:
  /// ```dart
  /// controller.updateTrimRange(5000, 15000); // Trim from 5s to 15s
  /// ```
  void updateTrimRange(int startMs, int endMs, {int? trimDurationMs}) {
    _startMs = startMs;
    _endMs = endMs;
    if (trimDurationMs != null) {
      _trimDurationMs = trimDurationMs;
    } else {
      _trimDurationMs = endMs - startMs;
    }
  }

  /// Import an audio file and load it into the widget.
  ///
  /// Validates the file exists and has a supported audio extension before loading.
  /// Supported extensions: .mp3, .wav, .m4a, .aac, .flac, .ogg, .opus
  ///
  /// Throws [FileSystemException] if the file doesn't exist.
  /// Throws [FormatException] if the file extension is not supported.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await controller.importFile('/path/to/audio.mp3');
  /// } catch (e) {
  ///   print('Error importing file: $e');
  /// }
  /// ```
  Future<void> importFile(String filePath) async {
    // Validate file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException(
        'Audio file does not exist',
        filePath,
      );
    }

    // Validate file extension
    final extension = filePath.toLowerCase().split('.').last;
    const supportedExtensions = [
      'mp3',
      'wav',
      'm4a',
      'aac',
      'flac',
      'ogg',
      'opus',
    ];

    if (!supportedExtensions.contains(extension)) {
      throw FormatException(
        'Unsupported audio format: .$extension. Supported formats: ${supportedExtensions.join(', ')}',
        filePath,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Emit the file path for the widget to load
      if (!_fileImportController.isClosed) {
        _fileImportController.add(filePath);
      }
    });
    
    _currentFilePath = filePath;
  }

  /// Trim the currently loaded audio file using the current trim range.
  ///
  /// Returns the path to the trimmed audio file.
  ///
  /// Throws [StateError] if no file has been imported.
  /// Throws [StateError] if trim range is invalid (end <= start).
  /// Throws [Exception] if the trimming operation fails.
  ///
  /// Parameters:
  /// - [outputPath]: Optional custom output path for the trimmed file.
  ///   If not provided, a default path will be generated.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   // Import file
  ///   await controller.importFile('/path/to/audio.mp3');
  ///   
  ///   // Update trim range (5s to 15s)
  ///   controller.updateTrimRange(5000, 15000);
  ///   
  ///   // Trim the audio
  ///   final outputPath = await controller.trim();
  ///   print('Trimmed audio saved to: $outputPath');
  /// } catch (e) {
  ///   print('Error: $e');
  /// }
  /// ```
  Future<String> trim({String? outputPath}) async {
    if (_currentFilePath == null) {
      throw StateError('No audio file has been imported. Call importFile() first.');
    }

    if (_endMs <= _startMs) {
      throw StateError('Invalid trim range: end ($_endMs ms) must be greater than start ($_startMs ms)');
    }

    return await AudioTrimmerUtils.trimAudio(
      inputPath: _currentFilePath!,
      outputPath: outputPath,
      startMs: _startMs,
      endMs: _startMs + _trimDurationMs,
    );
  }

  /// Dispose of this controller and close the stream.
  void dispose() {
    _playPauseController.close();
    _fileImportController.close();
  }
}
