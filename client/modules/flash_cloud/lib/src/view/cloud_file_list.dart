import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/cloud_file.dart';

/// 音频/文件列表展示
class CloudFileList extends StatelessWidget {
  final List<CloudFile> files;
  final void Function(CloudFile file)? onTap;

  const CloudFileList({super.key, required this.files, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(left: 56),
        child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0)),
      ),
      itemBuilder: (_, index) => _buildItem(files[index]),
    );
  }

  Widget _buildItem(CloudFile file) {
    final bool isAudio = file.mimeCategory == 'audio';
    final IconData icon = isAudio ? Icons.audiotrack : Icons.insert_drive_file;
    final Color iconColor = isAudio ? const Color(0xFFF44336) : const Color(0xFF4CAF50);

    return InkWell(
      onTap: () => onTap?.call(file),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fileName(file),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(file),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _fileName(CloudFile file) {
    return file.originalName ?? file.url.split('/').last;
  }

  String _subtitle(CloudFile file) {
    final String size = file.sizeFormatted;
    final String date = DateFormat('yyyy-MM-dd').format(file.createdAt);
    if (file.mimeCategory == 'audio' && file.durationMs != null) {
      return '$size · ${file.durationFormatted} · $date';
    }
    return '$size · $date';
  }
}
