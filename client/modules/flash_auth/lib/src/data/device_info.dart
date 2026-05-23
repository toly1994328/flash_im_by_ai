import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 设备信息，登录时携带
class DeviceInfo {
  final String? platform;
  final String? deviceName;
  final String? deviceId;
  final String? appVersion;

  const DeviceInfo({this.platform, this.deviceName, this.deviceId, this.appVersion});

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'device_name': deviceName,
    'device_id': deviceId,
    'app_version': appVersion,
  };

  /// 采集当前设备信息
  static Future<DeviceInfo> collect() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String? deviceName;

    if (Platform.isAndroid) {
      final info = await deviceInfoPlugin.androidInfo;
      deviceName = info.model;
    } else if (Platform.isIOS) {
      final info = await deviceInfoPlugin.iosInfo;
      deviceName = info.name;
    } else if (Platform.isWindows) {
      final info = await deviceInfoPlugin.windowsInfo;
      deviceName = info.computerName;
    } else if (Platform.isMacOS) {
      final info = await deviceInfoPlugin.macOsInfo;
      deviceName = info.computerName;
    } else if (Platform.isLinux) {
      final info = await deviceInfoPlugin.linuxInfo;
      deviceName = info.prettyName;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceId = await _getOrCreateDeviceId();

    return DeviceInfo(
      platform: Platform.operatingSystem,
      deviceName: deviceName,
      deviceId: deviceId,
      appVersion: packageInfo.version,
    );
  }

  static Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('device_id', id);
    }
    return id;
  }
}
