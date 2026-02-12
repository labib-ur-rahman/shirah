import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/cloud_functions_service.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/core/utils/constants/firebase_paths.dart';
import 'package:shirah/data/models/micro_job/job_submission_model.dart';
import 'package:shirah/data/models/micro_job/micro_job_model.dart';

/// Micro Job Repository - Firebase operations for micro jobs
/// All Firestore reads, Cloud Function calls, and Storage uploads
class MicroJobRepository extends GetxController {
  static MicroJobRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CloudFunctionsService _functions = CloudFunctionsService.instance;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  // ==================== JOB CREATION ====================

  /// Upload cover image to Firebase Storage
  Future<String> uploadJobCoverImage(File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'jobs/$_currentUid/cover_$timestamp.jpg';
      final ref = _storage.ref().child(path);

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      LoggerService.error('Failed to upload job cover image', e);
      rethrow;
    }
  }

  /// Create a micro job via Cloud Function
  Future<Map<String, dynamic>> createMicroJob({
    required String title,
    required String details,
    required String coverImage,
    required String jobLink,
    required int limit,
    required double perUserPrice,
  }) async {
    try {
      LoggerService.info('📋 Creating micro job: $title');
      final result = await _functions.call('createMicroJob', {
        'title': title,
        'details': details,
        'coverImage': coverImage,
        'jobLink': jobLink,
        'limit': limit,
        'perUserPrice': perUserPrice,
      });
      LoggerService.info('✅ Micro job created successfully');
      return result;
    } catch (e) {
      LoggerService.error('Failed to create micro job', e);
      rethrow;
    }
  }

  // ==================== JOB LISTING ====================

  /// Fetch approved micro jobs (for workers/feed)
  Future<List<MicroJobModel>> fetchAvailableJobs({
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection(FirebasePaths.microJobs)
          .where('status', isEqualTo: JobStatus.approved)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MicroJobModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      LoggerService.error('Failed to fetch available jobs', e);
      rethrow;
    }
  }

  /// Fetch jobs created by the logged-in user
  Future<List<MicroJobModel>> fetchMyCreatedJobs({int limit = 20}) async {
    try {
      final snapshot = await _db
          .collection(FirebasePaths.microJobs)
          .where('authorId', isEqualTo: _currentUid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MicroJobModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      LoggerService.error('Failed to fetch my created jobs', e);
      rethrow;
    }
  }

  /// Get single job details
  Future<MicroJobModel?> getJobDetails(String jobId) async {
    try {
      final doc = await _db
          .collection(FirebasePaths.microJobs)
          .doc(jobId)
          .get();
      if (!doc.exists) return null;
      return MicroJobModel.fromFirestore(doc);
    } catch (e) {
      LoggerService.error('Failed to get job details: $jobId', e);
      rethrow;
    }
  }

  // ==================== PROOF SUBMISSION ====================

  /// Upload proof images to Firebase Storage
  Future<List<String>> uploadProofImages(
    String jobId,
    List<File> images,
  ) async {
    try {
      final urls = <String>[];
      for (int i = 0; i < images.length; i++) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'job_proofs/$jobId/$_currentUid/proof_${timestamp}_$i.jpg';
        final ref = _storage.ref().child(path);

        final uploadTask = await ref.putFile(
          images[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      }
      return urls;
    } catch (e) {
      LoggerService.error('Failed to upload proof images', e);
      rethrow;
    }
  }

  /// Submit job proof via Cloud Function
  Future<Map<String, dynamic>> submitJobProof({
    required String jobId,
    required List<String> proofImages,
    required String proofText,
  }) async {
    try {
      LoggerService.info('📸 Submitting job proof for: $jobId');
      final result = await _functions.call('submitJobProof', {
        'jobId': jobId,
        'proofImages': proofImages,
        'proofText': proofText,
      });
      LoggerService.info('✅ Job proof submitted successfully');
      return result;
    } catch (e) {
      LoggerService.error('Failed to submit job proof', e);
      rethrow;
    }
  }

  /// Check if the current user has already submitted for a job
  Future<bool> hasUserSubmitted(String jobId) async {
    try {
      final snapshot = await _db
          .collection('job_submissions')
          .where('jobId', isEqualTo: jobId)
          .where('workerId', isEqualTo: _currentUid)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      LoggerService.error('Failed to check submission status', e);
      return false;
    }
  }

  /// Get user's submission for a specific job
  Future<JobSubmissionModel?> getUserSubmission(String jobId) async {
    try {
      final snapshot = await _db
          .collection('job_submissions')
          .where('jobId', isEqualTo: jobId)
          .where('workerId', isEqualTo: _currentUid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return JobSubmissionModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      LoggerService.error('Failed to get user submission', e);
      return null;
    }
  }

  /// Fetch user's submissions
  Future<List<JobSubmissionModel>> fetchMySubmissions({int limit = 20}) async {
    try {
      LoggerService.info('📋 Fetching my submissions');
      final result = await _functions.call('getMySubmissions', {
        'limit': limit,
      });

      final submissions = (result['data']?['submissions'] as List? ?? [])
          .map(
            (data) => JobSubmissionModel.fromMap(data as Map<String, dynamic>),
          )
          .toList();

      LoggerService.info('✅ Fetched ${submissions.length} submissions');
      return submissions;
    } catch (e) {
      LoggerService.error('Failed to fetch my submissions', e);
      rethrow;
    }
  }

  // ==================== JOB SUBMISSIONS (Author Review) ====================

  /// Fetch submissions for a specific job (author/admin only)
  Future<List<JobSubmissionModel>> fetchJobSubmissions({
    required String jobId,
    String? status,
    int limit = 50,
  }) async {
    try {
      LoggerService.info('📋 Fetching job submissions for: $jobId');
      final result = await _functions.call('getJobSubmissions', {
        'jobId': jobId,
        if (status != null) 'status': status,
        'limit': limit,
      });

      final submissions =
          (result['data']?['submissions'] as List?)
              ?.map(
                (s) => JobSubmissionModel.fromMap(s as Map<String, dynamic>),
              )
              .toList() ??
          [];

      LoggerService.info('✅ Fetched ${submissions.length} submissions');
      return submissions;
    } catch (e) {
      LoggerService.error('Failed to fetch job submissions', e);
      rethrow;
    }
  }

  /// Review a job submission (approve/reject) via Cloud Function
  Future<Map<String, dynamic>> reviewSubmission({
    required String submissionId,
    required String action,
    String? rejectionNote,
  }) async {
    try {
      LoggerService.info('🔍 Reviewing submission: $submissionId ($action)');
      final result = await _functions.call('reviewJobSubmission', {
        'submissionId': submissionId,
        'action': action,
        if (rejectionNote != null) 'rejectionNote': rejectionNote,
      });
      LoggerService.info('✅ Submission $action successfully');
      return result;
    } catch (e) {
      LoggerService.error('Failed to review submission', e);
      rethrow;
    }
  }
}
