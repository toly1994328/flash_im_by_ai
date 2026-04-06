import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/message.dart';
import '../logic/chat_cubit.dart';
import '../logic/chat_state.dart';

class FilePreviewPage extends StatelessWidget {
  final String messageId;
  final FileExtra fileExtra;
  final String baseUrl;

  const FilePreviewPage({
    super.key,
    required this.messageId,
    required this.fileExtra,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文件详情')),
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          final dlInfo = (state is ChatLoaded)
              ? state.fileDownloads[messageId]
              : null;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFileIcon(fileExtra.fileType),
                  const SizedBox(height: 16),
                  Text(fileExtra.fileName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center, maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(fileExtra.formattedSize,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                  const SizedBox(height: 4),
                  Text(fileExtra.fileType.toUpperCase(),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                  const SizedBox(height: 32),
                  _buildAction(context, dlInfo),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAction(BuildContext context, FileDownloadInfo? dlInfo) {
    final status = dlInfo?.status ?? FileDownloadStatus.idle;

    return switch (status) {
      FileDownloadStatus.idle => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _startDownload(context),
          icon: const Icon(Icons.download),
          label: const Text('下载'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      FileDownloadStatus.downloading => Column(
        children: [
          LinearProgressIndicator(
            value: dlInfo!.progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 8),
          Text('${(dlInfo.progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        ],
      ),
      FileDownloadStatus.done => Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(height: 8),
          const Text('下载完成', style: TextStyle(color: Colors.green, fontSize: 14)),
          if (dlInfo?.localPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(dlInfo!.localPath!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                textAlign: TextAlign.center),
            ),
        ],
      ),
      FileDownloadStatus.error => Column(
        children: [
          Text(dlInfo?.error ?? '下载失败',
            style: const TextStyle(color: Colors.red, fontSize: 14)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => _startDownload(context), child: const Text('重试')),
        ],
      ),
    };
  }

  void _startDownload(BuildContext context) {
    final fullUrl = fileExtra.fileUrl.startsWith('/')
        ? '$baseUrl${fileExtra.fileUrl}'
        : fileExtra.fileUrl;
    context.read<ChatCubit>().downloadFile(messageId, fullUrl, fileExtra.fileName);
  }

  Widget _buildFileIcon(String fileType) {
    final (IconData icon, Color color) = switch (fileType.toLowerCase()) {
      'pdf' => (Icons.picture_as_pdf, Colors.red),
      'doc' || 'docx' => (Icons.description, Colors.blue),
      'xls' || 'xlsx' || 'csv' => (Icons.table_chart, Colors.green),
      'ppt' || 'pptx' => (Icons.slideshow, Colors.orange),
      'zip' || 'rar' || '7z' => (Icons.folder_zip, Colors.amber),
      'txt' || 'md' => (Icons.article, Colors.blueGrey),
      _ => (Icons.insert_drive_file, Colors.grey),
    };
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 48),
    );
  }
}
