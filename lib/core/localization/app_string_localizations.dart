import 'package:get/get.dart';

/// App Strings - Centralized text constants for shirah localization
/// All text in the app should use these constants
class AppStrings {
  AppStrings._();

  // ==================== App Info ====================
  static String get appTitle => 'app_title'.tr;
  static String get appTagline => 'app_tagline'.tr;

  // ==================== Common ====================
  static String get error => 'error'.tr;
  static String get cancel => 'cancel'.tr;
  static String get ok => 'ok'.tr;
  static String get tryAgain => 'try_again'.tr;
  static String get loading => 'loading'.tr;
  static String get save => 'save'.tr;
  static String get done => 'done'.tr;
  static String get back => 'back'.tr;
  static String get next => 'next'.tr;
  static String get skip => 'skip'.tr;
  static String get continueText => 'continue'.tr;
  static String get submit => 'submit'.tr;
  static String get confirm => 'confirm'.tr;
  static String get close => 'close'.tr;
  static String get search => 'search'.tr;
  static String get filter => 'filter'.tr;
  static String get sort => 'sort'.tr;
  static String get refresh => 'refresh'.tr;
  static String get seeAll => 'see_all'.tr;
  static String get viewAll => 'view_all'.tr;
  static String get viewMore => 'view_more'.tr;
  static String get noData => 'no_data'.tr;
  static String get noResults => 'no_results'.tr;
  static String get comingSoon => 'coming_soon'.tr;
  static String get offline => 'offline'.tr;

  // ==================== Home Screen ====================
  static String get homeTitle => 'home_title'.tr;
  static String get welcomeMessage => 'welcome_message'.tr;
  static String get welcomeSubtitle => 'welcome_subtitle'.tr;
  static String get goodMorning => 'good_morning'.tr;
  static String get goodAfternoon => 'good_afternoon'.tr;
  static String get goodEvening => 'good_evening'.tr;
  static String get totalBalance => 'total_balance'.tr;
  static String get quickActions => 'quick_actions'.tr;
  static String get recentActivity => 'recent_activity'.tr;

  // ==================== Onboarding ====================
  static String get chooseTheme => 'choose_theme'.tr;
  static String get chooseThemeSubtitle => 'choose_theme_subtitle'.tr;
  static String get darkTheme => 'dark_theme'.tr;
  static String get lightTheme => 'light_theme'.tr;
  static String get systemTheme => 'system_theme'.tr;
  static String get darkThemeDesc => 'dark_theme_desc'.tr;
  static String get lightThemeDesc => 'light_theme_desc'.tr;
  static String get systemThemeDesc => 'system_theme_desc'.tr;
  static String get chooseLanguage => 'choose_language'.tr;
  static String get chooseLanguageSubtitle => 'choose_language_subtitle'.tr;
  static String get english => 'english'.tr;
  static String get bangla => 'bangla'.tr;
  static String get englishDesc => 'english_desc'.tr;
  static String get banglaDesc => 'bangla_desc'.tr;
  static String get getStarted => 'get_started'.tr;

  // Style Selection
  static String get chooseStyle => 'choose_style'.tr;
  static String get chooseStyleSubtitle => 'choose_style_subtitle'.tr;
  static String get styleShirah => 'style_shirah'.tr;
  static String get styleQuepal => 'style_quepal'.tr;
  static String get styleTimber => 'style_timber'.tr;
  static String get styleFlare => 'style_flare'.tr;
  static String get styleAmin => 'style_amin'.tr;
  static String get styleMidnight => 'style_midnight'.tr;
  static String get styleChanged => 'style_changed'.tr;

  // ==================== Authentication ====================
  static String get login => 'login'.tr;
  static String get loginTitle => 'login_title'.tr;
  static String get loginSubtitle => 'login_subtitle'.tr;
  static String get phoneNumber => 'phone_number'.tr;
  static String get enterPhone => 'enter_phone'.tr;
  static String get phoneHint => 'phone_hint'.tr;
  static String get invalidPhone => 'invalid_phone'.tr;
  static String get sendOtp => 'send_otp'.tr;
  static String get verifyOtp => 'verify_otp'.tr;
  static String get enterOtp => 'enter_otp'.tr;
  static String get otpSent => 'otp_sent'.tr;
  static String get otpSubtitle => 'otp_subtitle'.tr;
  static String get resendOtp => 'resend_otp'.tr;
  static String get resendIn => 'resend_in'.tr;
  static String get invalidOtp => 'invalid_otp'.tr;
  static String get verify => 'verify'.tr;
  static String get logout => 'logout'.tr;
  static String get logoutConfirm => 'logout_confirm'.tr;

