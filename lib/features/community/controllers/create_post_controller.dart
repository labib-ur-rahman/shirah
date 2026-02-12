import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/community/community_post_model.dart';
import 'package:shirah/data/models/community/post_author_model.dart';
import 'package:shirah/data/repositories/community_repository.dart';

/// Create Post Controller - Manages community post creation
/// Handles text input, image picking, privacy selection, and submission
class CreatePostController extends GetxController {
  static CreatePostController get instance => Get.find();

  // ==================== Dependencies ====================
  final CommunityRepository _repository = CommunityRepository.instance;

  /// Current user's author info (exposed for UI)
  PostAuthorModel get currentAuthor => _repository.currentAuthor;

  // ==================== Text Controller ====================
  final TextEditingController textController = TextEditingController();

  // ==================== Reactive State ====================

  /// Selected image file
  final Rx<File?> selectedImage = Rx<File?>(null);

  /// Selected privacy option
  final RxString selectedPrivacy = PostPrivacy.public_.obs;

  /// Loading state
  final RxBool isPosting = false.obs;

  /// Whether post button should be enabled
  bool get canPost =>
      textController.text.trim().isNotEmpty || selectedImage.value != null;

  // ==================== Image Picker ====================

  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      LoggerService.error('Failed to pick image', e);
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      LoggerService.error('Failed to capture image', e);
      Get.snackbar('Error', 'Failed to capture image');
    }
  }

  /// Remove selected image
  void removeImage() {
    selectedImage.value = null;
  }

  // ==================== Privacy Selection ====================

  /// Set post privacy
  void setPrivacy(String privacy) {
    selectedPrivacy.value = privacy;
  }

  // ==================== Post Submission ====================

  /// Submit the post
  Future<void> submitPost() async {
    if (!canPost) return;

    try {
      isPosting.value = true;
      EasyLoading.show(status: 'Posting...');

      await _repository.createPost(
        text: textController.text.trim(),
        privacy: selectedPrivacy.value,
        imageFile: selectedImage.value,
      );

      EasyLoading.showSuccess('Post shared!');

      // Clear form
      _resetForm();

      // Go back to feed
      Get.back(result: true);
    } catch (e) {
      LoggerService.error('Failed to submit post', e);
      EasyLoading.showError('Failed to create post');
    } finally {
      isPosting.value = false;
    }
  }

  /// Reset form fields
  void _resetForm() {
    textController.clear();
    selectedImage.value = null;
    selectedPrivacy.value = PostPrivacy.public_;
  }

  // ==================== Lifecycle ====================

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
