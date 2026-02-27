import 'package:flutter/material.dart';
import '../models/student.dart';

/// Upload Multiple Photos Screen
/// Allows users to capture photos of a student from different angles.
/// This improves face recognition accuracy by having multiple face embeddings.
///
/// Angle types:
/// - Front: Direct face view
/// - Left Side: Turn head left (~20°)
/// - Right Side: Turn head right (~20°)
/// - Up: Tilt head upward (~15°)
/// - Down: Tilt head downward (~15°)
class UploadMultiplePhotosScreen extends StatefulWidget {
  final Student student;
  final VoidCallback? onPhotosUploaded;

  const UploadMultiplePhotosScreen({
    super.key,
    required this.student,
    this.onPhotosUploaded,
  });

  @override
  State<UploadMultiplePhotosScreen> createState() =>
      _UploadMultiplePhotosScreenState();
}

class _UploadMultiplePhotosScreenState
    extends State<UploadMultiplePhotosScreen> {
  /// Track uploaded photos for each angle
  final Map<String, int> _uploadedPhotos = {
    'front': 0,
    'left': 0,
    'right': 0,
    'up': 0,
    'down': 0,
  };

  /// Photos captured per angle
  final Map<String, List<String>> _photoPaths = {
    'front': [],
    'left': [],
    'right': [],
    'up': [],
    'down': [],
  };

  /// Angle information with instructions
  final List<Map<String, String>> _angleInfo = [
    {
      'id': 'front',
      'title': 'Front',
      'instruction': 'Look straight at the camera',
    },
    {
      'id': 'left',
      'title': 'Left Side',
      'instruction': 'Turn head slightly to the left\n(~20°)',
    },
    {
      'id': 'right',
      'title': 'Right Side',
      'instruction': 'Turn head slightly to the\nright (~20°)',
    },
    {
      'id': 'up',
      'title': 'Up',
      'instruction': 'Tilt head slightly upward\n(~15°)',
    },
    {
      'id': 'down',
      'title': 'Down',
      'instruction': 'Tilt head slightly downward\n(~15°)',
    },
  ];

  /// Simulate camera capture and upload for an angle
  void _capturePhotoForAngle(String angleId) {
    // Simulate capturing a photo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening camera for $angleId view...'),
        duration: const Duration(seconds: 1),
      ),
    );

    // In a real app, this would open the camera
    // For now, simulate adding a photo
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _uploadedPhotos[angleId] = (_uploadedPhotos[angleId] ?? 0) + 1;
      });
    });

    // TODO: Integrate actual camera capture
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => CameraScreen(
    //       angle: angleId,
    //       onPhotoCapture: (photoPath) {
    //         setState(() {
    //           _photoPaths[angleId]!.add(photoPath);
    //           _uploadedPhotos[angleId] = _photoPaths[angleId]!.length;
    //         });
    //       },
    //     ),
    //   ),
    // );
  }

  /// Submit all captured photos
  void _submitPhotos() {
    final totalPhotos = _uploadedPhotos.values.fold(0, (sum, count) => sum + count);

    if (totalPhotos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least one photo')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Photos?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${widget.student.name}'),
            const SizedBox(height: 12.0),
            Text('Total photos captured: $totalPhotos'),
            const SizedBox(height: 12.0),
            ..._angleInfo.map((info) {
              final count = _uploadedPhotos[info['id']] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(info['title']!),
                    Text(
                      '$count photo${count != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: count > 0 ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Process upload
              _processPhotoUpload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  /// Process photo upload to backend
  void _processPhotoUpload() {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16.0),
            const Text('Uploading photos...'),
          ],
        ),
      ),
    );

    // Simulate upload delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close progress dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos uploaded successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      // Call callback if provided
      if (widget.onPhotosUploaded != null) {
        widget.onPhotosUploaded!();
      }

      // Go back to previous screen
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pop(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPhotos = _uploadedPhotos.values.fold(0, (sum, count) => sum + count);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Multiple Photos'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student name
            Text(
              widget.student.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Capture different angles for better recognition',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20.0),

            // Angle capture sections
            ..._angleInfo.map((info) {
              return _buildAngleSection(
                info['id']!,
                info['title']!,
                info['instruction']!,
              );
            }).toList(),
            const SizedBox(height: 20.0),

            // Upload status
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: totalPhotos > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color:
                      totalPhotos > 0
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  totalPhotos > 0
                      ? '✓ Upload $totalPhotos Photo${totalPhotos != 1 ? 's' : ''}'
                      : 'Upload 0 Photos',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color:
                        totalPhotos > 0
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Close and Submit buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: totalPhotos > 0 ? _submitPhotos : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Edit Photo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build angle capture section
  Widget _buildAngleSection(String angleId, String angleTitle, String instruction) {
    final photoCount = _uploadedPhotos[angleId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: photoCount > 0 ? Colors.green.shade300 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12.0),
        color: photoCount > 0 ? Colors.green.shade50 : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    angleTitle,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    instruction,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              // Photo count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: photoCount > 0 ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  photoCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Capture button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _capturePhotoForAngle(angleId),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Capture Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                backgroundColor: Colors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
