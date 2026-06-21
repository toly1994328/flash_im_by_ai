import 'package:flutter/material.dart';
import 'package:flash_cloud/flash_cloud.dart';

/// 桌面端云空间 Tab 右侧详情面板
class DesktopCloudDetailPanel extends StatelessWidget {
  final CloudFile? selectedFile;
  final CloudRepository repository;
  final String? baseUrl;
  final VoidCallback? onDeleted;

  const DesktopCloudDetailPanel({
    super.key,
    this.selectedFile,
    required this.repository,
    this.baseUrl,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_outlined, size: 64, color: Color(0xFFDDDDDD)),
            SizedBox(height: 16),
            Text('选择一个文件查看详情', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
          ],
        ),
      );
    }

    return FileDetailPage(
      key: ValueKey<int>(selectedFile!.id),
      fileId: selectedFile!.id,
      repository: repository,
      baseUrl: baseUrl,
      showAppBar: false,
      onDeleted: onDeleted,
    );
  }
}