  // Invite Code
  static String get haveInviteCode => 'have_invite_code'.tr;
  static String get enterInviteCode => 'enter_invite_code'.tr;
  static String get inviteCodeOptional => 'invite_code_optional'.tr;
  static String get invalidInviteCode => 'invalid_invite_code'.tr;

  // Profile Setup
  static String get setupProfile => 'setup_profile'.tr;
  static String get setupProfileSubtitle => 'setup_profile_subtitle'.tr;
  static String get yourName => 'your_name'.tr;
  static String get enterName => 'enter_name'.tr;
  static String get uploadPhoto => 'upload_photo'.tr;
  static String get changePhoto => 'change_photo'.tr;

  // ===== New Auth Flow =====
  static String get authSignInTitle => 'auth_sign_in_title'.tr;
  static String get authSignInSubtitle => 'auth_sign_in_subtitle'.tr;
  static String get authEmailHint => 'auth_email_hint'.tr;
  static String get authPasswordHint => 'auth_password_hint'.tr;
  static String get authPassword => 'auth_password'.tr;
  static String get authRememberMe => 'auth_remember_me'.tr;
  static String get authForgotPassword => 'auth_forgot_password'.tr;
  static String get authLogIn => 'auth_log_in'.tr;
  static String get authNoAccount => 'auth_no_account'.tr;
  static String get authSignUp => 'auth_sign_up'.tr;
  static String get authOrLoginWith => 'auth_or_login_with'.tr;
  static String get authOr => 'auth_or'.tr;
  static String get authFirstName => 'auth_first_name'.tr;
  static String get authLastNameOptional => 'auth_last_name_optional'.tr;
  static String get authPhoneHint => 'auth_phone_hint'.tr;
  static String get authConfirmPasswordHint => 'auth_confirm_password_hint'.tr;
  static String get authHaveAccount => 'auth_have_account'.tr;
  static String get authForgotPasswordTitle => 'auth_forgot_password_title'.tr;
  static String get authForgotPasswordDesc => 'auth_forgot_password_desc'.tr;
  static String get authEmailAddress => 'auth_email_address'.tr;
  static String get authSendResetLink => 'auth_send_reset_link'.tr;
  static String get authBackToLogin => 'auth_back_to_login'.tr;
  static String get authCheckEmailTitle => 'auth_check_email_title'.tr;
  static String get authCheckEmailSubtitle => 'auth_check_email_subtitle'.tr;
  static String get authCheckEmailInstructions =>
      'auth_check_email_instructions'.tr;
  static String get authTipLabel => 'auth_tip_label'.tr;
  static String get authCheckEmailTip => 'auth_check_email_tip'.tr;
  static String get authDidntReceiveEmail => 'auth_didnt_receive_email'.tr;
  static String get authResend => 'auth_resend'.tr;
  static String get authCompleteProfile => 'auth_complete_profile'.tr;
  static String get authCompleteProfileDesc => 'auth_complete_profile_desc'.tr;
  static String get authCompleteSignup => 'auth_complete_signup'.tr;
  static String get authInviteCodeTip => 'auth_invite_code_tip'.tr;
  static String get authCancelSignup => 'auth_cancel_signup'.tr;
  static String get authCancelSignupDesc => 'auth_cancel_signup_desc'.tr;
  static String get authStay => 'auth_stay'.tr;
  static String get authLeave => 'auth_leave'.tr;
  static String get authLoginSuccess => 'auth_login_success'.tr;
  static String get authSignupSuccess => 'auth_signup_success'.tr;
  static String get authPasswordResetSent => 'auth_password_reset_sent'.tr;
  static String get authLogoutSuccess => 'auth_logout_success'.tr;
  static String get authValidatingInviteCode =>
      'auth_validating_invite_code'.tr;
  static String get authCreatingAccount => 'auth_creating_account'.tr;

  // ==================== Wallet ====================
  static String get wallet => 'wallet'.tr;
  static String get walletBalance => 'wallet_balance'.tr;
  static String get rewardPoints => 'reward_points'.tr;
  static String get availableBalance => 'available_balance'.tr;
  static String get totalEarnings => 'total_earnings'.tr;
  static String get withdraw => 'withdraw'.tr;
  static String get deposit => 'deposit'.tr;
  static String get transfer => 'transfer'.tr;
  static String get convertPoints => 'convert_points'.tr;

