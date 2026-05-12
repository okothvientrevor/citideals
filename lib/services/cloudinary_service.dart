import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/env.dart';

final cloudinaryServiceProvider = Provider<CloudinaryService>((_) {
  return CloudinaryService(
    cloudName: Env.cloudinaryCloudName,
    uploadPreset: Env.cloudinaryUploadPreset,
  );
});

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final int width;
  final int height;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.width,
    required this.height,
  });

  /// Inline transformation for a small thumbnail (used in cards / queues).
  String thumbnail({int width = 600}) {
    final transform = 'c_fill,w_$width,q_auto,f_auto';
    return secureUrl.replaceFirst('/upload/', '/upload/$transform/');
  }
}

class CloudinaryException implements Exception {
  final String message;
  CloudinaryException(this.message);
  @override
  String toString() => 'CloudinaryException: $message';
}

class CloudinaryService {
  CloudinaryService({required this.cloudName, required this.uploadPreset});
  final String cloudName;
  final String uploadPreset;

  Uri get _endpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  Future<CloudinaryUploadResult> uploadFile(
    File file, {
    String? folder,
    void Function(double progress)? onProgress,
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw CloudinaryException(
        'Cloudinary not configured. Set CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET via --dart-define or lib/core/env.dart.',
      );
    }

    final request = http.MultipartRequest('POST', _endpoint)
      ..fields['upload_preset'] = uploadPreset;

    if (folder != null) request.fields['folder'] = folder;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 400) {
      throw CloudinaryException(
        'Upload failed (${streamed.statusCode}): $body',
      );
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return CloudinaryUploadResult(
      secureUrl: json['secure_url'] as String,
      publicId: json['public_id'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );
  }

  /// Sequential upload — keeps memory predictable on lower-end devices.
  /// Reports overall progress (0..1) as each file completes.
  Future<List<CloudinaryUploadResult>> uploadAll(
    List<File> files, {
    String? folder,
    void Function(double progress)? onProgress,
  }) async {
    final results = <CloudinaryUploadResult>[];
    for (var i = 0; i < files.length; i++) {
      final res = await uploadFile(files[i], folder: folder);
      results.add(res);
      onProgress?.call((i + 1) / files.length);
    }
    return results;
  }
}
