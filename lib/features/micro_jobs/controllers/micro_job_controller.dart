import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/micro_job/job_submission_model.dart';
import 'package:shirah/data/models/micro_job/micro_job_model.dart';
import 'package:shirah/data/repositories/micro_job_repository.dart';

/// Micro Job Controller - Manages job listing, detail, and proof submission
/// Handles fetching available jobs, viewing details, and submitting proof
class MicroJobController extends GetxController {
  static MicroJobController get instance => Get.find();

  // ==================== Dependencies ====================
  final MicroJobRepository _repository = MicroJobRepository.instance;

  // ==================== Reactive State ====================
  final RxList<MicroJobModel> availableJobs = <MicroJobModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;

  // ==================== Detail Screen State ====================
  final Rx<MicroJobModel> selectedJob = MicroJobModel.empty().obs;
  final RxBool isLoadingDetail = false.obs;
  final RxBool hasSubmitted = false.obs;
  final Rx<JobSubmissionModel?> userSubmission = Rx<JobSubmissionModel?>(null);

  // ==================== Proof Submission State ====================
  final RxList<File> proofImages = <File>[].obs;
  final TextEditingController proofMessageController = TextEditingController();
  final RxBool isSubmittingProof = false.obs;
  final ImagePicker _picker = ImagePicker();

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    fetchAvailableJobs();
  }

  @override
  void onClose() {
    proofMessageController.dispose();
    super.onClose();
  }

  // ==================== FETCH JOBS ====================

  Future<void> fetchAvailableJobs() async {
    try {
      isLoading.value = true;
      hasMore.value = true;

      final jobs = await _repository.fetchAvailableJobs(limit: 20);
      availableJobs.assignAll(jobs);

      if (jobs.length < 20) hasMore.value = false;
    } catch (e) {
      LoggerService.error('Failed to fetch available jobs', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreJobs() async {
    if (isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;

      final lastDoc = availableJobs.isNotEmpty
          ? availableJobs.last.documentSnapshot
          : null;

      final moreJobs = await _repository.fetchAvailableJobs(
        limit: 20,
        lastDoc: lastDoc,
      );

      if (moreJobs.length < 20) hasMore.value = false;
      availableJobs.addAll(moreJobs);
    } catch (e) {
      LoggerService.error('Failed to load more jobs', e);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshJobs() async {
    await fetchAvailableJobs();
  }

  // ==================== JOB DETAILS ====================

  Future<void> loadJobDetails(String jobId) async {
    try {
      isLoadingDetail.value = true;
      hasSubmitted.value = false;
      userSubmission.value = null;

      final job = await _repository.getJobDetails(jobId);
      if (job != null) {
        selectedJob.value = job;
      }

      // Check if user has submitted
      final submission = await _repository.getUserSubmission(jobId);
      if (submission != null) {
        hasSubmitted.value = true;
        userSubmission.value = submission;
      }
    } catch (e) {
      LoggerService.error('Failed to load job details', e);
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ==================== PROOF SUBMISSION ====================

  Future<void> pickProofImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        if (proofImages.length + images.length > 5) {
          Get.snackbar('Limit', 'Maximum 5 proof images allowed');
          return;
        }
        proofImages.addAll(images.map((x) => File(x.path)));
      }
    } catch (e) {
      LoggerService.error('Failed to pick proof images', e);
      Get.snackbar('Error', 'Failed to pick images');
    }
  }

  void removeProofImage(int index) {
    if (index >= 0 && index < proofImages.length) {
      proofImages.removeAt(index);
    }
  }

  Future<void> submitProof(String jobId) async {
    if (proofImages.isEmpty) {
      Get.snackbar('Required', 'Please add at least one proof screenshot');
      return;
    }
    if (proofMessageController.text.trim().length < 5) {
      Get.snackbar('Required', 'Please add a proof message (min 5 characters)');
      return;
    }

    try {
      isSubmittingProof.value = true;
      EasyLoading.show(status: 'Uploading proof...');

      // 1. Upload proof images
      final imageUrls = await _repository.uploadProofImages(jobId, proofImages);

      // 2. Submit via Cloud Function
      EasyLoading.show(status: 'Submitting proof...');
      await _repository.submitJobProof(
        jobId: jobId,
        proofImages: imageUrls,
        proofText: proofMessageController.text.trim(),
      );

      EasyLoading.showSuccess('Proof submitted!');

      // Update state
      hasSubmitted.value = true;
      proofImages.clear();
      proofMessageController.clear();

      // Close the proof sheet
      Get.back();

      // Refresh job details
      await loadJobDetails(jobId);
    } catch (e) {
      LoggerService.error('Failed to submit proof', e);
      EasyLoading.showError(e.toString());
    } finally {
      isSubmittingProof.value = false;
    }
  }
}