  // Transactions
  static String get transactions => 'transactions'.tr;
  static String get transactionHistory => 'transaction_history'.tr;
  static String get noTransactions => 'no_transactions'.tr;
  static String get pending => 'pending'.tr;
  static String get completed => 'completed'.tr;
  static String get failed => 'failed'.tr;
  static String get cancelled => 'cancelled'.tr;

  // Withdrawal
  static String get withdrawFunds => 'withdraw_funds'.tr;
  static String get withdrawTo => 'withdraw_to'.tr;
  static String get enterAmount => 'enter_amount'.tr;
  static String get minWithdraw => 'min_withdraw'.tr;
  static String get withdrawMethod => 'withdraw_method'.tr;
  static String get accountNumber => 'account_number'.tr;
  static String get confirmWithdraw => 'confirm_withdraw'.tr;
  static String get withdrawalSuccess => 'withdrawal_success'.tr;
  static String get insufficientBalance => 'insufficient_balance'.tr;

  // Points Conversion
  static String get convertToBdt => 'convert_to_bdt'.tr;
  static String get pointsToConvert => 'points_to_convert'.tr;
  static String get youWillReceive => 'you_will_receive'.tr;
  static String get conversionRate => 'conversion_rate'.tr;
  static String get minConversion => 'min_conversion'.tr;
  static String get convert => 'convert'.tr;
  static String get conversionSuccess => 'conversion_success'.tr;
  static String get insufficientPoints => 'insufficient_points'.tr;

  // ==================== Rewards ====================
  static String get rewards => 'rewards'.tr;
  static String get earnRewards => 'earn_rewards'.tr;
  static String get yourRewards => 'your_rewards'.tr;
  static String get watchAds => 'watch_ads'.tr;
  static String get watchEarn => 'watch_earn'.tr;
  static String get dailyRewards => 'daily_rewards'.tr;

  // Streak
  static String get streak => 'streak'.tr;
  static String get currentStreak => 'current_streak'.tr;
  static String get longestStreak => 'longest_streak'.tr;
  static String get days => 'days'.tr;
  static String get dayStreak => 'day_streak'.tr;
  static String get keepStreak => 'keep_streak'.tr;
  static String get streakBonus => 'streak_bonus'.tr;
  static String get multiplier => 'multiplier'.tr;

  // Ads
  static String get adsWatchedToday => 'ads_watched_today'.tr;
  static String get pointsEarnedToday => 'points_earned_today'.tr;
  static String get dailyLimit => 'daily_limit'.tr;
  static String get adsRemaining => 'ads_remaining'.tr;
  static String get watchAdEarn => 'watch_ad_earn'.tr;
  static String get adNotReady => 'ad_not_ready'.tr;
  static String get dailyLimitReached => 'daily_limit_reached'.tr;

  // ==================== Recharge ====================
  static String get recharge => 'recharge'.tr;
  static String get mobileRecharge => 'mobile_recharge'.tr;
  static String get rechargeNow => 'recharge_now'.tr;
  static String get enterNumber => 'enter_number'.tr;
  static String get selectOperator => 'select_operator'.tr;
  static String get selectAmount => 'select_amount'.tr;
  static String get customAmount => 'custom_amount'.tr;
  static String get rechargeSuccess => 'recharge_success'.tr;
  static String get rechargeFailed => 'recharge_failed'.tr;
  static String get processingRecharge => 'processing_recharge'.tr;
  static String get confirmRecharge => 'confirm_recharge'.tr;
  static String get recentHistory => 'recent_history'.tr;
  static String get cashback => 'cashback'.tr;
  static String get prepaid => 'prepaid'.tr;
  static String get postpaid => 'postpaid'.tr;

  // ==================== Offers ====================
  static String get offers => 'offers'.tr;
  static String get telecomOffers => 'telecom_offers'.tr;
  static String get hotOffers => 'hot_offers'.tr;
  static String get internetPacks => 'internet_packs'.tr;
  static String get minutePacks => 'minute_packs'.tr;
  static String get comboPacks => 'combo_packs'.tr;
  static String get bundleOffers => 'bundle_offers'.tr;
  static String get validity => 'validity'.tr;
  static String get buyNow => 'buy_now'.tr;
  static String get driveOffers => 'drive_offers'.tr;
  static String get noOffersFound => 'no_offers_found'.tr;
  static String get smsPacks => 'sms_packs'.tr;

