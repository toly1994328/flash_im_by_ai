import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/cloud_file.dart';

/// 图片/视频网格展示（3 列）
class CloudFileGrid extends StatelessWidget {
  final List<CloudFile> files;
  final String? baseUrl;
  final bool showCategoryTag;
  final void Function(CloudFile file)? onTap;

  const CloudFileGrid({super.key, required this.files, this.baseUrl, this.showCategoryTag = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: files.length,
      itemBuilder: (_, index) => _buildItem(files[index]),
    );
  }

  Widget _buildItem(CloudFile file) {
    final String? imageUrl = (file.thumbUrl ?? (file.mimeCategory == 'image' ? file.url : null));
    final bool isVideo = file.mimeCategory == 'video';
    final bool hasImage = imageUrl != null;

    return GestureDetector(
      onTap: () => onTap?.call(file),
      onDoubleTap: () => _showDebugInfo(file),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: _resolveUrl(imageUrl),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: const Color(0xFFF0F0F0)),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(Icons.broken_image, color: Color(0xFFCCCCCC)),
                    ),
                  )
                : Container(
                    color: _categoryColor(file.mimeCategory).withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(
                        _categoryIcon(file.mimeCategory),
                        color: _categoryColor(file.mimeCategory),
                        size: 32,
                      ),
                    ),
                  ),
          ),
          if (isVideo && file.durationMs != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  file.durationFormatted,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          if (!hasImage)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  file.sizeFormatted,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          if (showCategoryTag)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _categoryColor(file.mimeCategory),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _categoryLabel(file.mimeCategory),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    if (baseUrl != null) return '$baseUrl$url';
    return url;
  }

  static Color _categoryColor(String category) {
    return switch (category) {
      'image' => const Color(0xFF2196F3),
      'video' => const Color(0xFFFFC107),
      'audio' => const Color(0xFFF44336),
      'file' => const Color(0xFF4CAF50),
      _ => const Color(0xFF9E9E9E),
    };
  }

  static String _categoryLabel(String category) {
    return switch (category) {
      'image' => '图片',
      'video' => '视频',
      'audio' => '音频',
      'file' => '文件',
      _ => category,
    };
  }

  static IconData _categoryIcon(String category) {
    return switch (category) {
      'image' => Icons.image_outlined,
      'video' => Icons.videocam_outlined,
      'audio' => Icons.audiotrack_outlined,
      'file' => Icons.insert_drive_file_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  void _showDebugInfo(CloudFile file) {
    debugPrint('═══ CloudFile Debug ═══\n'
        'id: ${file.id}\n'
        'url: ${file.url}\n'
        'thumbUrl: ${file.thumbUrl}\n'
        'resolvedUrl: ${_resolveUrl(file.url)}\n'
        'size: ${file.sizeFormatted}\n'
        'mime: ${file.mimeType} (${file.mimeCategory})\n'
        'originalName: ${file.originalName}\n'
        'created: ${file.createdAt}\n'
        '═══════════════════════');
  }
}
