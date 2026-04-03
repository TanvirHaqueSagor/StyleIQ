import 'dart:convert';
import 'dart:typed_data';

/// Utility functions for image handling — works on web and native
class ImageUtils {
  /// Maximum image size in bytes (2 MB per CLAUDE.md requirement)
  static const int maxImageSizeBytes = 2 * 1024 * 1024;

  /// Convert raw bytes to base64 string for API transmission
  static String bytesToBase64(Uint8List bytes) => base64Encode(bytes);

  /// Wrap bytes as a data URL for storage/display
  static String toDataUrl(Uint8List bytes, String name) {
    return 'data:${getMediaTypeFromName(name)};base64,${base64Encode(bytes)}';
  }

  /// Decode a data URL back to bytes
  static Uint8List dataUrlToBytes(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    return base64Decode(dataUrl.substring(comma + 1));
  }

  /// Whether a string is a data URL
  static bool isDataUrl(String url) => url.startsWith('data:');

  /// Get MIME type from file name/extension
  static String getMediaTypeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Validate image by name/extension
  static bool isValidImageName(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  /// Get file size in human-readable format
  static String getFileSizeString(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
