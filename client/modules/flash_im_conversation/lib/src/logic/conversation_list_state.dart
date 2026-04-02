import 'package:equatable/equatable.dart';
import '../data/conversation.dart';

sealed class ConversationListState extends Equatable {
  const ConversationListState();

  @override
  List<Object?> get props => [];
}

class ConversationListInitial extends ConversationListState {
  const ConversationListInitial();
}

class ConversationListLoading extends ConversationListState {
  const ConversationListLoading();
}

class ConversationListLoaded extends ConversationListState {
  final List<Conversation> conversations;
  final bool hasMore;
  final int totalUnread;

  const ConversationListLoaded(this.conversations, {this.hasMore = false, this.totalUnread = 0});

  @override
  List<Object?> get props => [conversations, hasMore, totalUnread];
}

class ConversationListError extends ConversationListState {
  final String message;

  const ConversationListError(this.message);

  @override
  List<Object?> get props => [message];
}
