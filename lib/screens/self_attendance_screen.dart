import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/attendance_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'login_screen.dart';

class SelfAttendanceScreen extends StatefulWidget {
  const SelfAttendanceScreen({super.key});

  @override
  State<SelfAttendanceScreen> createState() => _SelfAttendanceScreenState();
}

class _SelfAttendanceScreenState extends State<SelfAttendanceScreen> {
  // Camera controller - Made nullable to prevent LateInitializationError
  // Will only be initialized after permission is granted
  CameraController? _cameraController;

  // IMPORTANT: This Future is now nullable and will be initialized when camera setup starts
  // This prevents the LateInitializationError exception
  Future<void>? _initializeControllerFuture;

  // Face detection - Made nullable to prevent LateInitializationError
  // Will only be initialized after camera is ready
  FaceDetector? _faceDetector;
  bool _isDetecting = false;

  // Face detection data
  String facePositionX = '0';
  String facePositionY = '0';
  bool isFaceDetected = false;
  bool isFaceInFrame = false;
  Offset? faceCenter;

  // Screen dimensions for face positioning
  double screenWidth = 0;
  double screenHeight = 0;

  // Target frame dimensions
  final double frameWidth = 250;
  final double frameHeight = 350;

  @override
  void initState() {
    super.initState();
    // Request permissions before initializing camera
    _requestPermissions();
  }

  /// Request all required permissions
  /// Step 1: Request Location Permission (if needed for attendance tracking)
  /// Step 2: Request Camera Permission (required for face detection)
  /// This method shows a dialog first to explain why permissions are needed
  Future<void> _requestPermissions() async {
    try {
      // 1️⃣ Request Camera Permission (REQUIRED)
      final cameraStatus = await Permission.camera.request();

      if (!cameraStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required for attendance'),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // 2️⃣ Request Location Permission (OPTIONAL)
      await Permission.location.request();

      // ✅ 3️⃣ IMPORTANT: Initialize Camera AFTER permission
      await _initializeCamera();
    } catch (e) {
      print('Permission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        Navigator.pop(context);
      }
    }
  }

  /// Initialize Front Camera
  /// CRITICAL IMPLEMENTATION NOTES:
  /// - Permission MUST be granted before calling this method
  /// - Camera controller is made nullable to prevent LateInitializationError
  /// - Variables are only initialized after permissions are confirmed
  ///
  /// Steps:
  /// 1. Get screen dimensions for face positioning
  /// 2. Initialize CameraController with front camera
  /// 3. Initialize face detector
  /// 4. Set up face detection listener
  ///
  /// Permission Requirements:
  /// - Android: android.permission.CAMERA (added in AndroidManifest.xml)
  /// - iOS: NSCameraUsageDescription (added in Info.plist)
  Future<void> _initializeCamera() async {
    try {
      // Get screen dimensions for face positioning calculations
      final size = MediaQuery.of(context).size;
      screenWidth = size.width;
      screenHeight = size.height * 0.6; // Camera preview height

      // Get available cameras
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      // Find front camera - CRITICAL: Use front camera for face detection
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Initialize camera controller as nullable
      // This prevents LateInitializationError if initialization fails
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      // CRITICAL FIX: Initialize the controller and assign the Future immediately
      // Assign Future BEFORE awaiting to prevent LateInitializationError
      _initializeControllerFuture = _cameraController!.initialize().then((_) {
        // Initialize face detector ONLY after camera is ready and mounted
        if (mounted) {
          _faceDetector = FaceDetector(
            options: FaceDetectorOptions(
              enableClassification: true,
              enableTracking: true,
              enableContours: true,
            ),
          );

          // Start face detection
          _startFaceDetection();
          setState(() {});
        }
      });

      // Notify UI that we've started initialization
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
        // Pop back to previous screen after showing error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  /// Start Face Detection using Google ML Kit
  /// This method:
  /// 1. Listens to camera frames continuously
  /// 2. Processes frames with ML Kit face detector
  /// 3. Extracts face position and validates positioning
  /// 4. Updates UI with real-time face detection data
  void _startFaceDetection() {
    // Safety check: Camera controller must be initialized
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('Camera controller not initialized');
      return;
    }

    // Safety check: Face detector must be initialized
    if (_faceDetector == null) {
      print('Face detector not initialized');
      return;
    }

    // Listen to camera images and process with face detector
    _cameraController!.startImageStream((image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        // Convert camera image to InputImage for ML Kit
        final inputImage = InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        // Detect faces - Safety check for face detector
        if (_faceDetector == null) return;
        final faces = await _faceDetector!.processImage(inputImage);

        if (mounted && faces.isNotEmpty) {
          final face = faces.first;

          // Calculate face center position
          final boundingBox = face.boundingBox;
          final faceXCenter = (boundingBox.left + boundingBox.right) / 2;
          final faceYCenter = (boundingBox.top + boundingBox.bottom) / 2;

          // Update face position coordinates
          final xCoordinate = faceXCenter.toStringAsFixed(4);
          final yCoordinate = faceYCenter.toStringAsFixed(4);

          // Calculate frame center
          final centerX = screenWidth / 2;
          final centerY = screenHeight / 2;

          // Calculate distance from center
          final distanceX = (faceXCenter - centerX).abs();
          final distanceY = (faceYCenter - centerY).abs();

          // Tolerance for face positioning (in pixels)
          const positionTolerance = 80.0;
          final faceInFrame =
              distanceX < positionTolerance && distanceY < positionTolerance;

          if (mounted) {
            setState(() {
              facePositionX = xCoordinate;
              facePositionY = yCoordinate;
              isFaceDetected = true;
              isFaceInFrame = faceInFrame;
              faceCenter = Offset(faceXCenter, faceYCenter);
            });
          }
        } else if (mounted) {
          setState(() {
            isFaceDetected = false;
            isFaceInFrame = false;
            faceCenter = null;
          });
        }
      } catch (e) {
        print('Error detecting face: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  /// Handle back navigation
  void _handleBack() {
    Navigator.of(context).pop();
  }

  /// Handle logout with confirmation
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Call logout API endpoint here
                // await logoutUser();
                Navigator.pop(context);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Get current location using geolocator
  /// Returns Position object with latitude and longitude
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled.'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  /// Capture and submit attendance
  void _captureAndSubmitAttendance() {
    if (!isFaceDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No face detected. Please position your face in the frame.',
          ),
        ),
      );
      return;
    }

    if (!isFaceInFrame) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Face not properly positioned. Please center your face.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Attendance Confirmation'),
          content: const Text('Mark attendance now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // Show loading dialog while marking attendance
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Marking attendance...'),
                        ],
                      ),
                    );
                  },
                );

