import 'package:equatable/equatable.dart';
import '../data/message.dart';

enum FileDownloadStatus { idle, downloading, done, error }

class FileDownloadInfo extends Equatable {
  final FileDownloadStatus status;
  final double progress;
  final String? localPath;
  final String? error;

  const FileDownloadInfo({
    this.status = FileDownloadStatus.idle,
    this.progress = 0,
    this.localPath,
    this.error,
  });

  FileDownloadInfo copyWith({
    FileDownloadStatus? status,
    double? progress,
    String? localPath,
    String? error,
  }) => FileDownloadInfo(
    status: status ?? this.status,
    progress: progress ?? this.progress,
    localPath: localPath ?? this.localPath,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, progress, localPath, error];
}

sealed class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool hasMore;
  final bool isLoadingMore;
  final double? uploadProgress;
  final Map<String, FileDownloadInfo> fileDownloads;

  const ChatLoaded({
    required this.messages,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.uploadProgress,
    this.fileDownloads = const {},
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    bool? hasMore,
    bool? isLoadingMore,
    double? uploadProgress,
    bool clearUploadProgress = false,
    Map<String, FileDownloadInfo>? fileDownloads,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      uploadProgress: clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      fileDownloads: fileDownloads ?? this.fileDownloads,
    );
  }

  @override
  List<Object?> get props => [messages, hasMore, isLoadingMore, uploadProgress, fileDownloads];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}
