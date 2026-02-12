import 'package:cloud_firestore/cloud_firestore.dart';

/// Job Submission Status ENUMs
class SubmissionStatus {
  SubmissionStatus._();
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
}

/// Job Submission Model - Represents a worker's proof submission
/// Collection: /job_submissions/{submissionId}
class JobSubmissionModel {
  final String submissionId;
  final String jobId;
  final String jobAuthorId;
  final String workerId;
  final String workerName;
  final List<String> proofImages;
  final String proofText;
  final String status;
  final String? rejectionNote;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  // Job details (from Cloud Function enrichment)
  final String? jobTitle;
  final String? jobCoverImage;
  final double? perUserPrice;

  /// Firestore document snapshot for pagination
  DocumentSnapshot? documentSnapshot;

  JobSubmissionModel({
    required this.submissionId,
    required this.jobId,
    required this.jobAuthorId,
    required this.workerId,
    required this.workerName,
    required this.proofImages,
    required this.proofText,
    this.status = 'PENDING',
    this.rejectionNote,
    this.createdAt,
    this.reviewedAt,
    this.jobTitle,
    this.jobCoverImage,
    this.perUserPrice,
    this.documentSnapshot,
  });

  // Convenience getters with defaults
  DateTime get submittedAt => createdAt ?? DateTime.now();

  factory JobSubmissionModel.empty() {
    return JobSubmissionModel(
      submissionId: '',
      jobId: '',
      jobAuthorId: '',
      workerId: '',
      workerName: '',
      proofImages: [],
      proofText: '',
    );
  }

  factory JobSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final model = JobSubmissionModel(
      submissionId: data['submissionId'] ?? doc.id,
      jobId: data['jobId'] ?? '',
      jobAuthorId: data['jobAuthorId'] ?? '',
      workerId: data['workerId'] ?? '',
      workerName: data['workerName'] ?? '',
      proofImages: List<String>.from(data['proofImages'] ?? []),
      proofText: data['proofText'] ?? '',
      status: data['status'] ?? SubmissionStatus.pending,
      rejectionNote: data['rejectionNote'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      jobTitle: data['jobTitle'],
      jobCoverImage: data['jobCoverImage'],
      perUserPrice: data['perUserPrice']?.toDouble(),
    );
    model.documentSnapshot = doc;
    return model;
  }

  /// Create from Map (e.g., from Cloud Function response)
  factory JobSubmissionModel.fromMap(Map<String, dynamic> data) {
    return JobSubmissionModel(
      submissionId: data['submissionId'] ?? '',
      jobId: data['jobId'] ?? '',
      jobAuthorId: data['jobAuthorId'] ?? '',
      workerId: data['workerId'] ?? '',
      workerName: data['workerName'] ?? '',
      proofImages: List<String>.from(data['proofImages'] ?? []),
      proofText: data['proofText'] ?? '',
      status: data['status'] ?? SubmissionStatus.pending,
      rejectionNote: data['rejectionNote'],
      createdAt: data['createdAt'] != null
          ? _parseTimestamp(data['createdAt'])
          : null,
      jobTitle: data['jobTitle'],
      jobCoverImage: data['jobCoverImage'],
      perUserPrice: data['perUserPrice']?.toDouble(),
      reviewedAt: data['reviewedAt'] != null
          ? _parseTimestamp(data['reviewedAt'])
          : null,
    );
  }

  /// Parse timestamp from either Firestore Timestamp or Map (Cloud Function)
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is Map) {
      final seconds = value['_seconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'jobId': jobId,
      'jobAuthorId': jobAuthorId,
      'workerId': workerId,
      'workerName': workerName,
      'proofImages': proofImages,
      'proofText': proofText,
      'status': status,
      'rejectionNote': rejectionNote,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'jobTitle': jobTitle,
      'jobCoverImage': jobCoverImage,
      'perUserPrice': perUserPrice,
    };
  }

  @override
  String toString() =>
      'JobSubmissionModel(submissionId: $submissionId, jobId: $jobId)';
}
