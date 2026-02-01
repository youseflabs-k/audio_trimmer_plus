import 'package:flutter/material.dart';

/// A widget representing a trim handle for the audio trimmer.
///
/// This displays a vertical bar with three horizontal lines in the middle,
/// commonly used as a visual indicator for draggable trim handles.
class AudioTrimHandle extends StatelessWidget {
  /// Creates an [AudioTrimHandle].
  ///
  /// The [width] parameter is required and determines the handle width.
  /// The [color] parameter customizes the handle color.
  const AudioTrimHandle({
    super.key,
    required this.width,
    this.color = const Color(0xFFFF0080),
  });

  /// The width of the handle.
  final double width;

  /// The color of the handle.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: color,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLine(),
            SizedBox(height: width * 0.25),
            _buildLine(),
            SizedBox(height: width * 0.25),
            _buildLine(),
          ],
        ),
      ),
    );
  }

  Widget _buildLine() {
    return Container(
      width: width * 0.5,
      height: 1.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
