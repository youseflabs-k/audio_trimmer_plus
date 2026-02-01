import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as path;

/// Utility functions for audio trimming operations.
class AudioTrimmerUtils {
  /// Trim an audio file based on start and end time in milliseconds.
  ///
  /// Returns the path to the trimmed audio file.
  /// 
  /// Parameters:
  /// - [inputPath]: Path to the input audio file
  /// - [outputPath]: Path where the trimmed audio will be saved (optional)
  /// - [startMs]: Start time in milliseconds
  /// - [endMs]: End time in milliseconds
  ///
  /// Throws [Exception] if the trimming operation fails.
  ///
  /// Example:
  /// ```dart
  /// final outputPath = await AudioTrimmerUtils.trimAudio(
  ///   inputPath: '/path/to/input.mp3',
  ///   startMs: 5000,  // Start at 5 seconds
  ///   endMs: 15000,   // End at 15 seconds
  /// );
  /// ```
  static Future<String> trimAudio({
    required String inputPath,
    String? outputPath,
    required int startMs,
    required int endMs,
  }) async {
    // Validate input file exists
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('Input file does not exist: $inputPath');
    }

    // Validate trim range
    if (startMs < 0) {
      throw ArgumentError('Start time cannot be negative');
    }
    if (endMs <= startMs) {
      throw ArgumentError('End time must be greater than start time');
    }

    // Generate output path if not provided
    final output = outputPath ?? _generateOutputPath(inputPath);

    // Calculate duration in seconds with high precision
    final startSec = startMs / 1000.0;
    final durationSec = (endMs - startMs) / 1000.0;

    // Determine appropriate codec based on output file extension
    final outputExtension = path.extension(output).toLowerCase();
    final String codecParams;
    
    if (outputExtension == '.wav') {
      // Use PCM codec for WAV files (uncompressed, frame-accurate)
      codecParams = '-c:a pcm_s16le';
    } else if (outputExtension == '.mp3') {
      // Use libmp3lame for MP3 files
      codecParams = '-c:a libmp3lame -b:a 192k';
    } else {
      // Use AAC for other formats (m4a, aac, etc.)
      codecParams = '-c:a aac -b:a 192k';
    }

    // Build FFmpeg command for frame-accurate trimming
    // -i: input file
    // -ss: start time (after -i for accuracy)
    // -t: duration
    // -c:a: audio codec (re-encode for precision)
    // -avoid_negative_ts make_zero: avoid timestamp issues
    // -y: overwrite output file if exists
    final command = '-i "$inputPath" -ss $startSec -t $durationSec $codecParams -avoid_negative_ts make_zero -y "$output"';

    // Execute FFmpeg command
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final output = await session.getOutput();
      throw Exception('Failed to trim audio: $output');
    }

    return output;
  }

  /// Generate an output file path based on the input path.
  static String _generateOutputPath(String inputPath) {
    final dir = path.dirname(inputPath);
    final filename = path.basenameWithoutExtension(inputPath);
    final extension = path.extension(inputPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    return path.join(dir, '${filename}_trimmed_$timestamp$extension');
  }
}
