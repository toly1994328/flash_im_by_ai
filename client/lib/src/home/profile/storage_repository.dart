import 'package:dio/dio.dart';

/// 云空间配额信息
class StorageQuota {
  final int usedBytes;
  final int quotaBytes;
  final Map<String, CategoryUsage> breakdown;

  StorageQuota({
    required this.usedBytes,
    required this.quotaBytes,
    required this.breakdown,
  });

  double get usagePercent => quotaBytes > 0 ? usedBytes / quotaBytes : 0;
  String get usedFormatted => _formatBytes(usedBytes);
  String get quotaFormatted => _formatBytes(quotaBytes);
  String get remainFormatted => _formatBytes(quotaBytes - usedBytes);
  int get remainBytes => quotaBytes - usedBytes;

  factory StorageQuota.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawBreakdown =
        (json['breakdown'] as Map<String, dynamic>?) ?? {};
    final Map<String, CategoryUsage> breakdown = rawBreakdown.map(
      (key, value) => MapEntry(
        key,
        CategoryUsage.fromJson(value as Map<String, dynamic>),
      ),
    );
    return StorageQuota(
      usedBytes: json['used_bytes'] as int? ?? 0,
      quotaBytes: json['quota_bytes'] as int? ?? 0,
      breakdown: breakdown,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 分类用量
class CategoryUsage {
  final int size;
  final int count;

  CategoryUsage({required this.size, required this.count});

  String get sizeFormatted => StorageQuota._formatBytes(size);

  factory CategoryUsage.fromJson(Map<String, dynamic> json) {
    return CategoryUsage(
      size: json['size'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }
}

/// 云空间配额数据仓库
class StorageRepository {
  final Dio _dio;

  StorageRepository({required Dio dio}) : _dio = dio;

  Future<StorageQuota> getQuota() async {
    final Response<dynamic> res = await _dio.get('/api/storage/quota');
    return StorageQuota.fromJson(res.data as Map<String, dynamic>);
  }
}
