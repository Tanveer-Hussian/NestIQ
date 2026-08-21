// lib/services/CloudinaryService.dart
// ─────────────────────────────────────────────────────────────────────────────
// Handles all image uploads to Cloudinary.
// Replaces Firebase Storage — images are uploaded to Cloudinary and the
// returned download URL is stored in Firestore as a plain String.
//
// HOW IT WORKS:
//   1. User picks image from gallery (File object)
//   2. We send a multipart HTTP POST to Cloudinary's upload API
//   3. Cloudinary stores the image and returns a JSON response
//   4. We extract the 'secure_url' from the response
//   5. That URL is saved in Firestore (hostels.images[], users.profileImage)
//   6. Any widget that needs the image just uses Image.network(url)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

class CloudinaryService extends GetxService {

  // ── Your Cloudinary credentials ────────────────────────────────────────────
  // Replace these with your actual values from Cloudinary Dashboard
  static const String _cloudName = 'dntto9b5q';       // e.g. 'dxyz123abc'
  static const String _uploadPreset = 'unsigned_preset'; // e.g. 'hostel_images'

  // Cloudinary unsigned upload endpoint
  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // ────────────────────────────────────────────────────────────────────────────
  // Upload a single image file to Cloudinary.
  // Returns the secure HTTPS URL of the uploaded image.
  //
  // [imageFile]  - The image file to upload (from image_picker)
  // [folder]     - Optional folder name inside Cloudinary (for organization)
  // ────────────────────────────────────────────────────────────────────────────
  Future<String> uploadImage(File imageFile, {String folder = 'hostel'}) async {
    try {
      print('CloudinaryService: uploading ${imageFile.path} to folder/$folder');

      // Build multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Required: your unsigned upload preset name
      request.fields['upload_preset'] = _uploadPreset;

      // Optional: organize images into folders inside Cloudinary
      request.fields['folder'] = folder;

      // Attach the image file
      final fileExtension = path.extension(imageFile.path).replaceAll('.', '');
      final mimeType = _getMimeType(fileExtension);

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', mimeType),
      ));

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse the JSON response from Cloudinary
        final jsonData = json.decode(response.body);

        // 'secure_url' is the HTTPS URL — always use this over 'url'
        final secureUrl = jsonData['secure_url'] as String;
        print('CloudinaryService: upload success → $secureUrl');

        return secureUrl;

      } else {
        // Cloudinary returned an error
        print('CloudinaryService: upload failed [${response.statusCode}]: ${response.body}');
        throw Exception('Cloudinary upload failed: ${response.statusCode} — ${response.body}');
      }

    } catch (e) {
      print('CloudinaryService: error uploading image: $e');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Upload multiple hostel images at once.
  // Shows progress via optional callback.
  //
  // Returns a List of secure URLs in the same order as input files.
  // ────────────────────────────────────────────────────────────────────────────
  Future<List<String>> uploadMultipleImages(
    String hostelId,
    List<File> imageFiles, {
    Function(int uploaded, int total)? onProgress,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      // Upload each image to a hostel-specific folder
      final url = await uploadImage(
        imageFiles[i],
        folder: 'hostel/$hostelId',
      );
      downloadUrls.add(url);

      // Notify caller of upload progress (e.g. "2 of 5 uploaded")
      onProgress?.call(i + 1, imageFiles.length);
    }

    return downloadUrls;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Upload a user profile picture.
  // Stored in Cloudinary under 'profiles/' folder.
  // ────────────────────────────────────────────────────────────────────────────
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    return await uploadImage(
      imageFile,
      folder: 'profiles/$userId',
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Delete an image from Cloudinary by its public_id.
  //
  // NOTE: Deleting from Cloudinary requires the Admin API (server-side only)
  // for security. For a student project, you can skip deletion or handle it
  // via a Firebase Cloud Function. For now this is a no-op placeholder.
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> deleteImage(String imageUrl) async {
    // Deletion via unsigned requests is not supported by Cloudinary.
    // The image URL is simply removed from Firestore — the image stays
    // in Cloudinary but becomes unreferenced.
    // For production, use a Cloud Function with your API Secret to delete.
    print('CloudinaryService: deleteImage() — image removed from Firestore reference only.');
    print('CloudinaryService: URL was: $imageUrl');
  }

  // ── Helper: map file extension to MIME type ────────────────────────────────
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg'; // default to jpeg for unknown types
    }
  }
}