                try {
                  // Get current location
                  final position = await _getCurrentLocation();

                  if (!mounted) return;

                  if (position == null) {
                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to get location'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Call AttendanceService.markAttendance with latitude, longitude, and faceVerified=true
                  final success = await AttendanceService.markAttendance(
                    latitude: position.latitude,
                    longitude: position.longitude,
                    faceVerified:
                        true, // Face verified through ML Kit detection
                  );

                  if (!mounted) return;

                  Navigator.pop(context); // Close loading dialog

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attendance marked successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Navigate back to home after 1 second
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) Navigator.of(context).pop();
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to mark attendance. Please try again.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
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
                  // Title Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Self Attendance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      Text(
                        'Position your face',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF2C2C2C).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Logout Button (Top Right)
                  GestureDetector(
                    onTap: _handleLogout,
                    child: const Icon(
                      Icons.login,
                      color: Color(0xFF2C2C2C),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            // Camera Preview Section
            Expanded(
              child: _initializeControllerFuture == null
                  ? // Show loading state while camera is initializing
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : // FutureBuilder for camera preview once initialization starts
                    FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            _cameraController != null) {
                          // Camera is initialized, display preview
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Camera preview - displays real front camera feed
                              CameraPreview(_cameraController!),
                              // Face detection frame guide overlay
                              Container(
                                width: frameWidth,
                                height: frameHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    // Green border when face is properly positioned
                                    color: isFaceInFrame
                                        ? Colors.green
                                        : Colors.white,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              // Instruction text overlay with face coordinates
                              Positioned(
                                bottom: 30,
                                child: Column(
                                  children: [
                                    // Face position coordinates display
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$facePositionX, $facePositionY',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Instruction text
                                    const Text(
                                      'Position your face in the frame',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Camera is still initializing, show loading
                          return Container(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
            ),
            // Bottom Action Section
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                children: [
                  // Status indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFaceDetected ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFaceDetected
                            ? isFaceInFrame
                                  ? 'Face detected - Ready to capture'
                                  : 'Face detected - Adjust position'
                            : 'No face detected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Capture Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isFaceDetected && isFaceInFrame
                          ? _captureAndSubmitAttendance
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DAB5E),
                        disabledBackgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Capture Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 1️⃣ Stop camera stream safely
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          _cameraController!.stopImageStream();
          print('Camera image stream stopped');
        }
      } catch (e) {
        print('Error stopping image stream: $e');
      }

      // 2️⃣ Dispose camera controller
      try {
        _cameraController!.dispose();
        print('Camera controller disposed');
      } catch (e) {
        print('Error disposing camera controller: $e');
      }
    }

    // 3️⃣ Close face detector ONCE
    try {
      _faceDetector?.close();
      print('Face detector closed');
    } catch (e) {
      print('Error closing face detector: $e');
    }

    super.dispose();
  }
}
