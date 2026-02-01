import 'package:audio_trimmer_plus/audio_trimmer.dart';
import 'package:flutter/material.dart';

/// A picker widget for audio trimming with an overlay and tap action.
///
/// This widget displays an [AudioTrimmerOverlay] with a centered add icon,
/// typically used to prompt the user to select an audio file. When tapped,
/// it triggers the provided callback to pick an audio file.
///
/// Example usage:
/// ```dart
/// AudioTrimPicker(
///   width: 300.0,
///   height: 80.0,
///   progress: myAnimationController,
///   onTap: () async {
///     // Pick audio file logic
///   },
///   iconColor: Colors.white,
///   iconBackgroundColor: Colors.black.withOpacity(0.35),
/// )
/// ```
class AudioTrimPicker extends StatelessWidget {
  /// Creates an [AudioTrimPicker].
  ///
  /// The [width], [height], [progress], and [onTap]
  /// parameters are required. Other parameters can be customized for appearance.
  const AudioTrimPicker({
    super.key,
    required this.width,
    required this.height,
    required this.progress,
    this.onTap,
    this.icon = Icons.add,
    this.iconSize = 20.0,
    this.iconColor,
    this.iconBackgroundColor,
    this.iconPadding = 5.0,
    this.config = const AudioTrimmerConfig(),
  });

  /// The width of the trim overlay.
  final double width;

  /// The height of the trim overlay.
  final double height;

  /// Animation controller for the progress indicator.
  ///
  /// The value should range from 0.0 (start) to 1.0 (end).
  final Animation<double> progress;

  /// Callback invoked when the user taps the picker.
  ///
  /// Typically used to trigger an audio file picker.
  final VoidCallback? onTap;

  /// The icon displayed in the center of the picker.
  ///
  /// Defaults to [Icons.add].
  final IconData icon;

  /// The size of the icon.
  ///
  /// Defaults to `20.0`.
  final double iconSize;

  /// The color of the icon.
  ///
  /// If not specified, defaults to white.
  final Color? iconColor;

  /// The background color of the icon container.
  ///
  /// If not specified, defaults to black with 35% opacity.
  final Color? iconBackgroundColor;

  /// The padding around the icon inside its container.
  ///
  /// Defaults to `5.0`.
  final double iconPadding;

  /// Configuration for customizing the trim overlay appearance.
  final AudioTrimmerConfig? config;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AudioTrimmerOverlay(
            width: width,
            height: height,
            progress: progress,
            config: config ?? const AudioTrimmerConfig(),
          ),
          Center(
            child: Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color:
                    iconBackgroundColor ?? Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
