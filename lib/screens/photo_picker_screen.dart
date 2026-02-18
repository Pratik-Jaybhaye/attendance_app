import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Photo Picker Screen
/// This screen allows users to choose between:
/// 1. Taking a new photo using the camera
/// 2. Choosing an existing photo from gallery
///
/// Returns the selected image file path back to the previous screen
class PhotoPickerScreen extends StatefulWidget {
  const PhotoPickerScreen({super.key});

  @override
  State<PhotoPickerScreen> createState() => _PhotoPickerScreenState();
}

class _PhotoPickerScreenState extends State<PhotoPickerScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  /// Request camera permission and open camera to take a photo
  /// Steps:
  /// 1. Request camera permission
  /// 2. Open camera
  /// 3. Return selected image path
  Future<void> _takePhotoWithCamera() async {
    try {
      // Request camera permission
      print('Requesting camera permission...');
      final cameraStatus = await Permission.camera.request();
      print('Camera permission: ${cameraStatus.name}');

      if (!cameraStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
        }
        return;
      }

      // Open camera to take a photo
      print('Opening camera...');
      final XFile? photoFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // 85% quality to reduce file size
        preferredCameraDevice:
            CameraDevice.front, // Use front camera for profile photos
      );

      if (photoFile != null) {
        print('Photo taken: ${photoFile.path}');
        if (mounted) {
          // Return the image path to the previous screen
          Navigator.of(context).pop(photoFile.path);
        }
      } else {
        print('User cancelled camera');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo capture cancelled')),
          );
        }
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Request gallery/storage permission and open gallery to choose a photo
  /// Steps:
  /// 1. Request storage/photo permission
  /// 2. Open gallery/file picker
  /// 3. Return selected image path
  Future<void> _choosePhotoFromGallery() async {
    try {
      // Request storage permission (for Android 13+)
      print('Requesting storage permission...');
      final storageStatus = await Permission.photos.request();
      print('Photos permission: ${storageStatus.name}');

      // Also request media library permission for broader compatibility
      if (!storageStatus.isGranted) {
        final readStatus = await Permission.storage.request();
        print('Storage permission: ${readStatus.name}');

        if (!readStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission is required')),
            );
          }
          return;
        }
      }

      // Open gallery to choose a photo
      print('Opening gallery...');
      final XFile? photoFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // 85% quality to reduce file size
      );

      if (photoFile != null) {
        print('Photo selected: ${photoFile.path}');
        if (mounted) {
          // Return the image path to the previous screen
          Navigator.of(context).pop(photoFile.path);
        }
      } else {
        print('User cancelled gallery selection');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery selection cancelled')),
          );
        }
      }
    } catch (e) {
      print('Error choosing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Handle back navigation
  void _handleBack() {
    Navigator.of(context).pop(); // Return null - no image selected
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              color: const Color(0xFFF5F3F8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: _handleBack,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2C2C2C),
                      size: 28,
                    ),
                  ),
                  // Title
                  const Text(
                    'Change Photo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  // Spacer for alignment
                  const SizedBox(width: 28),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 48.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        const Text(
                          'Change Photo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Take Photo Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _takePhotoWithCamera,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B5B95),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 24,
                            ),
                            label: const Text(
                              'Take Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Divider with "or" text
                        Row(
                          children: const [
                            Expanded(
                              child: Divider(
                                color: Color(0xFFD0D0D0),
                                thickness: 1,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'or',
                              style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Divider(
                                color: Color(0xFFD0D0D0),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Choose from Gallery Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _choosePhotoFromGallery,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF6B5B95),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.image,
                              color: Color(0xFF6B5B95),
                              size: 24,
                            ),
                            label: const Text(
                              'Choose from Gallery',
                              style: TextStyle(
                                color: Color(0xFF6B5B95),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Cancel Button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _handleBack,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF6B5B95),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
