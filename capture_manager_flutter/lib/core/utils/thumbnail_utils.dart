import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import '../constants/app_constants.dart';

/// Port of NSImage+Thumbnail.swift.
/// Returns PNG bytes of a thumbnail that fits within [maxDimension], or null on failure.
Future<Uint8List?> generateThumbnail(
  String filePath, {
  double maxDimension = AppConstants.thumbnailMaxDimension,
}) async {
  try {
    final bytes = await File(filePath).readAsBytes();
    final source = img.decodeImage(bytes);
    if (source == null) return null;

    final scale = maxDimension /
        (source.width > source.height ? source.width : source.height);
    if (scale >= 1.0) {
      // Already small enough — encode as-is
      return Uint8List.fromList(img.encodePng(source));
    }

    final targetW = (source.width * scale).round();
    final targetH = (source.height * scale).round();
    final thumbnail = img.copyResize(
      source,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.linear,
    );
    return Uint8List.fromList(img.encodePng(thumbnail));
  } catch (_) {
    return null;
  }
}
