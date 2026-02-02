import 'dart:async';
import 'package:audio_trimmer_plus/audio_trimmer_plus.dart';
import 'package:audio_trimmer_plus/src/audio_trim_waveform_panel.dart';
import 'package:audio_trimmer_plus/src/widgets/audio_trim_picker.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

/// A complete audio trimming widget that handles file loading, waveform display,
/// and picker UI.
///
/// This widget automatically:
/// - Shows a picker UI when no audio file is provided
/// - Loads and displays waveform when an audio file path is provided
/// - Handles waveform extraction with automatic sample calculation
/// - Manages scroll position and trim window calculations
/// - Provides callbacks for file selection and scroll events
///
/// Example usage:
/// ```dart
/// AudioTrimWidget(
///   audioPath: selectedFilePath,
///   onPickAudio: () async {
///     // Show file picker
///   },
///   onTrimRangeChanged: (start, end) {
///     print('Trim range: $start - $end ms');
///   },
///   trimWindowMs: 15000.0,
///   availableWidth: 320.0,
/// )
/// ```
class AudioTrimWidget extends StatefulWidget {
  /// Creates an [AudioTrimWidget].
  ///
  /// The [onTap] callback is required for the picker UI.
  /// When [audioPath] is null, the picker is shown; when provided,
  /// the waveform panel is displayed.
  const AudioTrimWidget({
    super.key,
    required this.trimmerController,
    this.onTap,
    this.progress,
    this.onTrimRangeChanged,
    this.onScrollNotification,
    this.onPlayerStateChanged,
    this.trimWindowMs = 15000.0,
    this.containerWidth,
    this.containerWidthFraction = 0.70,
    this.waveformHeight = 80.0,
    this.waveSpacing = 6.0,
    this.scaleFactor = 75.0,
    this.pickerIcon = Icons.add,
    this.pickerIconSize = 20.0,
    this.pickerIconColor,
    this.pickerIconBackgroundColor,
    this.fixedWaveColor,
    this.config,
    this.showLoading = true,
    this.loadingWidget,
    this.autoExtractWaveform = true,
  });

  /// Callback invoked when the user taps the picker.
  ///
  /// Use this to show a file picker dialog.
  final VoidCallback? onTap;

  /// Optional animation controller for progress. If not provided, one is created internally.
  final Animation<double>? progress;

  /// Optional controller for external playback control.
  ///
  /// Use this to trigger play/pause from outside the widget.
  /// Example:
  /// ```dart
  /// final controller = AudioTrimmerController();
  /// controller.play(); // Triggers playback
  /// controller.pause(); // Pauses playback
  /// ```
  final AudioTrimmerController trimmerController;

  /// Callback invoked when the trim range changes (in milliseconds).
  ///
  /// Called during scrolling with the new start and end positions.
  final void Function(int startMs, int endMs)? onTrimRangeChanged;

  /// Optional callback for scroll notifications.
  final bool Function(ScrollNotification notification)? onScrollNotification;

  /// Callback invoked when the player state changes.
  final void Function(PlayerState state)? onPlayerStateChanged;

  /// The duration of the trim window in milliseconds.
  ///
  /// Defaults to 15000 ms (15 seconds).
  final double trimWindowMs;

  /// The width of the container (trim overlay and visible region).
  ///
  /// If not provided, calculated as [availableWidth] * [containerWidthFraction].
  final double? containerWidth;

  /// The height of the waveform display.
  ///
  /// Defaults to 80.0.
  final double waveformHeight;

  /// The fraction of available width used for the container.
  ///
  /// Only used when [containerWidth] is not provided.
  /// Defaults to 0.70 (70% of available width).
  final double containerWidthFraction;

  /// The spacing between waveform bars.
  ///
  /// Defaults to 6.0.
  final double waveSpacing;

  /// The scale factor for waveform amplitude.
  ///
  /// Defaults to 75.0.
  final double scaleFactor;

  /// The icon for the picker UI.
  ///
  /// Defaults to [Icons.add].
  final IconData pickerIcon;

  /// The size of the picker icon.
  ///
  /// Defaults to 20.0.
  final double pickerIconSize;

  /// The color of the picker icon.
  final Color? pickerIconColor;

  /// The background color of the picker icon container.
  final Color? pickerIconBackgroundColor;

  /// The color of the unplayed waveform.
  final Color? fixedWaveColor;

  /// Configuration for the trim overlay appearance.
  final AudioTrimmerConfig? config;

  /// Whether to show a loading indicator while extracting waveform.
  ///
  /// Defaults to true.
  final bool showLoading;

  /// Custom loading widget. If not provided, uses [CircularProgressIndicator].
  final Widget? loadingWidget;

