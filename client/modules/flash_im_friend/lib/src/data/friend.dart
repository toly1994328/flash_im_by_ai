/// 好友（带用户信息）
class Friend {
  final String friendId;
  final String nickname;
  final String? avatar;
  final String? bio;
  final DateTime createdAt;

  const Friend({
    required this.friendId,
    required this.nickname,
    this.avatar,
    this.bio,
    required this.createdAt,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendId: json['friend_id'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 好友申请（带申请者/被申请者信息）
class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String? message;
  final int status;
  final String nickname;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.message,
    required this.status,
    required this.nickname,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      message: json['message'] as String?,
      status: json['status'] as int,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// 搜索结果用户
class SearchUser {
  final String id;
  final String nickname;
  final String? avatar;

  const SearchUser({
    required this.id,
    required this.nickname,
    this.avatar,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
    );
  }
}
