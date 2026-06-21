import 'package:dio/dio.dart';

/// 订阅状态
class SubscriptionStatus {
  final bool hasActiveSubscription;
  final String? planCode;
  final String? planName;
  final DateTime? expiresAt;
  final bool ossUploadEnabled;
  final int usedBytes;
  final int quotaBytes;

  const SubscriptionStatus({
    this.hasActiveSubscription = false,
    this.planCode,
    this.planName,
    this.expiresAt,
    this.ossUploadEnabled = false,
    this.usedBytes = 0,
    this.quotaBytes = 104857600,
  });

  const SubscriptionStatus.empty() : this();

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      hasActiveSubscription: json['has_active_subscription'] as bool? ?? false,
      planCode: json['plan_code'] as String?,
      planName: json['plan_name'] as String?,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      ossUploadEnabled: json['oss_upload_enabled'] as bool? ?? false,
      usedBytes: (json['quota']?['used_bytes'] as int?) ?? 0,
      quotaBytes: (json['quota']?['quota_bytes'] as int?) ?? 104857600,
    );
  }
}

/// 兑换结果
class RedeemResult {
  final String planCode;
  final String planName;
  final DateTime expiresAt;
  final int storageBytes;
  final int usedBytes;
  final int quotaBytes;

  const RedeemResult({
    required this.planCode,
    required this.planName,
    required this.expiresAt,
    required this.storageBytes,
    required this.usedBytes,
    required this.quotaBytes,
  });

  factory RedeemResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> sub = json['subscription'] as Map<String, dynamic>;
    final Map<String, dynamic> quota = json['quota'] as Map<String, dynamic>;
    return RedeemResult(
      planCode: sub['plan_code'] as String,
      planName: sub['plan_name'] as String,
      expiresAt: DateTime.parse(sub['expires_at'] as String),
      storageBytes: sub['storage_bytes'] as int,
      usedBytes: quota['used_bytes'] as int,
      quotaBytes: quota['quota_bytes'] as int,
    );
  }
}

/// 订阅数据仓库
class SubscriptionRepository {
  final Dio _dio;

  SubscriptionRepository({required Dio dio}) : _dio = dio;

  /// 查询订阅状态
  Future<SubscriptionStatus> getStatus() async {
    final Response<dynamic> res = await _dio.get('/api/subscriptions/status');
    return SubscriptionStatus.fromJson(res.data as Map<String, dynamic>);
  }

  /// 兑换码激活
  Future<RedeemResult> redeem(String code) async {
    final Response<dynamic> res = await _dio.post(
      '/api/subscriptions/redeem',
      data: {'code': code},
    );
    return RedeemResult.fromJson(res.data as Map<String, dynamic>);
  }
}
