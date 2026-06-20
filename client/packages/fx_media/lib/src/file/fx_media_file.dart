/// 文件操作抽象接口
abstract class FxMediaFile {
  /// 系统默认程序打开
  Future<void> open(String localPath);

  /// 另存为
  Future<void> saveAs(String localPath, {String? suggestedName});

  /// 打开所在文件夹（桌面端有效，移动端 no-op）
  Future<void> openFolder(String localPath);
}