  // ==================== Reselling ====================
  static String get reselling => 'reselling'.tr;
  static String get products => 'products'.tr;
  static String get myOrders => 'my_orders'.tr;
  static String get shareEarn => 'share_earn'.tr;
  static String get productCommission => 'product_commission'.tr;
  static String get orderPlaced => 'order_placed'.tr;
  static String get orderShipped => 'order_shipped'.tr;
  static String get orderDelivered => 'order_delivered'.tr;

  // ==================== Micro Jobs ====================
  static String get microJobs => 'micro_jobs'.tr;
  static String get availableJobs => 'available_jobs'.tr;
  static String get myTasks => 'my_tasks'.tr;
  static String get jobDetails => 'job_details'.tr;
  static String get applyNow => 'apply_now'.tr;
  static String get taskSubmitted => 'task_submitted'.tr;
  static String get earnUpto => 'earn_upto'.tr;

  // ==================== Community ====================
  static String get community => 'community'.tr;
  static String get posts => 'posts'.tr;
  static String get createPost => 'create_post'.tr;
  static String get marketplace => 'marketplace'.tr;
  static String get whatsOnMind => 'whats_on_mind'.tr;
  static String get post => 'post'.tr;
  static String get like => 'like'.tr;
  static String get comment => 'comment'.tr;
  static String get share => 'share'.tr;
  static String get comments => 'comments'.tr;
  static String get writeComment => 'write_comment'.tr;

  // ==================== Profile ====================
  static String get profile => 'profile'.tr;
  static String get editProfile => 'edit_profile'.tr;
  static String get myProfile => 'my_profile'.tr;
  static String get account => 'account'.tr;
  static String get personalInfo => 'personal_info'.tr;
  static String get updateProfile => 'update_profile'.tr;
  static String get profileUpdated => 'profile_updated'.tr;

  // Invite & Referral
  static String get inviteFriends => 'invite_friends'.tr;
  static String get referrals => 'referrals'.tr;
  static String get yourInviteCode => 'your_invite_code'.tr;
  static String get shareInvite => 'share_invite'.tr;
  static String get copyCode => 'copy_code'.tr;
  static String get codeCopied => 'code_copied'.tr;
  static String get totalReferrals => 'total_referrals'.tr;
  static String get referralEarnings => 'referral_earnings'.tr;

  // Settings
  static String get settings => 'settings'.tr;
  static String get notifications => 'notifications'.tr;
  static String get language => 'language'.tr;
  static String get theme => 'theme'.tr;
  static String get about => 'about'.tr;
  static String get helpSupport => 'help_support'.tr;
  static String get privacyPolicy => 'privacy_policy'.tr;
  static String get termsConditions => 'terms_conditions'.tr;
  static String get rateApp => 'rate_app'.tr;
  static String get appVersion => 'app_version'.tr;

  // ==================== Verification ====================
  static String get verifyAccount => 'verify_account'.tr;
  static String get verified => 'verified'.tr;
  static String get notVerified => 'not_verified'.tr;
  static String get completeVerification => 'complete_verification'.tr;
  static String get verificationPending => 'verification_pending'.tr;
  static String get verificationApproved => 'verification_approved'.tr;
  static String get verificationRejected => 'verification_rejected'.tr;
  static String get verificationScreenTitle => 'verification_screen_title'.tr;
  static String get verificationAlreadyDone => 'verification_already_done'.tr;
  static String get verificationPlanTitle => 'verification_plan_title'.tr;
  static String get verificationPlanSubtitle => 'verification_plan_subtitle'.tr;
  static String get verificationOneTime => 'verification_one_time'.tr;
  static String get verificationLifetimeNote => 'verification_lifetime_note'.tr;
  static String get verificationGetVerified => 'verification_get_verified'.tr;
  static String get verificationComplete => 'verification_complete'.tr;
  static String get verificationIncomplete => 'verification_incomplete'.tr;
  static String get verificationNotSubscribed =>
      'verification_not_subscribed'.tr;
  static String get verificationBenefitsTitle =>
      'verification_benefits_title'.tr;
  static String get verificationBenefit1 => 'verification_benefit_1'.tr;
  static String get verificationBenefit1Desc =>
      'verification_benefit_1_desc'.tr;
  static String get verificationBenefit2 => 'verification_benefit_2'.tr;
  static String get verificationBenefit2Desc =>
      'verification_benefit_2_desc'.tr;
  static String get verificationBenefit3 => 'verification_benefit_3'.tr;
  static String get verificationBenefit3Desc =>
      'verification_benefit_3_desc'.tr;
  static String get verificationBenefit4 => 'verification_benefit_4'.tr;
  static String get verificationBenefit4Desc =>
      'verification_benefit_4_desc'.tr;
  static String get verificationBenefit5 => 'verification_benefit_5'.tr;
  static String get verificationBenefit5Desc =>
      'verification_benefit_5_desc'.tr;
  static String get verificationNoPayments => 'verification_no_payments'.tr;
  static String get verificationPaymentHistory =>
      'verification_payment_history'.tr;
  static String get verificationProcessing => 'verification_processing'.tr;
  static String get verificationSuccess => 'verification_success'.tr;
  static String get verifyFirst => 'verify_first'.tr;
  static String get paymentConfigError => 'payment_config_error'.tr;
  static String get paymentBeingProcessed => 'payment_being_processed'.tr;
  static String get paymentPendingMessage => 'payment_pending_message'.tr;
  static String get paymentCancelledMessage => 'payment_cancelled_message'.tr;
  static String get paymentFailedMessage => 'payment_failed_message'.tr;

