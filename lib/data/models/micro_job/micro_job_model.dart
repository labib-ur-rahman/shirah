import 'package:cloud_firestore/cloud_firestore.dart';

/// Micro Job Status ENUMs
class JobStatus {
  JobStatus._();
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
  static const String paused = 'PAUSED';
  static const String completed = 'COMPLETED';
}

/// Micro Job Model - Represents a single micro job post
/// Collection: /jobs/{jobId}
class MicroJobModel {
  final String jobId;
  final String authorId;
  final String authorName;
  final String title;
  final String details;
  final String coverImage;
  final String jobLink;
  final int limit;
  final double perUserPrice;
  final double totalPrice;
  final double serviceFee;
  final int submittedCount;
  final int approvedCount;
  final String status;
  final String? rejectionNote;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  /// Firestore document snapshot for pagination
  DocumentSnapshot? documentSnapshot;

  MicroJobModel({
    required this.jobId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.details,
    required this.coverImage,
    required this.jobLink,
    required this.limit,
    required this.perUserPrice,
    required this.totalPrice,
    this.serviceFee = 0,
    this.submittedCount = 0,
    this.approvedCount = 0,
    this.status = 'PENDING',
    this.rejectionNote,
    this.createdAt,
    this.approvedAt,
    this.documentSnapshot,
  });

  /// Remaining slots available
  int get remainingSlots => limit - submittedCount;

  /// Whether the job is still accepting submissions
  bool get isAcceptingSubmissions =>
      status == JobStatus.approved && submittedCount < limit;

  /// Progress percentage (0.0 to 1.0)
  double get progress => limit > 0 ? submittedCount / limit : 0;

  factory MicroJobModel.empty() {
    return MicroJobModel(
      jobId: '',
      authorId: '',
      authorName: '',
      title: '',
      details: '',
      coverImage: '',
      jobLink: '',
      limit: 0,
      perUserPrice: 0,
      totalPrice: 0,
    );
  }

  factory MicroJobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final model = MicroJobModel(
      jobId: data['jobId'] ?? doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      title: data['title'] ?? '',
      details: data['details'] ?? '',
      coverImage: data['coverImage'] ?? '',
      jobLink: data['jobLink'] ?? '',
      limit: (data['limit'] ?? 0).toInt(),
      perUserPrice: (data['perUserPrice'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0).toDouble(),
      submittedCount: (data['submittedCount'] ?? 0).toInt(),
      approvedCount: (data['approvedCount'] ?? 0).toInt(),
      status: data['status'] ?? JobStatus.pending,
      rejectionNote: data['rejectionNote'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
    );
    model.documentSnapshot = doc;
    return model;
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'details': details,
      'coverImage': coverImage,
      'jobLink': jobLink,
      'limit': limit,
      'perUserPrice': perUserPrice,
      'totalPrice': totalPrice,
      'serviceFee': serviceFee,
      'submittedCount': submittedCount,
      'approvedCount': approvedCount,
      'status': status,
      'rejectionNote': rejectionNote,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  @override
  String toString() => 'MicroJobModel(jobId: $jobId, title: $title)';
}
