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

  const ConversationListLoaded(this.conversations, {this.hasMore = false});

  @override
  List<Object?> get props => [conversations, hasMore];
}

class ConversationListError extends ConversationListState {
  final String message;

  const ConversationListError(this.message);

  @override
  List<Object?> get props => [message];
}
