import 'package:flutter/material.dart';

/// A widget that displays an animated progress fill for the audio trimmer.
///
/// This widget animates from left to right based on the [progress] animation,
/// showing the current playback position within the trimmed region.
class AudioTrimProgressFill extends StatelessWidget {
  /// Creates an [AudioTrimProgressFill].
  ///
  /// The [progress] and [maxWidth] parameters are required.
  /// The [color] parameter customizes the fill color.
  const AudioTrimProgressFill({
    super.key,
    required this.progress,
    required this.maxWidth,
    this.color = const Color(0x80FF0080),
  });

  /// Animation controller for the progress.
  ///
  /// Value ranges from 0.0 to 1.0.
  final Animation<double> progress;

  /// Maximum width the progress fill can expand to.
  final double maxWidth;

  /// The color of the progress fill.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final currentWidth = maxWidth * progress.value;
        return Container(
          width: currentWidth,
          color: color,
        );
      },
    );
  }
}
