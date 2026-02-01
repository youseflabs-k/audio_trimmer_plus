import 'package:audio_trimmer_plus/audio_trimmer_plus.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

/// A customizable audio waveform panel with trimming overlay and playback controls.
///
/// This widget combines an audio waveform visualization with a trim overlay,
/// providing a complete solution for audio trimming UI with built-in playback.
/// It includes:
/// - Scrollable waveform visualization using [AudioFileWaveforms]
/// - Customizable trim overlay with handles and progress indicator
/// - Built-in play/pause functionality with progress sync
/// - Automatic playback stop at trim end position
///
/// Example usage:
/// ```dart
/// AudioTrimWaveformPanel(
///   playerController: myPlayerController,
///   scrollController: myScrollController,
///   availableWidth: 320.0,
///   containerWidth: 300.0,
///   waveformHeight: 80.0,
///   totalWaveformWidth: 600.0,
///   leftPaddingPx: 10.0,
///   trimStartMs: 0,
///   trimEndMs: 15000,
///   onPlay: () => print('Playing'),
///   onPause: () => print('Paused'),
/// )
/// ```
class AudioTrimWaveformPanel extends StatefulWidget {
  /// Creates an [AudioTrimWaveformPanel].
  ///
  /// All size and dimension parameters are required to ensure proper layout.
  /// Waveform appearance can be customized through optional parameters.
  const AudioTrimWaveformPanel({
    super.key,
    required this.playerController,
    required this.scrollController,
    required this.availableWidth,
    required this.containerWidth,
    required this.waveformHeight,
    required this.totalWaveformWidth,
    required this.leftPaddingPx,
    required this.progress,
    this.trimStartMs = 0,
    this.trimEndMs,
    this.onPlay,
    this.onPause,
    this.onScrollNotification,
    this.waveformType = WaveformType.fitWidth,
    this.enableSeekGesture = false,
    this.fixedWaveColor,
    this.waveSpacing = 6.0,
    this.showSeekLine = false,
    this.scaleFactor = 75.0,
    this.scrollPhysics,
    this.overlayAlignment = Alignment.center,
    this.config = const AudioTrimmerConfig(),
  });

  /// The player controller from audio_waveforms package.
  ///
  /// Controls the audio playback and manages the waveform data.
  final PlayerController playerController;

  /// The scroll controller for horizontal waveform scrolling.
  final ScrollController scrollController;

  /// The total available width for the panel.
  ///
  /// This is the width constraint for the entire widget.
  final double availableWidth;

  /// The width of the trim overlay container.
  ///
  /// This defines the visible trim region width.
  final double containerWidth;

  /// The height of the waveform and overlay.
  final double waveformHeight;

  /// The total width of the waveform.
  ///
  /// This is usually larger than [availableWidth] to enable scrolling.
  final double totalWaveformWidth;

  /// The left padding in pixels for the waveform scroll view.
  ///
  /// Typically used to center the trim region at the start.
  final double leftPaddingPx;

  /// The start position of the trim in milliseconds.
  ///
  /// Defaults to 0.
  final int trimStartMs;

  /// The end position of the trim in milliseconds.
  ///
  /// If null, plays until the end of the audio.
  final int? trimEndMs;

  /// Progress animation controller from parent widget.
  ///
  /// Controls the progress indicator animation.
  final AnimationController progress;


  /// Callback invoked when playback starts.
  final VoidCallback? onPlay;

  /// Callback invoked when playback pauses or stops.
  final VoidCallback? onPause;

  /// Optional callback for scroll notifications.
  ///
  /// Called when the user scrolls the waveform. Return `true` to
  /// cancel the notification bubbling.
  final bool Function(ScrollNotification notification)? onScrollNotification;

  /// The type of waveform visualization.
  ///
  /// Defaults to [WaveformType.fitWidth] which scales the waveform
  /// to fit the specified width.
  final WaveformType waveformType;

  /// Whether to enable seek gesture on the waveform.
  ///
  /// When `true`, tapping the waveform seeks to that position.
  /// Defaults to `false`.
  final bool enableSeekGesture;

  /// The color of the unplayed (fixed) waveform.
  ///
  /// If not specified, defaults to white with 30% opacity.
  final Color? fixedWaveColor;


  /// The spacing between waveform bars.
  ///
  /// Defaults to `6.0` pixels.
  final double waveSpacing;

  /// Whether to show the seek line on the waveform.
  ///
  /// Defaults to `false`.
  final bool showSeekLine;

  /// The scale factor for the waveform amplitude.
  ///
  /// Higher values increase the visual amplitude of the waveform.
  /// Defaults to `75.0`.
  final double scaleFactor;

  /// The scroll physics for the waveform scroll view.
  ///
  /// If not specified, defaults to [BouncingScrollPhysics].
  final ScrollPhysics? scrollPhysics;

  /// The alignment of the overlay within the stack.
  ///
  /// Defaults to [Alignment.center].
  final Alignment overlayAlignment;

  /// Configuration for customizing the trim overlay appearance.
  final AudioTrimmerConfig config;

  @override
  State<AudioTrimWaveformPanel> createState() => _AudioTrimWaveformPanelState();
}

class _AudioTrimWaveformPanelState extends State<AudioTrimWaveformPanel>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.availableWidth,
      height: widget.waveformHeight,
      child: Stack(
        alignment: widget.overlayAlignment,
        children: [
          // Scrollable waveform visualization
          NotificationListener<ScrollNotification>(
            onNotification: widget.onScrollNotification ?? (_) => false,
            child: SingleChildScrollView(
              controller: widget.scrollController,
              scrollDirection: Axis.horizontal,
              physics: widget.scrollPhysics ?? const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                  left: widget.leftPaddingPx, right: widget.leftPaddingPx),
              child: AudioFileWaveforms(
                size: Size(widget.totalWaveformWidth, widget.waveformHeight),
                playerController: widget.playerController,
                waveformType: widget.waveformType,
                enableSeekGesture: widget.enableSeekGesture,
                playerWaveStyle: PlayerWaveStyle(
                  fixedWaveColor: widget.fixedWaveColor ??
                      Colors.white.withValues(alpha: 0.3),
                  liveWaveColor: widget.fixedWaveColor ??
                      Colors.white.withValues(alpha: 0.3),
                  spacing: widget.waveSpacing,
                  showSeekLine: widget.showSeekLine,
                  scaleFactor: widget.scaleFactor,
                ),
              ),
            ),
          ),
          // Trim overlay with handles and progress
          IgnorePointer(
            child: AudioTrimmerOverlay(
              width: widget.containerWidth,
              height: widget.waveformHeight,
              progress: widget.progress,
              config: widget.config
            )
          )
        ],
      ),
    );
  }
}
