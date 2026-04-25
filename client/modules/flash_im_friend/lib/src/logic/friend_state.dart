import 'package:equatable/equatable.dart';
import '../data/friend.dart';

class FriendState extends Equatable {
  final List<Friend> friends;
  final List<FriendRequest> receivedRequests;
  final List<FriendRequest> sentRequests;
  final int pendingCount;
  final bool isLoading;
  final String? error;
  final Set<String> onlineIds;

  const FriendState({
    this.friends = const [],
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.pendingCount = 0,
    this.isLoading = false,
    this.error,
    this.onlineIds = const {},
  });

  FriendState copyWith({
    List<Friend>? friends,
    List<FriendRequest>? receivedRequests,
    List<FriendRequest>? sentRequests,
    int? pendingCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Set<String>? onlineIds,
  }) {
    return FriendState(
      friends: friends ?? this.friends,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      pendingCount: pendingCount ?? this.pendingCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      onlineIds: onlineIds ?? this.onlineIds,
    );
  }

  @override
  List<Object?> get props => [friends, receivedRequests, sentRequests, pendingCount, isLoading, error, onlineIds];
}
