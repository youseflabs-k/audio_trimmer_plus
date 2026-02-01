import 'package:flutter/material.dart';

/// A widget that displays a colored tint overlay for the trimmed region.
///
/// This is typically used to visually indicate the selected/trimmed area
/// of the audio waveform.
class AudioTrimTint extends StatelessWidget {
  /// Creates an [AudioTrimTint].
  ///
  /// The [color] parameter is required and should typically be
  /// a semi-transparent color for the overlay effect.
  const AudioTrimTint({
    super.key,
    required this.color,
  });

  /// The tint color for the overlay.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
    );
  }
}
