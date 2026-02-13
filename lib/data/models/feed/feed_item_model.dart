import 'package:cloud_firestore/cloud_firestore.dart';

/// Feed Item Type ENUM - System Contract
/// Defines all possible feed item types in the home feed
class FeedItemType {
  FeedItemType._();

  // ====== Running Feed Types ======
  static const String communityPost = 'COMMUNITY_POST';
  static const String microJob = 'MICRO_JOB';

  // ====== Upcoming Feed Types (Future-ready) ======
  static const String reselling = 'RESELLING';
  static const String driveOffer = 'DRIVE_OFFER';
  static const String suggestedFollowing = 'SUGGESTED_FOLLOWING';
  static const String onDemandPost = 'ON_DEMAND_POST';
  static const String buySellPost = 'BUY_SELL_POST';
  static const String sponsored = 'SPONSORED';
  static const String adsView = 'ADS_VIEW';
  static const String nativeAd = 'NATIVE_AD';
  static const String announcement = 'ANNOUNCEMENT';

  /// All valid feed types
  static const List<String> all = [
    communityPost,
    microJob,
    reselling,
    driveOffer,
    suggestedFollowing,
    onDemandPost,
    buySellPost,
    sponsored,
    adsView,
    nativeAd,
    announcement,
  ];

  /// Check if a type is valid
  static bool isValid(String type) => all.contains(type);
}

/// Feed Visibility ENUM
class FeedVisibility {
  FeedVisibility._();

  static const String public_ = 'PUBLIC';
  static const String friends = 'FRIENDS';
  static const String onlyMe = 'ONLY_ME';
}

/// Feed Status ENUM
class FeedStatus {
  FeedStatus._();

  static const String active = 'ACTIVE';
  static const String disabled = 'DISABLED';
  static const String hidden = 'HIDDEN';
  static const String removed = 'REMOVED';
}

/// Feed Priority Values (Semantic)
class FeedPriority {
  FeedPriority._();

  static const int low = 5;
  static const int normal = 10; // Community Post
  static const int important = 20; // Micro Job
  static const int critical = 30; // Native Ad / Sponsored

  /// Get default priority for a feed type
  static int forType(String type) {
    switch (type) {
      case FeedItemType.communityPost:
      case FeedItemType.onDemandPost:
      case FeedItemType.buySellPost:
      case FeedItemType.announcement:
        return normal;
      case FeedItemType.microJob:
      case FeedItemType.reselling:
      case FeedItemType.driveOffer:
        return important;
      case FeedItemType.nativeAd:
      case FeedItemType.sponsored:
      case FeedItemType.adsView:
        return critical;
      case FeedItemType.suggestedFollowing:
        return low;
      default:
        return normal;
    }
  }
}

/// Feed Meta Model - Extension-safe container for feed metadata
class FeedMetaModel {
  final String? authorId;
  final bool adminPinned;
  final bool boosted;
  final String? adUnitId;
  final String? platform;
  final bool emergencyPause;

  const FeedMetaModel({
    this.authorId,
    this.adminPinned = false,
    this.boosted = false,
    this.adUnitId,
    this.platform,
    this.emergencyPause = false,
  });

  factory FeedMetaModel.empty() => const FeedMetaModel();

  factory FeedMetaModel.fromMap(Map<String, dynamic> data) {
    return FeedMetaModel(
      authorId: data['authorId'] as String?,
      adminPinned: data['adminPinned'] as bool? ?? false,
      boosted: data['boosted'] as bool? ?? false,
      adUnitId: data['adUnitId'] as String?,
      platform: data['platform'] as String?,
      emergencyPause: data['emergencyPause'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (authorId != null) 'authorId': authorId,
      'adminPinned': adminPinned,
      'boosted': boosted,
      if (adUnitId != null) 'adUnitId': adUnitId,
      if (platform != null) 'platform': platform,
      'emergencyPause': emergencyPause,
    };
  }
}

/// Feed Rules Model - Ad gap & frequency rules
class FeedRulesModel {
  final int minGap;
  final int maxPerSession;

  const FeedRulesModel({this.minGap = 6, this.maxPerSession = 3});