  // ==================== Payment Result Dialog ====================
  static String get paymentResultDone => 'payment_result_done'.tr;
  static String get paymentResultRetry => 'payment_result_retry'.tr;
  static String get paymentResultClose => 'payment_result_close'.tr;
  static String get paymentResultTransactionId =>
      'payment_result_transaction_id'.tr;
  static String get paymentResultAmount => 'payment_result_amount'.tr;
  static String get paymentResultMethod => 'payment_result_method'.tr;
  static String get paymentResultVerifiedTitle =>
      'payment_result_verified_title'.tr;
  static String get paymentResultVerifiedMessage =>
      'payment_result_verified_message'.tr;
  static String get paymentResultSubscribedTitle =>
      'payment_result_subscribed_title'.tr;
  static String get paymentResultSubscribedMessage =>
      'payment_result_subscribed_message'.tr;
  static String get paymentResultPendingTitle =>
      'payment_result_pending_title'.tr;
  static String get paymentResultPendingMessage =>
      'payment_result_pending_message'.tr;
  static String get paymentResultCheckStatus =>
      'payment_result_check_status'.tr;
  static String get paymentCheckingStatus => 'payment_checking_status'.tr;
  static String get paymentStillPending => 'payment_still_pending'.tr;
  static String get paymentNowCompleted => 'payment_now_completed'.tr;
  static String get paymentStatusCheckFailed =>
      'payment_status_check_failed'.tr;
  static String get paymentResultFailedMessage =>
      'payment_result_failed_message'.tr;
  static String get paymentResultCancelledMessage =>
      'payment_result_cancelled_message'.tr;
  static String get paymentResultCongrats => 'payment_result_congrats'.tr;

  // ==================== Subscription ====================
  static String get subscription => 'subscription'.tr;
  static String get premium => 'premium'.tr;
  static String get subscribeNow => 'subscribe_now'.tr;
  static String get subscribed => 'subscribed'.tr;
  static String get subscriptionBenefits => 'subscription_benefits'.tr;
  static String get subscriptionExpires => 'subscription_expires'.tr;
  static String get subscriptionPlanTitle => 'subscription_plan_title'.tr;
  static String get subscriptionPlanSubtitle => 'subscription_plan_subtitle'.tr;
  static String get subscriptionMonthly => 'subscription_monthly'.tr;
  static String get subscriptionAlreadyActive =>
      'subscription_already_active'.tr;
  static String get subscriptionSuccess => 'subscription_success'.tr;
  static String get subscriptionIncludesVerification =>
      'subscription_includes_verification'.tr;

  // ==================== Error Messages ====================
  static String get networkError => 'network_error'.tr;
  static String get somethingWentWrong => 'something_went_wrong'.tr;
  static String get sessionExpired => 'session_expired'.tr;
  static String get permissionDenied => 'permission_denied'.tr;
  static String get featureLocked => 'feature_locked'.tr;

  // ==================== Success Messages ====================
  static String get success => 'success'.tr;
  static String get savedSuccessfully => 'saved_successfully'.tr;
  static String get updatedSuccessfully => 'updated_successfully'.tr;
  static String get deletedSuccessfully => 'deleted_successfully'.tr;

