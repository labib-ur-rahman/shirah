import 'package:get/get.dart';
import 'package:shirah/core/services/cloud_functions_service.dart';
import 'package:shirah/core/services/connectivity_service.dart';
import 'package:shirah/core/services/firebase_service.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/core/utils/manager/network_manager.dart';
import 'package:shirah/data/repositories/community_repository.dart';
import 'package:shirah/data/repositories/home_feed_repository.dart';
import 'package:shirah/data/repositories/micro_job_repository.dart';
import 'package:shirah/features/authentication/controllers/auth_controller.dart';
import 'package:shirah/features/community/controllers/feed_controller.dart';
import 'package:shirah/features/home/controllers/home_controller.dart';
import 'package:shirah/features/home/controllers/home_feed_controller.dart';
import 'package:shirah/features/main/controllers/main_header_controller.dart';
import 'package:shirah/features/micro_jobs/controllers/micro_job_controller.dart';
import 'package:shirah/features/micro_jobs/controllers/my_created_jobs_controller.dart';
import 'package:shirah/features/micro_jobs/controllers/worker_submissions_controller.dart';
import 'package:shirah/features/personalization/onboarding/controllers/style_controller.dart';
import 'package:shirah/features/personalization/onboarding/controllers/theme_controller.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';
import 'package:shirah/features/rewards/controllers/reward_controller.dart';
import 'package:shirah/features/wallet/controllers/wallet_controller.dart';

/// Initial Binding - Sets up initial dependencies when app starts
/// This binding is called when the app launches and sets up global controllers
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ==================== Firebase Service (MUST BE FIRST) ====================
    // Firebase Service - All Firebase operations
    Get.put<FirebaseService>(FirebaseService(), permanent: true);

    // Cloud Functions Service - All Cloud Functions calls
    Get.put<CloudFunctionsService>(CloudFunctionsService(), permanent: true);

    // ==================== Core Services ====================
    // Theme Service - Enterprise-level theme management (MUST BE EARLY)
    Get.put<ThemeService>(ThemeService(), permanent: true);

    // Network Manager - Internet connectivity monitoring
    Get.put<NetworkManager>(NetworkManager(), permanent: true);

    // Connectivity Service - Network monitoring
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);

    // ==================== Onboarding ====================
    // Style Controller - App style management
    Get.put<StyleController>(StyleController(), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);

    // ==================== Main Navigation ====================
    // Main Header Controller - Tab bar navigation
    Get.put<MainHeaderController>(MainHeaderController(), permanent: true);

    // ==================== Authentication ====================
    // Auth Controller - Firebase auth state management
    Get.put<AuthController>(AuthController(), permanent: true);

    // ==================== User ====================
    // User Controller - Current user data management
    Get.lazyPut<UserController>(() => UserController(), fenix: true);

    // ==================== Wallet ====================
    // Wallet Controller - Wallet and transactions
    Get.lazyPut<WalletController>(() => WalletController(), fenix: true);

    // ==================== Rewards ====================
    // Reward Controller - Streaks and reward points
    Get.lazyPut<RewardController>(() => RewardController(), fenix: true);

    // ==================== Home ====================
    // Home Controller - Main app controller
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

    // Home Feed Repository - Firebase operations for unified feed
    Get.put<HomeFeedRepository>(HomeFeedRepository(), permanent: true);

    // Home Feed Controller - Unified feed state management
    Get.lazyPut<HomeFeedController>(() => HomeFeedController(), fenix: true);

    // ==================== Community ====================
    // Community Repository - Firebase operations for posts/comments/reactions
    Get.put<CommunityRepository>(CommunityRepository(), permanent: true);

    // Feed Controller - Community feed state management
    Get.lazyPut<FeedController>(() => FeedController(), fenix: true);

    // ==================== Micro Jobs ====================
    // Micro Job Repository - Firebase operations for jobs/submissions
    Get.put<MicroJobRepository>(MicroJobRepository(), permanent: true);

    // Micro Job Controller - Job listing, detail, and proof submission
    Get.lazyPut<MicroJobController>(() => MicroJobController(), fenix: true);

    // My Created Jobs Controller - Author's job management and submission reviews
    Get.lazyPut<MyCreatedJobsController>(
      () => MyCreatedJobsController(),
      fenix: true,
    );

    // Worker Submissions Controller - Worker's own submission history
    Get.lazyPut<WorkerSubmissionsController>(
      () => WorkerSubmissionsController(),
      fenix: true,
    );

  }
}
