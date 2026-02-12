import 'package:cloud_firestore/cloud_firestore.dart';

/// User System Model - Admin-controlled system fields
/// Stored in: users/{uid}.system
class UserSystemModel {
  /// Reason for ban (null if not banned)
  final String? banReason;

  /// Suspension expiry timestamp (null if not suspended)
  final DateTime? suspendUntil;

  /// Admin notes about this user
  final String notes;

  const UserSystemModel({this.banReason, this.suspendUntil, this.notes = ''});

  /// Empty system fields
  factory UserSystemModel.empty() {
    return const UserSystemModel(
      banReason: null,
      suspendUntil: null,
      notes: '',
    );
  }

  /// Create from map
  factory UserSystemModel.fromMap(Map<String, dynamic> map) {
    DateTime? suspendUntil;
    if (map['suspendUntil'] != null) {
      if (map['suspendUntil'] is Timestamp) {
        suspendUntil = (map['suspendUntil'] as Timestamp).toDate();
      } else if (map['suspendUntil'] is String) {
        suspendUntil = DateTime.tryParse(map['suspendUntil'] as String);
      }
    }

    return UserSystemModel(
      banReason: map['banReason']?.toString(),
      suspendUntil: suspendUntil,
      notes: map['notes']?.toString() ?? '',
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'banReason': banReason,
      'suspendUntil': suspendUntil != null
          ? Timestamp.fromDate(suspendUntil!)
          : null,
      'notes': notes,
    };
  }

  /// Copy with
  UserSystemModel copyWith({
    String? banReason,
    DateTime? suspendUntil,
    String? notes,
  }) {
    return UserSystemModel(
      banReason: banReason ?? this.banReason,
      suspendUntil: suspendUntil ?? this.suspendUntil,
      notes: notes ?? this.notes,
    );
  }

  /// Check if user is currently suspended
  bool get isSuspended {
    if (suspendUntil == null) return false;
    return DateTime.now().isBefore(suspendUntil!);
  }

  /// Check if user has ban reason
  bool get isBanned => banReason != null && banReason!.isNotEmpty;

  /// Check if user has admin notes
  bool get hasNotes => notes.isNotEmpty;
}