  // ==================== UI Actions ====================
  static String get toggleTheme => 'toggle_theme'.tr;
  static String get toggleLanguage => 'toggle_language'.tr;
  static String get themeChanged => 'theme_changed'.tr;
  static String get darkThemeEnabled => 'dark_theme_enabled'.tr;
  static String get lightThemeEnabled => 'light_theme_enabled'.tr;
  static String get languageChanged => 'language_changed'.tr;

  // ==================== Payment ====================
  static String get payment => 'payment'.tr;
  static String get paymentMethod => 'payment_method'.tr;
  static String get selectPaymentMethod => 'select_payment_method'.tr;
  static String get payNow => 'pay_now'.tr;
  static String get paymentSuccessful => 'payment_successful'.tr;
  static String get paymentFailed => 'payment_failed'.tr;
  static String get paymentCancelled => 'payment_cancelled'.tr;
  static String get processingPayment => 'processing_payment'.tr;

  // ==================== Onboarding Screens ====================
  static String get obWelcomeTitle => 'ob_welcome_title'.tr;
  static String get obWelcomeSubtitle => 'ob_welcome_subtitle'.tr;
  static String get obWelcomeDesc => 'ob_welcome_desc'.tr;
  static String get obHowWorksTitle => 'ob_how_works_title'.tr;
  static String get obHowWorksSubtitle => 'ob_how_works_subtitle'.tr;
  static String get obHowWorksDesc => 'ob_how_works_desc'.tr;
  static String get obTransparencyTitle => 'ob_transparency_title'.tr;
  static String get obTransparencySubtitle => 'ob_transparency_subtitle'.tr;
  static String get obTransparencyDesc => 'ob_transparency_desc'.tr;
  static String get obFeaturesTitle => 'ob_features_title'.tr;
  static String get obFeaturesSubtitle => 'ob_features_subtitle'.tr;
  static String get obFeature1 => 'ob_feature_1'.tr;
  static String get obFeature2 => 'ob_feature_2'.tr;
  static String get obFeature3 => 'ob_feature_3'.tr;
  static String get obFeature4 => 'ob_feature_4'.tr;
  static String get obFeature5 => 'ob_feature_5'.tr;
  static String get obFeature6 => 'ob_feature_6'.tr;
  static String get obFeature7 => 'ob_feature_7'.tr;
  static String get obFeature8 => 'ob_feature_8'.tr;
  static String get obFeature9 => 'ob_feature_9'.tr;
  static String get obFeature10 => 'ob_feature_10'.tr;
  static String get obFeature11 => 'ob_feature_11'.tr;
  static String get obFeature12 => 'ob_feature_12'.tr;

  // ==================== Home Feed ====================
  static String get feedEmpty => 'feed_empty'.tr;
  static String get feedEmptySubtitle => 'feed_empty_subtitle'.tr;
  static String get feedErrorSubtitle => 'feed_error_subtitle'.tr;
  static String get feedAdBadge => 'feed_ad_badge'.tr;
  static String get feedAdLoading => 'feed_ad_loading'.tr;
  static String get feedSponsoredBadge => 'feed_sponsored_badge'.tr;
  static String get feedAnnouncementBadge => 'feed_announcement_badge'.tr;
  static String get feedMicroJobBadge => 'feed_micro_job_badge'.tr;
  static String get feedCommunityPost => 'feed_community_post'.tr;
  static String get feedReselling => 'feed_reselling'.tr;
  static String get feedDriveOffer => 'feed_drive_offer'.tr;
  static String get feedOnDemand => 'feed_on_demand'.tr;
  static String get feedBuySell => 'feed_buy_sell'.tr;
  static String get feedAdsView => 'feed_ads_view'.tr;
  static String get feedAdsViewProgress => 'feed_ads_view_progress'.tr;
  static String get feedAdsViewComplete => 'feed_ads_view_complete'.tr;
  static String get feedAdsViewRemaining => 'feed_ads_view_remaining'.tr;
  static String get feedSuggestedFollowing => 'feed_suggested_following'.tr;
  static String get feedLoadMore => 'feed_load_more'.tr;
  static String get feedEndOfFeed => 'feed_end_of_feed'.tr;

