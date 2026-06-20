import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fx_logger/fx_logger.dart';
import 'package:path/path.dart' as p;

import 'fx_media_file.dart';

/// FxMediaFile 实现：平台原生文件操作
class FxMediaFileImpl implements FxMediaFile {
  static final FxLog _log = FxLog('FxFile');

  @override
  Future<void> open(String localPath) async {
    _log.d('open: $localPath');
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', localPath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [localPath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [localPath]);
    } else {
      // 移动端：暂用 Process 无法实现，后续可集成 open_filex
      _log.w('open not supported on this platform for: $localPath');
    }
  }

  @override
  Future<void> saveAs(String localPath, {String? suggestedName}) async {
    final String fileName = suggestedName ?? p.basename(localPath);
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: '另存为',
      fileName: fileName,
    );
    if (outputPath == null) return;
    await File(localPath).copy(outputPath);
    _log.d('saveAs: $localPath → $outputPath');
  }

  @override
  Future<void> openFolder(String localPath) async {
    final File file = File(localPath);
    if (!file.existsSync()) return;

    final String normalized = file.absolute.path.replaceAll('/', Platform.pathSeparator);
    _log.d('openFolder: $normalized');

    if (Platform.isWindows) {
      await Process.start('explorer.exe', ['/select,$normalized']);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', normalized]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [file.parent.path]);
    }
    // 移动端无此操作，no-op
  }
}
