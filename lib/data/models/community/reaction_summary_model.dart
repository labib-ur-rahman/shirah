import 'package:shirah/core/utils/constants/image_path.dart';

/// Reaction Summary Model - Aggregated reaction counts for a post or comment
/// Matches ReactionType enum: LIKE, LOVE, INSIGHTFUL, SUPPORT, INSPIRING
class ReactionSummaryModel {
  final int total;
  final int like;
  final int love;
  final int insightful;
  final int support;
  final int inspiring;

  const ReactionSummaryModel({
    required this.total,
    required this.like,
    required this.love,
    required this.insightful,
    required this.support,
    required this.inspiring,
  });

  factory ReactionSummaryModel.empty() {
    return const ReactionSummaryModel(
      total: 0,
      like: 0,
      love: 0,
      insightful: 0,
      support: 0,
      inspiring: 0,
    );
  }

  factory ReactionSummaryModel.fromMap(Map<String, dynamic> data) {
    return ReactionSummaryModel(
      total: data['total'] as int? ?? 0,
      like: data['like'] as int? ?? 0,
      love: data['love'] as int? ?? 0,
      insightful: data['insightful'] as int? ?? 0,
      support: data['support'] as int? ?? 0,
      inspiring: data['inspiring'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'like': like,
      'love': love,
      'insightful': insightful,
      'support': support,
      'inspiring': inspiring,
    };
  }

  /// Get top 3 reaction types that have counts > 0
  List<String> get topReactions {
    final map = {
      'like': like,
      'love': love,
      'insightful': insightful,
      'support': support,
      'inspiring': inspiring,
    };
    final sorted = map.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Get emoji for reaction type
  static String emoji(String type) {
    switch (type.toUpperCase()) {
      case 'LIKE':
        return ImagePath.reactionLike;
      case 'LOVE':
        return ImagePath.reactionLove;
      case 'INSIGHTFUL':
        return ImagePath.reactionInsightful;
      case 'SUPPORT':
        return ImagePath.reactionSupport;
      case 'INSPIRING':
        return ImagePath.reactionInspiring;
      default:
        return ImagePath.reactionLike;
    }
  }
}

/// Reaction types matching Firestore/Cloud Functions enum
class ReactionType {
  ReactionType._();
  static const String like = 'LIKE';
  static const String love = 'LOVE';
  static const String insightful = 'INSIGHTFUL';
  static const String support = 'SUPPORT';
  static const String inspiring = 'INSPIRING';

  static List<String> get values => [
    like,
    love,
    insightful,
    support,
    inspiring,
  ];

  static String displayName(String type) {
    switch (type) {
      case love:
        return 'Love';
      case insightful:
        return 'Insightful';
      case support:
        return 'Support';
      case inspiring:
        return 'Inspiring';
      default:
        return 'Like';
    }
  }

  static String emoji(String type) => ReactionSummaryModel.emoji(type);
}
