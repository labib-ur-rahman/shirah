import 'package:get/get.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/micro_job/job_submission_model.dart';
import 'package:shirah/data/repositories/micro_job_repository.dart';

/// Worker Submissions Controller - Shows all jobs the worker has submitted
/// Manages fetching and filtering of worker's own job submissions
class WorkerSubmissionsController extends GetxController {
  static WorkerSubmissionsController get instance => Get.find();

  // ==================== Dependencies ====================
  final MicroJobRepository _repository = MicroJobRepository.instance;

  // ==================== State ====================
  final RxList<JobSubmissionModel> submissions = <JobSubmissionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filterStatus = 'all'.obs;

  // ==================== Computed ====================
  List<JobSubmissionModel> get filteredSubmissions {
    if (filterStatus.value == 'all') {
      return submissions;
    }
    return submissions
        .where((s) => s.status.toLowerCase() == filterStatus.value)
        .toList();
  }

  int get pendingCount =>
      submissions.where((s) => s.status == 'PENDING').length;
  int get approvedCount =>
      submissions.where((s) => s.status == 'APPROVED').length;
  int get rejectedCount =>
      submissions.where((s) => s.status == 'REJECTED').length;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    fetchMySubmissions();
  }

  // ==================== Methods ====================

  /// Fetch all submissions by current worker
  Future<void> fetchMySubmissions() async {
    try {
      isLoading.value = true;
      final result = await _repository.fetchMySubmissions();
      submissions.assignAll(result);
    } catch (e) {
      LoggerService.error('Failed to fetch worker submissions', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Set filter status
  void setFilter(String status) {
    filterStatus.value = status;
  }

  /// Refresh submissions
  Future<void> refreshSubmissions() async {
    await fetchMySubmissions();
  }
}
