import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Displays image bytes at their natural aspect ratio with no black bars.
/// Width always fills available space; height adapts to the image dimensions.
class PhotoPreview extends StatelessWidget {
  final Uint8List bytes;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const PhotoPreview({
    super.key,
    required this.bytes,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}
