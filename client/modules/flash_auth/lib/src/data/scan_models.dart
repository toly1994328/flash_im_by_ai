class ScanCreateResult {
  final String token;
  final String qrContent;
  final DateTime expiresAt;

  ScanCreateResult({required this.token, required this.qrContent, required this.expiresAt});

  factory ScanCreateResult.fromJson(Map<String, dynamic> json) => ScanCreateResult(
    token: json['token'] as String,
    qrContent: json['qr_content'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String),
  );
}

class ScanStatusResult {
  final String status; // pending/scanned/confirmed/expired/cancelled
  final String? token; // JWT（confirmed 时有值）
  final int? userId;

  ScanStatusResult({required this.status, this.token, this.userId});

  factory ScanStatusResult.fromJson(Map<String, dynamic> json) => ScanStatusResult(
    status: json['status'] as String,
    token: json['token'] as String?,
    userId: json['user_id'] as int?,
  );
}
