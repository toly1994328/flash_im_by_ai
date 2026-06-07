import 'package:flutter/material.dart';

import '../data/update_info.dart';
import '../logic/update_manager.dart';

/// 下载回调类型：传入进度回调，返回下载后的本地文件路径
typedef DownloadHandler = Future<String> Function(void Function(double progress));

/// 安装回调类型：传入本地文件路径，执行安装
typedef InstallHandler = Future<void> Function(String filePath);

/// 更新提示对话框（支持下载进度 + 安装）
///
/// 始终展示更新信息，下载时在底部追加进度条。
class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final VoidCallback? onUpdate;
  final VoidCallback? onDismiss;
  final DownloadHandler? downloadHandler;
  final InstallHandler? installHandler;

  const UpdateDialog({
    super.key,
    required this.info,
    this.onUpdate,
    this.onDismiss,
    this.downloadHandler,
    this.installHandler,
  });

  static Future<void> show(
    BuildContext context, {
    required UpdateInfo info,
    VoidCallback? onUpdate,
    VoidCallback? onDismiss,
    DownloadHandler? downloadHandler,
    InstallHandler? installHandler,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (_) => UpdateDialog(
        info: info,
        onUpdate: onUpdate,
        onDismiss: onDismiss,
        downloadHandler: downloadHandler,
        installHandler: installHandler,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

enum _DialogState { info, downloading, completed, failed }

class _UpdateDialogState extends State<UpdateDialog> {
  _DialogState _state = _DialogState.info;
  double _progress = 0;
  String? _filePath;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 恢复 FxUpdater 中的下载状态
    if (FxUpdater().isDownloaded && FxUpdater().downloadedFilePath != null) {
      _state = _DialogState.completed;
      _filePath = FxUpdater().downloadedFilePath;
      _progress = 1.0;
    } else if (FxUpdater().isDownloading) {
      _state = _DialogState.downloading;
      _progress = FxUpdater().progress;
      // 监听后续进度
      FxUpdater().progressStream.listen((double p) {
        if (mounted) setState(() => _progress = p);
        if (p >= 1.0 && mounted) {
          setState(() {
            _state = _DialogState.completed;
            _filePath = FxUpdater().downloadedFilePath;
          });
        }
      });
    }
  }

  Future<void> _startDownload() async {
    if (widget.downloadHandler == null) {
      widget.onUpdate?.call();
      return;
    }
    setState(() {
      _state = _DialogState.downloading;
      _progress = 0;
    });
    try {
      final String path = await widget.downloadHandler!((double p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) setState(() { _state = _DialogState.completed; _filePath = path; });
    } catch (e) {
      if (mounted) setState(() { _state = _DialogState.failed; _error = e.toString(); });
    }
  }

  Future<void> _install() async {
    if (_filePath != null && widget.installHandler != null) {
      await widget.installHandler!(_filePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '发现新版本 v${widget.info.version}',
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 始终展示更新信息
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80, maxHeight: 260),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.info.fileSizeText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(widget.info.fileSizeText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                const Text('更新内容：', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  widget.info.releaseNotes.isNotEmpty ? widget.info.releaseNotes : '修复已知问题，提升稳定性',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.6),
                ),
              ],
            ),
          ),
        ),
        // 下载进度/状态（追加在更新信息下方）
        if (_state == _DialogState.downloading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _progress > 0 ? '${(_progress * 100).toStringAsFixed(1)}%' : '下载中...',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        if (_state == _DialogState.completed)
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 16),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 6),
                Text('下载完成', style: TextStyle(fontSize: 13, color: Colors.green)),
              ],
            ),
          ),
        if (_state == _DialogState.failed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(_error ?? '下载失败', style: const TextStyle(fontSize: 13, color: Colors.red))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: switch (_state) {
        _DialogState.info => _buildInfoFooter(context),
        _DialogState.downloading => const Center(child: Text('下载中，请稍候...', style: TextStyle(fontSize: 13, color: Colors.grey))),
        _DialogState.completed => _buildCompletedFooter(),
        _DialogState.failed => _buildFailedFooter(context),
      },
    );
  }

  Widget _buildInfoFooter(BuildContext context) {
    return Row(
      children: [
        if (!widget.info.forceUpdate) ...[
          Expanded(
            child: InkWell(
              onTap: () { Navigator.of(context).pop(); widget.onDismiss?.call(); },
              child: const Center(child: Text('稍后再说', style: TextStyle(fontSize: 15, color: Colors.grey))),
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade200),
        ],
        Expanded(
          child: InkWell(
            onTap: _startDownload,
            child: const Center(child: Text('立即升级', style: TextStyle(fontSize: 15, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600))),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedFooter() {
    return InkWell(
      onTap: _install,
      child: const Center(child: Text('立即安装', style: TextStyle(fontSize: 15, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600))),
    );
  }

  Widget _buildFailedFooter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Center(child: Text('关闭', style: TextStyle(fontSize: 15, color: Colors.grey))),
          ),
        ),
        Container(width: 1, height: 50, color: Colors.grey.shade200),
        Expanded(
          child: InkWell(
            onTap: _startDownload,
            child: const Center(child: Text('重试', style: TextStyle(fontSize: 15, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600))),
          ),
        ),
      ],
    );
  }
}
