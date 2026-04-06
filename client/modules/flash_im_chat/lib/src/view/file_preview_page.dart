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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          final dlInfo = (state is ChatLoaded)
              ? state.fileDownloads[messageId]
              : null;
          return Column(
            children: [
              // 文件信息区（偏上，约屏幕 1/4 处）
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        _buildFileIcon(fileExtra.fileType),
                        const SizedBox(height: 20),
                        Text(fileExtra.fileName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center, maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text('文件大小: ${fileExtra.formattedSize}',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                      ],
                    ),
                  ),
                ),
              ),
              // 底部操作区
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: _buildAction(context, dlInfo),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAction(BuildContext context, FileDownloadInfo? dlInfo) {
    final status = dlInfo?.status ?? FileDownloadStatus.idle;

    return switch (status) {
      FileDownloadStatus.idle => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _startDownload(context),
            child: Container(
              width: 200,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('下载',
                style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
            ),
          ),
          const SizedBox(height: 8),
          const Text('点击下载到本地',
            style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
        ],
      ),
      FileDownloadStatus.downloading => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('正在下载文件',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
          const SizedBox(height: 12),
          SizedBox(
            width: 48, height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: dlInfo!.progress > 0 ? dlInfo.progress : null,
                  strokeWidth: 3,
                  color: const Color(0xFF999999),
                  backgroundColor: const Color(0xFFE8E8E8),
                ),
                const Icon(Icons.pause, size: 20, color: Color(0xFF999999)),
              ],
            ),
          ),
        ],
      ),
      FileDownloadStatus.done => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 36),
          const SizedBox(height: 8),
          const Text('下载完成',
            style: TextStyle(fontSize: 14, color: Colors.green)),
          if (dlInfo?.localPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(dlInfo!.localPath!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
                textAlign: TextAlign.center),
            ),
        ],
      ),
      FileDownloadStatus.error => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dlInfo?.error ?? '下载失败',
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _startDownload(context),
            child: Container(
              width: 200, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('重试',
                style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
            ),
          ),
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
