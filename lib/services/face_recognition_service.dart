import 'dart:typed_data';
import 'dart:math';

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
/// Performs face matching using embedding cosine similarity
class FaceRecognitionService {
  // In-memory embedding cache for performance
  // Map: studentId -> FaceEmbedding[]
  final Map<String, List<FaceEmbedding>> _embeddingCache = {};

  // Precomputed metadata for quick access
  final Map<String, Map<String, dynamic>> _studentMetadata = {};

  FaceRecognitionService() {
    _initializeService();
  }

  void _initializeService() {
    // TODO: Load student embeddings from database/local storage
    // This should happen during app startup
  }

  /// Load student embeddings into cache
  /// Called during app initialization or class selection
  Future<void> loadStudentEmbeddings(List<String> studentIds) async {
    try {
      for (final studentId in studentIds) {
        // TODO: Fetch embeddings from backend or local database
        // Example:
        // final embeddings = await _getStudentEmbeddings(studentId);
        // _embeddingCache[studentId] = embeddings;
      }
    } catch (e) {
      print('Error loading embeddings: $e');
    }
  }

  /// Recognize face by comparing with stored embeddings
  /// Returns top matches with confidence scores
  Map<String, dynamic> recognizeFace(
    List<double> faceEmbedding, {
    double confidenceThreshold = 0.65,
    int topMatches = 3,
  }) {
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
        if (similarity >= confidenceThreshold) {
          matches.add({
            'studentId': studentId,
            'studentName': embedding.studentName,
            'confidence': similarity,
            'enrolledAt': embedding.enrolledAt,
            'distance': 1.0 - similarity, // Euclidean-like distance
          });
        }
      }
    });

    // Sort by confidence (descending)
    matches.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );

    // Return top matches
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

  /// Dynamic threshold based on face quality
  /// Better quality = lower threshold needed
  double getDynamicThreshold(int faceQualityScore) {
    // faceQualityScore: 0-100
    if (faceQualityScore >= 90) {
      return 0.60; // High quality: 60% similarity needed
    } else if (faceQualityScore >= 75) {
      return 0.70; // Good quality: 70% similarity needed
    } else if (faceQualityScore >= 60) {
      return 0.80; // Fair quality: 80% similarity needed
    } else {
      return 0.90; // Poor quality: 90% similarity needed (strict)
    }
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
  void cacheEmbedding(FaceEmbedding embedding) {
    if (!_embeddingCache.containsKey(embedding.studentId)) {
      _embeddingCache[embedding.studentId] = [];
    }
    _embeddingCache[embedding.studentId]!.add(embedding);
  }

  /// Preload all embeddings (called during warmup)
  Future<void> preloadAllEmbeddings() async {
    try {
      // TODO: Fetch all student embeddings from database
      // Store in _embeddingCache for fast lookup
    } catch (e) {
      print('Error preloading embeddings: $e');
    }
  }

  /// Clear cache
  void clearCache() {
    _embeddingCache.clear();
    _studentMetadata.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    int totalEmbeddings = 0;
    _embeddingCache.forEach((_, embeddings) {
      totalEmbeddings += embeddings.length;
    });

    return {
      'cachedStudents': _embeddingCache.length,
      'totalEmbeddings': totalEmbeddings,
      'cacheSize': '${(totalEmbeddings * 128 * 8) ~/ 1024} KB', // Approx size
    };
  }
}