  // ==================== Admin Feed Management ====================
  static String get adminFeedTitle => 'admin_feed_title'.tr;
  static String get adminFeedSubtitle => 'admin_feed_subtitle'.tr;
  static String get adminFeedAll => 'admin_feed_all'.tr;
  static String get adminFeedActive => 'admin_feed_active'.tr;
  static String get adminFeedDisabled => 'admin_feed_disabled'.tr;
  static String get adminFeedHidden => 'admin_feed_hidden'.tr;
  static String get adminFeedRemoved => 'admin_feed_removed'.tr;
  static String get adminFeedTotalItems => 'admin_feed_total_items'.tr;
  static String get adminFeedActiveItems => 'admin_feed_active_items'.tr;
  static String get adminFeedAdsCount => 'admin_feed_ads_count'.tr;
  static String get adminFeedDisabledCount => 'admin_feed_disabled_count'.tr;
  static String get adminFeedEmpty => 'admin_feed_empty'.tr;
  static String get adminFeedEmptySubtitle => 'admin_feed_empty_subtitle'.tr;
  static String get adminFeedType => 'admin_feed_type'.tr;
  static String get adminFeedStatus => 'admin_feed_status'.tr;
  static String get adminFeedPriority => 'admin_feed_priority'.tr;
  static String get adminFeedVisibility => 'admin_feed_visibility'.tr;
  static String get adminFeedCreatedAt => 'admin_feed_created_at'.tr;
  static String get adminFeedRefId => 'admin_feed_ref_id'.tr;
  static String get adminFeedAuthorId => 'admin_feed_author_id'.tr;
  static String get adminFeedPinned => 'admin_feed_pinned'.tr;
  static String get adminFeedBoosted => 'admin_feed_boosted'.tr;
  static String get adminFeedChangeStatus => 'admin_feed_change_status'.tr;
  static String get adminFeedChangePriority => 'admin_feed_change_priority'.tr;
  static String get adminFeedStatusReason => 'admin_feed_status_reason'.tr;
  static String get adminFeedStatusUpdated => 'admin_feed_status_updated'.tr;
  static String get adminFeedPriorityUpdated =>
      'admin_feed_priority_updated'.tr;
  static String get adminFeedConfirmRemove => 'admin_feed_confirm_remove'.tr;
  static String get adminFeedConfirmDisable => 'admin_feed_confirm_disable'.tr;
  static String get adminFeedDetailTitle => 'admin_feed_detail_title'.tr;
  static String get adminFeedFilterByType => 'admin_feed_filter_by_type'.tr;
  static String get adminFeedFilterByStatus => 'admin_feed_filter_by_status'.tr;
  static String get adminFeedSearchHint => 'admin_feed_search_hint'.tr;
  static String get adminFeedPriorityLow => 'admin_feed_priority_low'.tr;
  static String get adminFeedPriorityNormal => 'admin_feed_priority_normal'.tr;
  static String get adminFeedPriorityImportant =>
      'admin_feed_priority_important'.tr;
  static String get adminFeedPriorityCritical =>
      'admin_feed_priority_critical'.tr;
  static String get adminFeedNoRef => 'admin_feed_no_ref'.tr;
  static String get adminFeedActions => 'admin_feed_actions'.tr;

  // ==================== Admin Native Ad Management ====================
  static String get adminNativeAdTitle => 'admin_native_ad_title'.tr;
  static String get adminNativeAdSubtitle => 'admin_native_ad_subtitle'.tr;
  static String get adminNativeAdCreate => 'admin_native_ad_create'.tr;
  static String get adminNativeAdCreateSubtitle =>
      'admin_native_ad_create_subtitle'.tr;
  static String get adminNativeAdUnitId => 'admin_native_ad_unit_id'.tr;
  static String get adminNativeAdUnitIdHint =>
      'admin_native_ad_unit_id_hint'.tr;
  static String get adminNativeAdPlatform => 'admin_native_ad_platform'.tr;
  static String get adminNativeAdPlatformHint =>
      'admin_native_ad_platform_hint'.tr;
  static String get adminNativeAdMinGap => 'admin_native_ad_min_gap'.tr;
  static String get adminNativeAdMinGapHint =>
      'admin_native_ad_min_gap_hint'.tr;
  static String get adminNativeAdMaxPerSession =>
      'admin_native_ad_max_per_session'.tr;
  static String get adminNativeAdMaxPerSessionHint =>
      'admin_native_ad_max_per_session_hint'.tr;
  static String get adminNativeAdCreated => 'admin_native_ad_created'.tr;
  static String get adminNativeAdAndroid => 'admin_native_ad_android'.tr;
  static String get adminNativeAdIos => 'admin_native_ad_ios'.tr;
  static String get adminNativeAdBoth => 'admin_native_ad_both'.tr;
  static String get adminNativeAdRules => 'admin_native_ad_rules'.tr;
  static String get adminNativeAdEmergencyPause =>
      'admin_native_ad_emergency_pause'.tr;
  static String get adminNativeAdEmergencyPauseDesc =>
      'admin_native_ad_emergency_pause_desc'.tr;
  static String get adminNativeAdActiveAds => 'admin_native_ad_active_ads'.tr;
  static String get adminNativeAdNoAds => 'admin_native_ad_no_ads'.tr;
  static String get adminNativeAdNoAdsSubtitle =>
      'admin_native_ad_no_ads_subtitle'.tr;

