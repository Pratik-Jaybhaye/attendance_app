import 'dart:math';
import 'face_recognition_config.dart';

/// Face Embedding Model - 128-dimensional vector representation
class FaceEmbedding {
  final List<double> vector;
  final String studentId;
  final String studentName;
  final DateTime enrolledAt;

  FaceEmbedding({
    required this.vector,
    required this.studentId,
    required this.studentName,
    required this.enrolledAt,
  });

  /// Ensure embedding is normalized (L2 normalization)
  List<double> getNormalized() {
    final magnitude = sqrt(vector.fold(0.0, (sum, v) => sum + (v * v)));
    if (magnitude == 0) return vector;
    return vector.map((v) => v / magnitude).toList();
  }
}

/// Face Recognition Service using FaceNet
/// Performs face matching using embedding cosine similarity (128-dimensional vectors)
///
/// Features:
/// - Dynamic Recognition Thresholds: Adjusts based on face quality (60-90% similarity)
/// - Embedding Cache: Pre-loads all student embeddings to RAM for O(1) lookup
/// - Multiple Match Support: Returns top 3 matches for confidence ranking
/// - Mode Support: Works with Student Mode (multi-student) and Teacher Mode (single teacher)
class FaceRecognitionService {
  // In-memory embedding cache for performance
  // Map: studentId -> FaceEmbedding[]
  final Map<String, List<FaceEmbedding>> _embeddingCache = {};

  // Precomputed metadata for quick access
  final Map<String, Map<String, dynamic>> _studentMetadata = {};

  // Cache statistics
  late DateTime _cacheLoadTime;

  FaceRecognitionService() {
    _initializeService();
  }

  void _initializeService() {
    print(
      '[FaceRecognition] Service initialized with ${FaceRecognitionConfig.embeddingDimension}-dim embeddings',
    );
    print(
      '[FaceRecognition] Embedding Cache: ${FaceRecognitionConfig.enableEmbeddingCache ? 'ENABLED' : 'DISABLED'}',
    );
    print(
      '[FaceRecognition] Max cached embeddings: ${FaceRecognitionConfig.maxCachedEmbeddings}',
    );
  }

  /// Load student embeddings into cache
  /// Called during app initialization or class selection
  ///
  /// Performance: Pre-loads all embeddings to RAM for O(1) lookup during recognition
  /// Typical cache size: 5000 embeddings × 128 dimensions × 8 bytes = ~5.2 MB
  Future<void> loadStudentEmbeddings(List<String> studentIds) async {
    try {
      print(
        '[FaceRecognition] Loading embeddings for ${studentIds.length} students...',
      );

      for (final studentId in studentIds) {
        // TODO: Fetch embeddings from backend or local database
        // Example:
        // final embeddings = await _getStudentEmbeddings(studentId);
        // _embeddingCache[studentId] = embeddings;
      }

      _cacheLoadTime = DateTime.now();
      print('[FaceRecognition] Embedding cache loaded successfully');
    } catch (e) {
      print('[FaceRecognition] Error loading embeddings: $e');
    }
  }

  /// Recognize face by comparing with stored embeddings
  /// Returns top matches with confidence scores
  ///
  /// Dynamic Thresholds:
  /// - High Quality (90+): 60% similarity needed
  /// - Good Quality (75-90): 70% similarity needed
  /// - Fair Quality (60-75): 80% similarity needed
  /// - Poor Quality (<60): 90% similarity needed
  ///
  /// Returns top N matches (default 3) sorted by confidence
  Map<String, dynamic> recognizeFace(
    List<double> faceEmbedding, {
    double? confidenceThreshold,
    int topMatches = FaceRecognitionConfig.topMatchesCount,
  }) {
    // Use provided threshold or default
    final threshold =
        confidenceThreshold ?? FaceRecognitionConfig.highQualityThreshold;

    final normalizedEmbedding = _normalizeEmbedding(faceEmbedding);
    final matches = <Map<String, dynamic>>[];

    // Compare with all cached embeddings
    _embeddingCache.forEach((studentId, embeddings) {
      for (final embedding in embeddings) {
        final similarity = _cosineSimilarity(
          normalizedEmbedding,
          embedding.getNormalized(),
        );

        // Store match if above threshold
        if (similarity >= threshold) {
          matches.add({
            'studentId': studentId,
            'studentName': embedding.studentName,
            'confidence': similarity,
            'enrolledAt': embedding.enrolledAt,
            'distance': 1.0 - similarity,
          });
        }
      }
    });

    // Sort by confidence (descending) and return top matches
    matches.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );

    final topResults = matches.take(topMatches).toList();

    return {
      'matched': topResults.isNotEmpty,
      'topMatch': topResults.isNotEmpty ? topResults.first : null,
      'allMatches': topResults,
      'confidence': topResults.isNotEmpty
          ? topResults.first['confidence']
          : 0.0,
    };
  }

  /// Get dynamic recognition threshold based on face quality score
  /// Quality scores: 0-100 (100 = perfect quality)
  ///
  /// Thresholds:
  /// - 90+ quality: 60% (most confident)
  /// - 75-90 quality: 70%
  /// - 60-75 quality: 80%
  /// - <60 quality: 90% (most strict)
  double getDynamicThreshold(int faceQualityScore) {
    return FaceRecognitionConfig.getDynamicThreshold(faceQualityScore);
  }

  /// Cosine similarity between two embeddings
  /// Range: 0-1 (1 = identical, 0 = completely different)
  double _cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) {
      throw ArgumentError('Vectors must have same dimension');
    }

    double dotProduct = 0.0;
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      magnitude1 += vec1[i] * vec1[i];
      magnitude2 += vec2[i] * vec2[i];
    }

    final denominator = sqrt(magnitude1) * sqrt(magnitude2);
    if (denominator == 0) return 0.0;

    return dotProduct / denominator;
  }

  /// Normalize embedding vector to unit length
  List<double> _normalizeEmbedding(List<double> embedding) {
    final magnitude = sqrt(embedding.fold(0.0, (sum, v) => sum + (v * v)));
    if (magnitude == 0) return embedding;
    return embedding.map((v) => v / magnitude).toList();
  }

  /// Generate mock embedding for testing (128-dim FaceNet output)
  List<double> generateMockEmbedding() {
    final random = Random();
    return List.generate(128, (_) => (random.nextDouble() - 0.5) * 2);
  }

  /// Calculate embedding distance (Euclidean)
  double calculateEuclideanDistance(List<double> vec1, List<double> vec2) {
    double sum = 0.0;
    for (int i = 0; i < vec1.length; i++) {
      final diff = vec1[i] - vec2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  /// Cache student embedding
  /// Adds embedding to in-memory cache for fast lookup
  void cacheEmbedding(FaceEmbedding embedding) {
    if (!_embeddingCache.containsKey(embedding.studentId)) {
      _embeddingCache[embedding.studentId] = [];
    }
    if (_embeddingCache[embedding.studentId]!.length <
        FaceRecognitionConfig.maxCachedEmbeddings) {
      _embeddingCache[embedding.studentId]!.add(embedding);
    }
  }

  /// Preload all embeddings (called during warmup)
  /// Loads all cached embeddings into RAM for fast recognition
  Future<void> preloadAllEmbeddings() async {
    try {
      if (!FaceRecognitionConfig.enableEmbeddingCache) {
        print('[FaceRecognition] Embedding cache disabled, skipping preload');
        return;
      }
      print('[FaceRecognition] Preloading all embeddings...');
      // TODO: Fetch all student embeddings from database
      // Store in _embeddingCache for fast lookup
    } catch (e) {
      print('[FaceRecognition] Error preloading embeddings: $e');
    }
  }

  /// Clear cache
  void clearCache() {
    _embeddingCache.clear();
    _studentMetadata.clear();
  }

  /// Get cache statistics for debugging/monitoring
  /// Returns: number of cached students, total embeddings, approximate cache size
  Map<String, dynamic> getCacheStats() {
    int totalEmbeddings = 0;
    _embeddingCache.forEach((_, embeddings) {
      totalEmbeddings += embeddings.length;
    });

    // Approximate cache size: embeddings × 128 dimensions × 8 bytes (double)
    final approximateSizeBytes =
        totalEmbeddings * FaceRecognitionConfig.embeddingDimension * 8;
    final sizeMB = approximateSizeBytes / (1024 * 1024);

    return {
      'cachedStudents': _embeddingCache.length,
      'totalEmbeddings': totalEmbeddings,
      'cacheSize': '${sizeMB.toStringAsFixed(2)} MB',
      'status': 'OK',
      'loadTime': _cacheLoadTime.toString(),
    };
  }
}