  factory FeedRulesModel.fromMap(Map<String, dynamic> data) {
    return FeedRulesModel(
      minGap: data['minGap'] as int? ?? 6,
      maxPerSession: data['maxPerSession'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {'minGap': minGap, 'maxPerSession': maxPerSession};
  }
}

/// Feed Item Model - Represents a single document in /home_feeds collection
/// This is the AUTHORITATIVE feed index. Content lives in referenced collections.
///
/// Collection: home_feeds/{feedId}
class FeedItemModel {
  final String feedId;
  final String type;
  final String? refId;
  final int priority;
  final String status;
  final String visibility;
  final DateTime createdAt;
  final FeedMetaModel meta;
  final FeedRulesModel? rules;

  /// Firestore document snapshot for cursor-based pagination
  DocumentSnapshot? documentSnapshot;

  FeedItemModel({
    required this.feedId,
    required this.type,
    this.refId,
    required this.priority,
    required this.status,
    required this.visibility,
    required this.createdAt,
    required this.meta,
    this.rules,
    this.documentSnapshot,
  });

  /// Empty model for initialization
  factory FeedItemModel.empty() {
    return FeedItemModel(
      feedId: '',
      type: FeedItemType.communityPost,
      priority: FeedPriority.normal,
      status: FeedStatus.active,
      visibility: FeedVisibility.public_,
      createdAt: DateTime.now(),
      meta: FeedMetaModel.empty(),
    );
  }

  /// Create from Firestore document
  factory FeedItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final model = FeedItemModel(
      feedId: doc.id,
      type: data['type'] as String? ?? FeedItemType.communityPost,
      refId: data['refId'] as String?,
      priority: data['priority'] as int? ?? FeedPriority.normal,
      status: data['status'] as String? ?? FeedStatus.active,
      visibility: data['visibility'] as String? ?? FeedVisibility.public_,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      meta: FeedMetaModel.fromMap(data['meta'] as Map<String, dynamic>? ?? {}),
      rules: data['rules'] != null
          ? FeedRulesModel.fromMap(data['rules'] as Map<String, dynamic>)
          : null,
    );
    model.documentSnapshot = doc;
    return model;
  }

  /// Create from plain Map (used when data comes from Cloud Functions)
  factory FeedItemModel.fromMap(Map<String, dynamic> data) {
    // Handle createdAt from Cloud Functions (can be Timestamp map or string)
    DateTime createdAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is Map) {
      // Firestore Timestamp serialized as {_seconds, _nanoseconds}
      final seconds = rawCreatedAt['_seconds'] as int? ?? 0;
      createdAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return FeedItemModel(
      feedId: data['feedId'] as String? ?? '',
      type: data['type'] as String? ?? FeedItemType.communityPost,
      refId: data['refId'] as String?,
      priority: data['priority'] as int? ?? FeedPriority.normal,
      status: data['status'] as String? ?? FeedStatus.active,
      visibility: data['visibility'] as String? ?? FeedVisibility.public_,
      createdAt: createdAt,
      meta: FeedMetaModel.fromMap(data['meta'] as Map<String, dynamic>? ?? {}),
      rules: data['rules'] != null
          ? FeedRulesModel.fromMap(
              Map<String, dynamic>.from(data['rules'] as Map),
            )
          : null,
    );
  }

  /// Convert to Firestore document (for creating new feed item)
  Map<String, dynamic> toCreateMap() {
    return {
      'feedId': feedId,
      'type': type,
      'refId': refId,
      'priority': priority,
      'status': status,
      'visibility': visibility,
      'createdAt': FieldValue.serverTimestamp(),
      'meta': meta.toMap(),
      if (rules != null) 'rules': rules!.toMap(),
    };
  }

  /// Convert to full map (for updates)
  Map<String, dynamic> toMap() {
    return {
      'feedId': feedId,
      'type': type,
      'refId': refId,
      'priority': priority,
      'status': status,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      'meta': meta.toMap(),
      if (rules != null) 'rules': rules!.toMap(),
    };
  }

  /// Check if this feed item is a community post
  bool get isCommunityPost => type == FeedItemType.communityPost;

  /// Check if this feed item is a micro job
  bool get isMicroJob => type == FeedItemType.microJob;

  /// Check if this feed item is a native ad
  bool get isNativeAd => type == FeedItemType.nativeAd;

  /// Check if this feed item is sponsored
  bool get isSponsored => type == FeedItemType.sponsored;

  /// Check if this feed item is active
  bool get isActive => status == FeedStatus.active;

  @override
  String toString() =>
      'FeedItemModel(feedId: $feedId, type: $type, refId: $refId, priority: $priority, status: $status)';
}