  /// Whether to automatically extract waveform data.
  ///
  /// Defaults to true. Set to false if you want to prepare the player manually.
  final bool autoExtractWaveform;

  @override
  State<AudioTrimWidget> createState() => _AudioTrimWidgetState();
}

class _AudioTrimWidgetState extends State<AudioTrimWidget>
    with SingleTickerProviderStateMixin {
  late PlayerController _playerController;
  late final ScrollController _scrollController;
  late final AnimationController _internalProgressController;

  bool _isLoadingWaveform = false;
  bool _isPlaying = false;
  double _durationMs = 0.0;
  int _currentTrimStartMs = 0;
  int? _currentTrimEndMs;
  Timer? _endStopTimer;
  bool get _isProgressInternal => widget.progress == null;

  Animation<double> get _progress =>
      widget.progress ?? _internalProgressController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _internalProgressController = AnimationController(vsync: this, value: 0);
    _intializePlayer();
    
    // Listen to trimmer controller commands
    widget.trimmerController.onPlayPauseCommand.listen((shouldPlay) {
      if (!mounted) return;
      togglePlayPause();
    });

    // Listen to file import commands
    widget.trimmerController.onFileImport.listen((filePath) {
      if (!mounted) return;
      _intializePlayer();
      _loadWaveform(filePath);
    });
  
  }
  void _intializePlayer() async {
    _playerController = PlayerController();
    _playerController.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final isPlaying = state == PlayerState.playing;
      setState(() {
        _isPlaying = isPlaying;
      });
      
      if (!isPlaying) {
        _stopEndWatcher();
        _internalProgressController.stop();
        _internalProgressController.value = 0.0;
      }
    });

    if (widget.onPlayerStateChanged != null) {
      _playerController.onPlayerStateChanged
          .listen(widget.onPlayerStateChanged);
    }
  }

  @override
  void dispose() {
    _stopEndWatcher();
    if (_isProgressInternal) {
      _internalProgressController.dispose();
    }
    _playerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _stopEndWatcher() {
    _endStopTimer?.cancel();
    _endStopTimer = null;
  }

  void _startEndWatcher() {
    _stopEndWatcher();
    _endStopTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      if (!mounted || !_isPlaying) return;

      final endMs = _currentTrimEndMs;
      if (endMs == null) return;

      final current = await _playerController.getDuration(DurationType.current);
      final currentMs = current.toInt();

      if (currentMs >= endMs) {
        _stopEndWatcher();
        await _playerController.pausePlayer();
        await _playerController.seekTo(endMs);
        _internalProgressController
          ..stop()
          ..value = 1.0;
      }
    });
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      _stopEndWatcher();
      _internalProgressController
        ..stop()
        ..value = 0.0;
      await _playerController.pausePlayer();
      return;
    }

    // Validate that audio is ready before playing
    final maxDuration = await _playerController.getDuration(DurationType.max);
    if (maxDuration <= 0) {
      await _loadWaveform(widget.trimmerController.currentFilePath!);
    }

    await _playerController.seekTo(_currentTrimStartMs);
    await _playerController.startPlayer();
    _startEndWatcher();

    // Ensure valid duration before setting animation
    _internalProgressController
      ..stop()
      ..value = 0.0
      ..duration = Duration(milliseconds: widget.trimWindowMs.round());
    _internalProgressController.forward(from: 0.0);
  }

  Future<void> _loadWaveform(String path) async {
    if (!mounted) return;

    setState(() {
      _isLoadingWaveform = true;
    });

    // Get screen width before any async operations
    final screenWidth = MediaQuery.of(context).size.width;

    try {
      // 1) Prepare without waveform extraction to get duration first
      await _playerController.preparePlayer(
        path: path,
        shouldExtractWaveform: false,
      );

      final duration = await _playerController.getDuration(DurationType.max);
      final durationMs = duration.toDouble();

      if (mounted) {
        setState(() {
          _durationMs = durationMs;
          _currentTrimStartMs = 0;
        });
      }

      if (widget.autoExtractWaveform) {
        // 2) Calculate waveform sample count based on dimensions
        // Use the same calculation as build() for consistency
        final containerWidth = widget.containerWidth ??
            (screenWidth * widget.containerWidthFraction) - (widget.config?.handleWidth ?? 8.0) * 2;
        final totalWaveformWidth =
            (durationMs / widget.trimWindowMs) * (containerWidth);

        // One sample per bar spacing
        final samplesNeeded =
            (totalWaveformWidth / widget.waveSpacing).round();

        // 3) Prepare again with waveform extraction
        await _playerController.preparePlayer(
          path: path,
          shouldExtractWaveform: true,
          noOfSamples: samplesNeeded,
        );
        _playerController.setFinishMode(finishMode: FinishMode.pause);
      }


      // 4) Set initial trim range
      final endMs =
          durationMs < widget.trimWindowMs ? durationMs : widget.trimWindowMs;
      
      // Update controller's trim range
      widget.trimmerController.updateTrimRange(0, endMs.round(), trimDurationMs: widget.trimWindowMs.round());
      
      if (widget.onTrimRangeChanged != null) {
        widget.onTrimRangeChanged!(0, endMs.round());
      }

      await _playerController.seekTo(0);

      // Reset scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } catch (e) {
      debugPrint('Error loading waveform: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWaveform = false;
        });
      }
    }
  }

    void _pausePlaybackForUserScroll() {
    _stopEndWatcher();
    _internalProgressController
      ..stop()
      ..value = 0.0;
    if (!_isPlaying) return;
    _playerController.pausePlayer();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final maxWidth = MediaQuery.of(context).size.width;

    // Call user's callback first
    final userHandled =
        widget.onScrollNotification?.call(notification) ?? false;
    if(notification is! ScrollStartNotification && 
       notification is! ScrollUpdateNotification) {
      _pausePlaybackForUserScroll();
    }
    // Handle trim range updates
    if (notification is ScrollUpdateNotification) {
      // We can't access constraints here, so we need to store them
      // For now, use the containerWidth directly if provided
      // The trim range calculation doesn't strictly need the screen width
      final containerWidth =
          widget.containerWidth ?? (maxWidth * widget.containerWidthFraction) - (widget.config?.handleWidth ?? 8.0) * 2;
      if (containerWidth > 0) {
        final totalWaveformWidth =
            (_durationMs / widget.trimWindowMs) * (containerWidth);
        final msPerPixel = _durationMs / totalWaveformWidth;

        final contentScrollPx = notification.metrics.pixels;
        final scrolledMs = contentScrollPx * msPerPixel;
        final startMs = scrolledMs.floor();
        final endMs =
            (startMs + widget.trimWindowMs).clamp(0.0, _durationMs).round();

        _currentTrimStartMs = startMs;

        // Update controller's trim range
        widget.trimmerController.updateTrimRange(startMs, endMs, trimDurationMs: widget.trimWindowMs.round());

        if (widget.onTrimRangeChanged != null) {
          widget.onTrimRangeChanged!(startMs, endMs);
        }
      }
    }

    if (notification is ScrollEndNotification) {
      _playerController.seekTo(_currentTrimStartMs);
    }

    return userHandled;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final maxWidth = MediaQuery.of(context).size.width;
        final containerWidth =
            widget.containerWidth ?? (maxWidth * widget.containerWidthFraction);
        final leftPaddingPx = (availableWidth - containerWidth) / 2 +
            (widget.config?.handleWidth ?? 8.0);

        // Show picker if no audio path
        if (widget.trimmerController.currentFilePath == null) {
          return AudioTrimPicker(
              width: containerWidth,
              height: widget.waveformHeight,
              progress: _progress,
              onTap: widget.onTap,
              icon: widget.pickerIcon,
              iconSize: widget.pickerIconSize,
              iconColor: widget.pickerIconColor,
              iconBackgroundColor: widget.pickerIconBackgroundColor,
              config: widget.config
          );
        }

        // Show loading indicator
        if (_isLoadingWaveform && widget.showLoading) {
          return widget.loadingWidget ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        final maxDurationMs = _durationMs > 0
            ? _durationMs
            : _playerController.maxDuration.toDouble();

        final totalWaveformWidth =
            (maxDurationMs / widget.trimWindowMs) * (containerWidth - (widget.config?.handleWidth ?? 8.0) * 2);

        // Calculate current trim end
        final trimEndMs = (_currentTrimStartMs + widget.trimWindowMs)
            .clamp(0.0, maxDurationMs<0 ? 0.0 : maxDurationMs)
            .round();
        
        // Store for toggle playback
        _currentTrimEndMs = trimEndMs;

        return AudioTrimWaveformPanel(
          playerController: _playerController,
          scrollController: _scrollController,
          availableWidth: availableWidth,
          containerWidth: containerWidth,
          waveformHeight: widget.waveformHeight,
          totalWaveformWidth: totalWaveformWidth,
          leftPaddingPx: leftPaddingPx,
          trimStartMs: _currentTrimStartMs,
          trimEndMs: trimEndMs,
          progress: _internalProgressController,
          onScrollNotification: _handleScrollNotification,
          fixedWaveColor: widget.fixedWaveColor,
          waveSpacing: widget.waveSpacing,
          scaleFactor: widget.scaleFactor,
          config: widget.config ?? const AudioTrimmerConfig(),
        );
      },
    );
  }
}
