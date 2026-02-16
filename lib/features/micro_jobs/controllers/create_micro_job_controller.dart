import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shirah/core/services/image_compression_service.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/repositories/micro_job_repository.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';

/// Create Micro Job Controller - Manages micro job post creation
/// Handles form input, image picking, price calculation, and submission
class CreateMicroJobController extends GetxController {
  static CreateMicroJobController get instance => Get.find();

  // ==================== Dependencies ====================
  final MicroJobRepository _repository = MicroJobRepository.instance;

  // ==================== Text Controllers ====================
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController jobLinkController = TextEditingController();
  final TextEditingController limitController = TextEditingController();
  final TextEditingController perUserPriceController = TextEditingController();

  // ==================== Form Key ====================
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ==================== Reactive State ====================
  final Rx<File?> coverImage = Rx<File?>(null);
  final RxBool isSubmitting = false.obs;
  final RxDouble totalPrice = 0.0.obs;
  final RxDouble serviceFee = 0.0.obs;
  final RxDouble basePrice = 0.0.obs;

  // ==================== Image Picker ====================
  final ImagePicker _picker = ImagePicker();

  // ==================== Computed Properties ====================
  bool get canSubmit =>
      titleController.text.trim().isNotEmpty &&
      detailsController.text.trim().isNotEmpty &&
      jobLinkController.text.trim().isNotEmpty &&
      coverImage.value != null &&
      limitController.text.isNotEmpty &&
      perUserPriceController.text.isNotEmpty &&
      totalPrice.value > 0;

  /// Check if user is verified
  bool get isUserVerified {
    try {
      return UserController.instance.isVerified;
    } catch (_) {
      return false;
    }
  }

  /// Get user wallet balance
  double get userBalance {
    try {
      return UserController.instance.balance;
    } catch (_) {
      return 0;
    }
  }

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    // Listen to limit and price changes for auto-calculation
    limitController.addListener(_calculateTotalPrice);
    perUserPriceController.addListener(_calculateTotalPrice);
  }

  @override
  void onClose() {
    titleController.dispose();
    detailsController.dispose();
    jobLinkController.dispose();
    limitController.dispose();
    perUserPriceController.dispose();
    super.onClose();
  }

  // ==================== Price Calculation ====================

  void _calculateTotalPrice() {
    final limit = int.tryParse(limitController.text) ?? 0;
    final pricePerUser = double.tryParse(perUserPriceController.text) ?? 0;

    if (limit > 0 && pricePerUser > 0) {
      final base = limit * pricePerUser;
      final fee = (base * 0.10).ceilToDouble(); // 10% service fee
      basePrice.value = base;
      serviceFee.value = fee;
      totalPrice.value = base + fee;
    } else {
      basePrice.value = 0;
      serviceFee.value = 0;
      totalPrice.value = 0;
    }
  }

  // ==================== Image Picker ====================

  Future<void> pickCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        EasyLoading.show(status: 'Compressing image...');
        // Compress image to WebP with 50% quality
        final compressedFile = await ImageCompressionService().compressImage(
          File(image.path),
        );
        coverImage.value = compressedFile;
        EasyLoading.dismiss();
      }
    } catch (e) {
      EasyLoading.dismiss();
      LoggerService.error('Failed to pick cover image', e);
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  void removeCoverImage() {
    coverImage.value = null;
  }

  // ==================== Job Type Selection ====================

  // Job type removed — title and description are sufficient

  // ==================== Form Submission ====================

  Future<void> submitJob() async {
    if (!formKey.currentState!.validate()) return;

    // Check cover image
    if (coverImage.value == null) {
      Get.snackbar('Required', 'Please add a cover image');
      return;
    }

    // Check user verification
    if (!isUserVerified) {
      Get.snackbar(
        'Verification Required',
        'You must verify your profile before creating micro jobs',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Check balance
    if (userBalance < totalPrice.value) {
      Get.snackbar(
        'Insufficient Balance',
        'You need ৳${totalPrice.value.toStringAsFixed(0)} but have ৳${userBalance.toStringAsFixed(0)}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSubmitting.value = true;
      EasyLoading.show(status: 'Creating job...');

      // 1. Upload cover image
      EasyLoading.show(status: 'Uploading image...');
      final coverUrl = await _repository.uploadJobCoverImage(coverImage.value!);

      // 2. Create micro job via Cloud Function
      EasyLoading.show(status: 'Creating job post...');
      await _repository.createMicroJob(
        title: titleController.text.trim(),
        details: detailsController.text.trim(),
        coverImage: coverUrl,
        jobLink: jobLinkController.text.trim(),
        limit: int.parse(limitController.text),
        perUserPrice: double.parse(perUserPriceController.text),
      );

      EasyLoading.showSuccess('Job post created!');

      // Refresh user data to update wallet
      try {
        UserController.instance.refreshUser();
      } catch (_) {}

      _resetForm();
      Get.back(result: true);
    } catch (e) {
      LoggerService.error('Failed to create micro job', e);
      EasyLoading.showError(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  void _resetForm() {
    titleController.clear();
    detailsController.clear();
    jobLinkController.clear();
    limitController.clear();
    perUserPriceController.clear();
    coverImage.value = null;
    totalPrice.value = 0;
    serviceFee.value = 0;
    basePrice.value = 0;
  }
}
