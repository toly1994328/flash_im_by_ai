import 'package:flutter/material.dart';
import '../../data/message.dart';
import '../../logic/chat_state.dart';

class FileBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final double? uploadProgress;
  final FileDownloadInfo? downloadInfo;
  final VoidCallback? onTap;

  const FileBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.uploadProgress,
    this.downloadInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fileExtra = message.fileExtra;
    final fileName = fileExtra?.fileName ?? message.content;
    final fileType = fileExtra?.fileType ?? '';
    final formattedSize = fileExtra?.formattedSize ?? '';
    final isUploading = uploadProgress != null && uploadProgress! < 1.0
        && message.status == MessageStatus.sending;
    final dlInfo = downloadInfo;

    final isIdle = !isMe && (dlInfo == null || dlInfo.status == FileDownloadStatus.idle);
    final isDone = dlInfo != null && dlInfo.status == FileDownloadStatus.done;
    final isDownloading = dlInfo != null && dlInfo.status == FileDownloadStatus.downloading;

    final nameColor = isIdle ? const Color(0xFF999999) : const Color(0xFF333333);
    final bgColor = isIdle ? const Color(0xFFF5F5F5) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 237,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDEE0E2), width: 0.5),
        ),
        child: Stack(children: [
          if (isUploading)
            Positioned.fill(child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: uploadProgress ?? 0,
              child: Container(color: const Color(0xFF3B82F6).withValues(alpha: 0.1)),
            )),
          if (isDownloading)
            Positioned.fill(child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: dlInfo!.progress,
              child: Container(color: const Color(0xFF3B82F6).withValues(alpha: 0.1)),
            )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: nameColor)),
                  if (formattedSize.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        Text(formattedSize,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        if (isDone) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle, color: Colors.green, size: 14),
                        ],
                      ])),
                ],
              )),
              const SizedBox(width: 8),
              _buildFileIcon(fileType),
            ]),
          ),
        ]),
      ),
    );
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
    return Container(width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 24));
  }
}