  // ==================== User Profile Screen ====================
  static String get profileFollowers => 'profile_followers'.tr;
  static String get profileFollowing => 'profile_following'.tr;
  static String get profileCommunityMembers => 'profile_community_members'.tr;
  static String get profileSellNow => 'profile_sell_now'.tr;
  static String get profileWholesale => 'profile_wholesale'.tr;
  static String get profileMaxSelling => 'profile_max_selling'.tr;
  static String get profileYourEarningUpto => 'profile_your_earning_upto'.tr;
  static String get profilePerSale => 'profile_per_sale'.tr;
  static String get profileJobPost => 'profile_job_post'.tr;
  static String get profileColors => 'profile_colors'.tr;
  static String get profileSizes => 'profile_sizes'.tr;
  static String get profileTabCommunity => 'profile_tab_community'.tr;
  static String get profileTabBuySell => 'profile_tab_buy_sell'.tr;
  static String get profileTabJobPost => 'profile_tab_job_post'.tr;
  static String get profileTabProducts => 'profile_tab_products'.tr;
  static String get profileBioAdd => 'profile_bio_add'.tr;
  static String get profileBioEmpty => 'profile_bio_empty'.tr;
  static String get profileBioEdit => 'profile_bio_edit'.tr;
  static String get profileBioDialogTitle => 'profile_bio_dialog_title'.tr;
  static String get profileBioHint => 'profile_bio_hint'.tr;
  static String get profileBioSave => 'profile_bio_save'.tr;
  static String get profileBioSaving => 'profile_bio_saving'.tr;
  static String get profileBioSaved => 'profile_bio_saved'.tr;
  static String get profileBioError => 'profile_bio_error'.tr;
  static String get profileBioMaxChars => 'profile_bio_max_chars'.tr;

  // ── Image Picker ────────────────────────────────────────────
  static String get pickerProfilePhoto => 'picker_profile_photo'.tr;
  static String get pickerCoverPhoto => 'picker_cover_photo'.tr;
  static String get pickerGallery => 'picker_gallery'.tr;
  static String get pickerCamera => 'picker_camera'.tr;
  static String get pickerUploadingAvatar => 'picker_uploading_avatar'.tr;
  static String get pickerUploadingCover => 'picker_uploading_cover'.tr;
  static String get pickerAvatarSuccess => 'picker_avatar_success'.tr;
  static String get pickerCoverSuccess => 'picker_cover_success'.tr;
  static String get pickerUploadFailed => 'picker_upload_failed'.tr;
  static String get pickerPermissionDenied => 'picker_permission_denied'.tr;
  static String get pickerPermissionGalleryMsg =>
      'picker_permission_gallery_msg'.tr;
  static String get pickerPermissionCameraMsg =>
      'picker_permission_camera_msg'.tr;
  static String get pickerOpenSettings => 'picker_open_settings'.tr;

  // ── Edit Profile ─────────────────────────────────────────────
  static String get editProfileTitle => 'edit_profile_title'.tr;
  static String get editFirstName => 'edit_first_name'.tr;
  static String get editLastName => 'edit_last_name'.tr;
  static String get editPhone => 'edit_phone'.tr;
  static String get editPhoneHint => 'edit_phone_hint'.tr;
  static String get editSaveChanges => 'edit_save_changes'.tr;
  static String get editProfileSuccess => 'edit_profile_success'.tr;
  static String get editProfileFailed => 'edit_profile_failed'.tr;
  static String get editNameRequired => 'edit_name_required'.tr;

  // ── Community ────────────────────────────────────────────────
  static String get communityMembersLabel => 'community_members'.tr;
}
