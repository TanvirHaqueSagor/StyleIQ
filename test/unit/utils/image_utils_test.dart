import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/core/utils/image_utils.dart';

void main() {
  // Minimal valid 1×1 white JPEG bytes for testing
  final Uint8List sampleJpegBytes = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
  ]);

  group('ImageUtils.getMediaTypeFromName', () {
    test('returns image/jpeg for .jpg', () {
      expect(ImageUtils.getMediaTypeFromName('photo.jpg'), 'image/jpeg');
    });

    test('returns image/jpeg for .jpeg', () {
      expect(ImageUtils.getMediaTypeFromName('photo.jpeg'), 'image/jpeg');
    });

    test('returns image/png for .png', () {
      expect(ImageUtils.getMediaTypeFromName('image.png'), 'image/png');
    });

    test('returns image/gif for .gif', () {
      expect(ImageUtils.getMediaTypeFromName('anim.gif'), 'image/gif');
    });

    test('returns image/webp for .webp', () {
      expect(ImageUtils.getMediaTypeFromName('img.webp'), 'image/webp');
    });

    test('returns image/jpeg for unknown extension', () {
      expect(ImageUtils.getMediaTypeFromName('file.bmp'), 'image/jpeg');
    });

    test('is case-insensitive', () {
      expect(ImageUtils.getMediaTypeFromName('PHOTO.JPG'), 'image/jpeg');
      expect(ImageUtils.getMediaTypeFromName('IMAGE.PNG'), 'image/png');
    });
  });

  group('ImageUtils.toDataUrl', () {
    test('produces data: prefix', () {
      final url = ImageUtils.toDataUrl(sampleJpegBytes, 'photo.jpg');
      expect(url, startsWith('data:image/jpeg;base64,'));
    });

    test('base64 segment decodes back to original bytes', () {
      final url = ImageUtils.toDataUrl(sampleJpegBytes, 'photo.jpg');
      final b64 = url.split(',').last;
      final decoded = base64Decode(b64);
      expect(decoded, equals(sampleJpegBytes));
    });

    test('uses correct media type for PNG', () {
      final url = ImageUtils.toDataUrl(sampleJpegBytes, 'image.png');
      expect(url, startsWith('data:image/png;base64,'));
    });
  });

  group('ImageUtils.isDataUrl', () {
    test('returns true for valid data URL', () {
      final url = ImageUtils.toDataUrl(sampleJpegBytes, 'photo.jpg');
      expect(ImageUtils.isDataUrl(url), isTrue);
    });

    test('returns false for regular URL', () {
      expect(ImageUtils.isDataUrl('https://example.com/image.jpg'), isFalse);
    });

    test('returns false for empty string', () {
      expect(ImageUtils.isDataUrl(''), isFalse);
    });

    test('returns false for file path', () {
      expect(ImageUtils.isDataUrl('/Users/photos/img.jpg'), isFalse);
    });
  });

  group('ImageUtils.dataUrlToBytes', () {
    test('round-trips: toDataUrl → dataUrlToBytes', () {
      final url = ImageUtils.toDataUrl(sampleJpegBytes, 'photo.jpg');
      final bytes = ImageUtils.dataUrlToBytes(url);
      expect(bytes, equals(sampleJpegBytes));
    });

    test('handles PNG data URL', () {
      final url = ImageUtils.toDataUrl(sampleJpegBytes, 'img.png');
      final bytes = ImageUtils.dataUrlToBytes(url);
      expect(bytes, equals(sampleJpegBytes));
    });
  });

  group('ImageUtils.isValidImageName', () {
    test('returns true for .jpg', () {
      expect(ImageUtils.isValidImageName('photo.jpg'), isTrue);
    });

    test('returns true for .png', () {
      expect(ImageUtils.isValidImageName('img.png'), isTrue);
    });

    test('returns true for .webp', () {
      expect(ImageUtils.isValidImageName('img.webp'), isTrue);
    });

    test('returns false for .pdf', () {
      expect(ImageUtils.isValidImageName('doc.pdf'), isFalse);
    });

    test('returns false for no extension', () {
      expect(ImageUtils.isValidImageName('noextension'), isFalse);
    });

    test('returns false for empty string', () {
      expect(ImageUtils.isValidImageName(''), isFalse);
    });
  });

  group('ImageUtils.bytesToBase64', () {
    test('produces valid base64 string', () {
      final b64 = ImageUtils.bytesToBase64(sampleJpegBytes);
      expect(() => base64Decode(b64), returnsNormally);
    });

    test('round-trips with base64Decode', () {
      final b64 = ImageUtils.bytesToBase64(sampleJpegBytes);
      expect(base64Decode(b64), equals(sampleJpegBytes));
    });
  });
}
