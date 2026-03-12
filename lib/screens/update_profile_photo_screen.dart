import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/photo_storage_service.dart';
import '../services/database_helper.dart';
import '../services/user_service.dart';

/// Update Profile Photo Screen
/// This screen allows users to view their current profile information
/// and update their profile photo by navigating to the photo picker
class UpdateProfilePhotoScreen extends StatefulWidget {
  final String userName;
  final String userID;
  final String? currentProfileImage;

  const UpdateProfilePhotoScreen({
    super.key,
    required this.userName,
    required this.userID,
    this.currentProfileImage,
  });

  @override
  State<UpdateProfilePhotoScreen> createState() =>
      _UpdateProfilePhotoScreenState();
}

class _UpdateProfilePhotoScreenState extends State<UpdateProfilePhotoScreen> {
  // Variable to store selected image path
  String? selectedImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  /// Handle back navigation
  void _handleBack() {
    Navigator.of(context).pop();
  }

  /// Request camera permission and open camera to take a photo
  Future<void> _takePhotoWithCamera() async {
    try {
      final cameraStatus = await Permission.camera.request();

      if (!cameraStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
        }
        return;
      }

      final XFile? photoFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photoFile != null && mounted) {
        Navigator.pop(context); // Close dialog
        setState(() {
          selectedImagePath = photoFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Request gallery/storage permission and open gallery to choose a photo
  Future<void> _choosePhotoFromGallery() async {
    try {
      final storageStatus = await Permission.photos.request();

      if (!storageStatus.isGranted) {
        final readStatus = await Permission.storage.request();

        if (!readStatus.isGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required')),
          );
          return;
        }
      }

      final XFile? photoFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photoFile != null && mounted) {
        Navigator.pop(context); // Close dialog
        setState(() {
          selectedImagePath = photoFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Handle photo change by showing the photo picker options
  /// This shows a dialog where user can:
  /// 1. Take a photo using camera
  /// 2. Choose from gallery
  void _handleChangePhoto() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'Change Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 24),
                // Take Photo Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _takePhotoWithCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5B95),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
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
                const SizedBox(height: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.image,
                      color: Color(0xFF6B5B95),
                      size: 20,
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
                const SizedBox(height: 16),
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF6B5B95),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Handle updating the profile photo on backend
  /// TODO: Implement actual API call to upload the image
  void _handleUpdatePhoto() {
    if (selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo first')),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Update'),
          content: const Text('Update profile photo with the selected image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _uploadProfilePhoto();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /// Upload profile photo to backend
  /// Saves photo locally and updates user profile image path in database
  Future<void> _uploadProfilePhoto() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5B95)),
                ),
                SizedBox(height: 16),
                Text('Updating profile photo...'),
              ],
            ),
          );
        },
      );

      // Step 1: Save photo to local storage with user ID
      final photoStorageService = PhotoStorageService();
      final savedPhotoPath = await photoStorageService.saveProfilePhoto(
        sourceImagePath: selectedImagePath!,
        userId: widget.userID,
      );

      if (savedPhotoPath == null) {
        throw Exception('Failed to save photo locally');
      }

      print('[UpdateProfilePhoto] Photo saved to: $savedPhotoPath');

      // Step 2: Get user from database
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUserById(widget.userID);

      if (user == null) {
        throw Exception('User not found in database');
      }

      print('[UpdateProfilePhoto] User found: ${user.username}');

      // Step 3: Update user with new profile image path
      final updatedUser = user.copyWith(profileImagePath: savedPhotoPath);

      // Step 4: Save updated user to database
      final updateSuccess = await dbHelper.updateUser(updatedUser);

      if (!updateSuccess) {
        throw Exception('Failed to update user in database');
      }

      print('[UpdateProfilePhoto] User profile updated successfully');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home screen
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pop(true); // Return true to indicate update
        });
      }
    } catch (e) {
      print('[UpdateProfilePhoto] Error: $e');

      // Close loading dialog if it exists
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (e) {
          // Dialog might not exist, ignore
        }
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F8),
      body: SafeArea(
        child: SingleChildScrollView(
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
                      'Update Profile Photo',
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
              const SizedBox(height: 24),
              // Main Content Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
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
                    vertical: 32.0,
                  ),
                  child: Column(
                    children: [
                      // User Information Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // User Name
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B5B95),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // User ID
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'ID: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2C2C2C),
                                ),
                              ),
                              Text(
                                widget.userID,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C2C2C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Warning Text
                      Text(
                        'Current photo will be replaced',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Instruction Text
                      const Text(
                        'Tap image to select new photo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5A5C6E),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Profile Image Display
                      GestureDetector(
                        onTap: _handleChangePhoto,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFD0D0D0),
                              width: 2,
                            ),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: selectedImagePath != null
                                ? // Display selected image from file
                                  Image.file(
                                    // ignore: deprecated_member_use
                                    File(selectedImagePath!),
                                    fit: BoxFit.cover,
                                    height: 280,
                                  )
                                : widget.currentProfileImage != null
                                ? // Display current profile image from network
                                  Image.network(
                                    widget.currentProfileImage!,
                                    fit: BoxFit.cover,
                                    height: 280,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 280,
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 80,
                                            color: Color(0xFF6B5B95),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : // Default placeholder
                                  Container(
                                    height: 280,
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Color(0xFF6B5B95),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Update Photo Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedImagePath != null
                              ? _handleUpdatePhoto
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B5B95),
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Update Photo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
