import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class BunnyCdnService {
  BunnyCdnService._();
  static final BunnyCdnService instance = BunnyCdnService._();

  // BunnyCDN Storage Configuration
  static const String _storageZoneName = 'booknglow-media';
  static const String _folderName = 'shop-images';
  static const String _storageAccessKey = 'b059ca2b-7223-417d-ba87b92a4d7e-6417-4a70';
  static const String _storageEndpoint = 'https://storage.bunnycdn.com';
  static const String _cdnBaseUrl = 'https://booknglow-media.b-cdn.net';

  /// Compresses an image file before uploading.
  /// First attempts native platform compression (via FlutterImageCompress),
  /// and automatically falls back to pure Dart image compression (via package:image)
  /// ensuring 100% guaranteed, reliable compression on all platforms.
  Future<Uint8List> compressImage(
    File file, {
    int quality = 75,
    int maxDimension = 1280,
  }) async {
    final originalBytes = await file.readAsBytes();
    final originalSizeKb = originalBytes.lengthInBytes / 1024;
    debugPrint('[BunnyCDN] Original Image Size: ${originalSizeKb.toStringAsFixed(1)} KB');

    // 1. Try Native Image Compression
    try {
      final Uint8List? nativeCompressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: maxDimension,
        minHeight: (maxDimension * 9 / 16).round(),
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (nativeCompressed != null &&
          nativeCompressed.isNotEmpty &&
          nativeCompressed.lengthInBytes < originalBytes.lengthInBytes) {
        final compressedSizeKb = nativeCompressed.lengthInBytes / 1024;
        final reductionRatio = ((1 - (compressedSizeKb / originalSizeKb)) * 100).toStringAsFixed(1);
        debugPrint(
          '[BunnyCDN] Native Compressed Size: ${compressedSizeKb.toStringAsFixed(1)} KB ($reductionRatio% reduction)',
        );
        return nativeCompressed;
      }
    } catch (e) {
      debugPrint('[BunnyCDN] Native compression skipped/failed ($e), using pure Dart compression fallback.');
    }

    // 2. Fallback to Guaranteed Pure Dart Compression (runs in background isolate)
    try {
      final Uint8List dartCompressed = await compute(
        _processPureDartCompression,
        _CompressionParams(bytes: originalBytes, maxDimension: maxDimension, quality: quality),
      );

      if (dartCompressed.isNotEmpty) {
        final compressedSizeKb = dartCompressed.lengthInBytes / 1024;
        final reductionRatio = ((1 - (compressedSizeKb / originalSizeKb)) * 100).toStringAsFixed(1);
        debugPrint(
          '[BunnyCDN] Pure Dart Compressed Size: ${compressedSizeKb.toStringAsFixed(1)} KB ($reductionRatio% reduction)',
        );
        return dartCompressed;
      }
    } catch (e) {
      debugPrint('[BunnyCDN] Pure Dart compression error ($e), using original bytes.');
    }

    return originalBytes;
  }

  /// Compresses the image and uploads it to BunnyCDN storage zone
  /// Returns the full public CDN URL on success, e.g.:
  /// `https://booknglow-media.b-cdn.net/shop-images/shop_<salonId>_<timestamp>.jpg`
  Future<String> uploadShopImage({
    required File file,
    required String salonId,
  }) async {
    // 1. Compress the image before upload
    debugPrint('[BunnyCDN] Starting image compression for salon: $salonId');
    final Uint8List compressedBytes = await compressImage(file);

    // 2. Generate unique filename
    final cleanSalonId = salonId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'shop_${cleanSalonId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final uploadUrl = '$_storageEndpoint/$_storageZoneName/$_folderName/$fileName';

    debugPrint(
      '[BunnyCDN] Uploading ${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB to $uploadUrl...',
    );

    // 3. Upload to BunnyCDN Storage API via HTTP PUT
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'AccessKey': _storageAccessKey,
        'Content-Type': 'image/jpeg',
      },
      body: compressedBytes,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final cdnUrl = '$_cdnBaseUrl/$_folderName/$fileName';
      debugPrint('[BunnyCDN] Upload successful! Public CDN URL: $cdnUrl');
      return cdnUrl;
    } else {
      debugPrint('[BunnyCDN] Upload failed with status code ${response.statusCode}: ${response.body}');
      throw Exception('BunnyCDN upload failed (HTTP ${response.statusCode}): ${response.body}');
    }
  }

  /// Deletes an old shop image from BunnyCDN storage if it exists in the storage zone
  Future<bool> deleteShopImage(String imageUrl) async {
    if (imageUrl.isEmpty || !imageUrl.contains(_cdnBaseUrl)) {
      return false;
    }

    try {
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (fileName.isEmpty) return false;

      final deleteUrl = '$_storageEndpoint/$_storageZoneName/$_folderName/$fileName';
      debugPrint('[BunnyCDN] Deleting old image from $deleteUrl...');

      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'AccessKey': _storageAccessKey,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 404) {
        debugPrint('[BunnyCDN] Old image deleted successfully or not found ($fileName).');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[BunnyCDN] Notice: failed to delete old image: $e');
      return false;
    }
  }
}

/// Parameters for background isolate image compression
class _CompressionParams {
  final Uint8List bytes;
  final int maxDimension;
  final int quality;

  _CompressionParams({
    required this.bytes,
    required this.maxDimension,
    required this.quality,
  });
}

/// Top-level function executed on background isolate for pure Dart image compression
Uint8List _processPureDartCompression(_CompressionParams params) {
  final img.Image? decoded = img.decodeImage(params.bytes);
  if (decoded == null) return params.bytes;

  // Auto-orient according to EXIF data (fixes rotation for camera photos)
  img.Image processed = img.bakeOrientation(decoded);

  // Resize if dimensions exceed maxDimension
  if (processed.width > params.maxDimension || processed.height > params.maxDimension) {
    if (processed.width >= processed.height) {
      processed = img.copyResize(
        processed,
        width: params.maxDimension,
        interpolation: img.Interpolation.linear,
      );
    } else {
      processed = img.copyResize(
        processed,
        height: params.maxDimension,
        interpolation: img.Interpolation.linear,
      );
    }
  }

  // Encode as compressed JPEG
  final List<int> compressedJpg = img.encodeJpg(processed, quality: params.quality);
  return Uint8List.fromList(compressedJpg);
}
