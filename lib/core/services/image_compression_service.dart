import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shirah/core/services/logger_service.dart';

/// Image Compression Service
/// Compresses images to Jpg format with reduced quality and size
/// - Quality: 50%
/// - Max Height: 1080px
/// - Format: Jpg (smaller file size, better compression)
class ImageCompressionService {
  static ImageCompressionService? _instance;

  factory ImageCompressionService() {
    _instance ??= ImageCompressionService._();
    return _instance!;
  }

  ImageCompressionService._();

  /// Compress image from gallery or camera
  /// Reduces quality, resizes to max height 1080, converts to Jpg
  Future<File> compressImage(File imageFile) async {
    try {
      LoggerService.info('🖼️ Starting image compression...');

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw 'Failed to decode image';
      }

      LoggerService.info(
        '📏 Original size: ${image.width}x${image.height} (${imageBytes.length ~/ 1024}KB)',
      );

      // Resize if height > 1080
      if (image.height > 1080) {
        final ratio = 1080 / image.height;
        final newWidth = (image.width * ratio).toInt();
        image = img.copyResize(
          image,
          width: newWidth,
          height: 1080,
          interpolation: img.Interpolation.linear,
        );
        LoggerService.info('📐 Resized to: ${image.width}x${image.height}');
      }

      // Encode as Jpg with 50% quality
      List<int> compressedBytes;
      try {
        // Try encoding with quality parameter
        compressedBytes = img.encodeJpg(image, quality: 50);
      } catch (e) {
        LoggerService.info(
          'Jpg quality parameter issue, using default encoding',
        );
        // Fallback: encode without quality parameter
        compressedBytes = img.encodeJpg(image);
      }

      LoggerService.info(
        '✅ Compressed size: ${compressedBytes.length ~/ 1024}KB',
      );

      // Save to persistent directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFile = File(
        '${appDocDir.path}/compressed_image_$timestamp.Jpg',
      );

      await compressedFile.writeAsBytes(compressedBytes);

      LoggerService.info('💾 Saved to: ${compressedFile.path}');

      return compressedFile;
    } catch (e) {
      LoggerService.error('Failed to compress image', e);
      rethrow;
    }
  }

  /// Compress multiple images (for proof submission)
  Future<List<File>> compressImages(List<File> imageFiles) async {
    try {
      final compressedFiles = <File>[];

      for (int i = 0; i < imageFiles.length; i++) {
        LoggerService.info(
          '🖼️ Compressing image ${i + 1}/${imageFiles.length}',
        );
        final compressed = await compressImage(imageFiles[i]);
        compressedFiles.add(compressed);
      }

      return compressedFiles;
    } catch (e) {
      LoggerService.error('Failed to compress images', e);
      rethrow;
    }
  }
}
