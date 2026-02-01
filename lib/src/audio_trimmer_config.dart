import 'package:flutter/material.dart';

/// Configuration class for customizing the audio trimmer overlay appearance.
class AudioTrimmerConfig {
  /// Creates an [AudioTrimmerConfig] with customizable parameters.
  const AudioTrimmerConfig({
    this.borderColor = const Color(0xFFFF0080),
    this.borderWidth = 3.0,
    this.borderRadius = 10.0,
    this.tintColor = const Color(0x1AFF0080),
    this.handleColor = const Color(0xFFFF0080),
    this.handleWidth = 8.0,
    this.progressColor = const Color(0x80FF0080),
  });

  /// The color of the border around the trim overlay.
  final Color borderColor;

  /// The width of the border stroke.
  final double borderWidth;

  /// The border radius for rounded corners.
  final double borderRadius;

  /// The tint color overlay on the trim region.
  final Color tintColor;

  /// The color of the trim handles.
  final Color handleColor;

  /// The width of each trim handle.
  final double handleWidth;

  /// The color of the progress fill indicator.
  final Color progressColor;

  /// Creates a copy of this config with the given fields replaced.
  AudioTrimmerConfig copyWith({
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    Color? tintColor,
    Color? handleColor,
    double? handleWidth,
    Color? progressColor,
  }) {
    return AudioTrimmerConfig(
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      tintColor: tintColor ?? this.tintColor,
      handleColor: handleColor ?? this.handleColor,
      handleWidth: handleWidth ?? this.handleWidth,
      progressColor: progressColor ?? this.progressColor,
    );
  }
}
