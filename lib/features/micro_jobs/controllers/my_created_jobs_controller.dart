import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/micro_job/job_submission_model.dart';
import 'package:shirah/data/models/micro_job/micro_job_model.dart';
import 'package:shirah/data/repositories/micro_job_repository.dart';

/// My Created Jobs Controller - Manages author's job list and submission reviews
/// Handles fetching author's jobs, viewing submissions, and approving/rejecting proofs
class MyCreatedJobsController extends GetxController {
  static MyCreatedJobsController get instance => Get.find();

  // ==================== Dependencies ====================
  final MicroJobRepository _repository = MicroJobRepository.instance;

  // ==================== My Jobs State ====================
  final RxList<MicroJobModel> myJobs = <MicroJobModel>[].obs;
  final RxBool isLoadingJobs = false.obs;

  // ==================== Submissions State ====================
  final Rx<MicroJobModel> selectedJob = MicroJobModel.empty().obs;
  final RxList<JobSubmissionModel> submissions = <JobSubmissionModel>[].obs;
  final RxBool isLoadingSubmissions = false.obs;
  final RxString filterStatus =
      ''.obs; // '' = all, 'PENDING', 'APPROVED', 'REJECTED'

  // ==================== Review State ====================
  final RxBool isReviewing = false.obs;
  final TextEditingController rejectionNoteController = TextEditingController();

  // ==================== Computed Properties ====================
  int get pendingCount =>
      submissions.where((s) => s.status == SubmissionStatus.pending).length;
  int get approvedCount =>
      submissions.where((s) => s.status == SubmissionStatus.approved).length;
  int get rejectedCount =>
      submissions.where((s) => s.status == SubmissionStatus.rejected).length;

  List<JobSubmissionModel> get filteredSubmissions {
    if (filterStatus.value.isEmpty) return submissions;
    return submissions.where((s) => s.status == filterStatus.value).toList();
  }

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    fetchMyCreatedJobs();
  }

  @override
  void onClose() {
    rejectionNoteController.dispose();
    super.onClose();
  }

  // ==================== FETCH MY CREATED JOBS ====================

  Future<void> fetchMyCreatedJobs() async {
    try {
      isLoadingJobs.value = true;
      final jobs = await _repository.fetchMyCreatedJobs(limit: 50);
      myJobs.assignAll(jobs);
    } catch (e) {
      LoggerService.error('Failed to fetch my created jobs', e);
    } finally {
      isLoadingJobs.value = false;
    }
  }

  Future<void> refreshMyJobs() async {
    await fetchMyCreatedJobs();
  }

  // ==================== FETCH JOB SUBMISSIONS ====================

  Future<void> loadJobSubmissions(MicroJobModel job) async {
    try {
      selectedJob.value = job;
      isLoadingSubmissions.value = true;
      filterStatus.value = '';

      final subs = await _repository.fetchJobSubmissions(jobId: job.jobId);
      submissions.assignAll(subs);
    } catch (e) {
      LoggerService.error('Failed to load job submissions', e);
    } finally {
      isLoadingSubmissions.value = false;
    }
  }

  Future<void> refreshSubmissions() async {
    if (selectedJob.value.jobId.isEmpty) return;
    await loadJobSubmissions(selectedJob.value);
  }

  void setFilter(String status) {
    filterStatus.value = status;
  }

  // ==================== REVIEW SUBMISSION ====================

  Future<void> approveSubmission(JobSubmissionModel submission) async {
    try {
      isReviewing.value = true;
      EasyLoading.show(status: 'Approving...');

      await _repository.reviewSubmission(
        submissionId: submission.submissionId,
        action: 'approve',
      );

      EasyLoading.showSuccess(
        'Submission approved! Worker paid ৳${selectedJob.value.perUserPrice.toStringAsFixed(0)}',
      );

      // Refresh submissions and job data
      await _refreshAfterReview();
    } catch (e) {
      LoggerService.error('Failed to approve submission', e);
      EasyLoading.showError(e.toString());
    } finally {
      isReviewing.value = false;
    }
  }

  Future<void> rejectSubmission(JobSubmissionModel submission) async {
    final note = rejectionNoteController.text.trim();
    if (note.length < 5) {
      Get.snackbar(
        'Required',
        'Rejection reason must be at least 5 characters',
      );
      return;
    }

    try {
      isReviewing.value = true;
      EasyLoading.show(status: 'Rejecting...');

      await _repository.reviewSubmission(
        submissionId: submission.submissionId,
        action: 'reject',
        rejectionNote: note,
      );

      EasyLoading.showSuccess('Submission rejected');
      rejectionNoteController.clear();

      // Refresh submissions and job data
      await _refreshAfterReview();
    } catch (e) {
      LoggerService.error('Failed to reject submission', e);
      EasyLoading.showError(e.toString());
    } finally {
      isReviewing.value = false;
    }
  }

  Future<void> _refreshAfterReview() async {
    // Refresh submissions list
    if (selectedJob.value.jobId.isNotEmpty) {
      final subs = await _repository.fetchJobSubmissions(
        jobId: selectedJob.value.jobId,
      );
      submissions.assignAll(subs);

      // Refresh the job itself to update counts
      final updatedJob = await _repository.getJobDetails(
        selectedJob.value.jobId,
      );
      if (updatedJob != null) {
        selectedJob.value = updatedJob;

        // Also update in my jobs list
        final index = myJobs.indexWhere((j) => j.jobId == updatedJob.jobId);
        if (index != -1) {
          myJobs[index] = updatedJob;
        }
      }
    }
  }
}
