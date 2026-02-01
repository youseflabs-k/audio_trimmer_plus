import 'package:flutter/material.dart';
import 'audio_trimmer_config.dart';
import 'widgets/audio_trim_handle.dart';
import 'widgets/audio_trim_progress_fill.dart';
import 'widgets/audio_trim_tint.dart';

/// A customizable audio trimmer overlay widget that displays trim handles,
/// a tinted region, and a progress indicator.
///
/// This widget is typically used to visualize audio trimming operations,
/// showing the selected region with handles on each end and a progress
/// animation during playback.
class AudioTrimmerOverlay extends StatelessWidget {
  /// Creates an [AudioTrimmerOverlay].
  ///
  /// The [width], [height], and [progress] parameters are required.
  /// Use [config] to customize the appearance, or it will use default values.
  const AudioTrimmerOverlay({
    super.key,
    required this.width,
    required this.height,
    required this.progress,
    this.config = const AudioTrimmerConfig(),
  });

  /// The total width of the overlay widget.
  final double width;

  /// The total height of the overlay widget.
  final double height;

  /// Animation controller for the progress indicator.
  ///
  /// The value should range from 0.0 (start) to 1.0 (end) representing
  /// the playback progress within the trimmed region.
  final Animation<double> progress;

  /// Configuration for customizing the overlay appearance.
  final AudioTrimmerConfig config;

  @override
  Widget build(BuildContext context) {
    // Calculate the inner width by subtracting handle widths
    final innerWidth = (width - config.handleWidth * 2).clamp(0.0, double.infinity);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(
          color: config.borderColor,
          width: config.borderWidth,
        ),
      ),
      child: Stack(
        children: [
          // Left trim handle
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AudioTrimHandle(
              width: config.handleWidth,
              color: config.handleColor,
            ),
          ),

          // Tint overlay in the middle region
          Positioned(
            left: config.handleWidth,
            right: config.handleWidth,
            top: 0,
            bottom: 0,
            child: AudioTrimTint(color: config.tintColor),
          ),

          // Progress fill indicator
          Positioned(
            left: config.handleWidth,
            top: 0,
            bottom: 0,
            child: AudioTrimProgressFill(
              progress: progress,
              maxWidth: innerWidth,
              color: config.progressColor,
            ),
          ),

          // Right trim handle
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: AudioTrimHandle(
              width: config.handleWidth,
              color: config.handleColor,
            ),
          ),
        ],
      ),
    );
  }
}
