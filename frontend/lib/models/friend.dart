import 'enums.dart';

/// Дос өтінімі (offline режімде Hive-та сақталады).
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest copyWith({FriendRequestStatus? status}) => FriendRequest(
        id: id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: json['id'] as String,
        fromUserId: json['from_user_id'] as String,
        toUserId: json['to_user_id'] as String,
        status: FriendRequestStatus.fromName(json['status'] as String?),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
