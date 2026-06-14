import 'package:flutter/material.dart';
import '../../data/message.dart';

/// 置顶消息计数指示器：垂直蓝色分段线
class _CountIndicator extends StatelessWidget {
  final int count;
  final double height;

  const _CountIndicator({required this.count, this.height = 34});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF177EE6);
    const spacing = 4.0;
    final segmentHeight = (height - spacing * (count - 1)) / count;

    return SizedBox(
      height: height,
      width: 2,
      child: Column(
        children: List.generate(count, (index) => [
          Container(
            height: segmentHeight.clamp(4.0, 34.0),
            width: 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          if (index < count - 1) const SizedBox(height: spacing),
        ]).expand((e) => e).toList(),
      ),
    );
  }
}

/// 置顶消息横幅
///
/// 蓝色背景横幅，显示在 ChatPage AppBar 下方。
/// - 单条置顶：显示内容摘要 + 右侧×按钮
/// - 多条置顶：点击展开下拉列表
class PinnedMessageBar extends StatefulWidget {
  final List<PinnedMessage> pinnedMessages;
  final bool isOwner;
  final void Function(String pinId)? onUnpin;

  const PinnedMessageBar({
    super.key,
    required this.pinnedMessages,
    this.isOwner = false,
    this.onUnpin,
  });

  @override
  State<PinnedMessageBar> createState() => _PinnedMessageBarState();
}

class _PinnedMessageBarState extends State<PinnedMessageBar> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PinnedMessageBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pinnedMessages.isEmpty && _isOpen) {
      _removeOverlay();
    }
    if (_isOpen && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final barWidth = renderBox.size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeOverlay,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: Offset.zero,
            child: SizeTransition(
              sizeFactor: _fadeAnimation,
              // ignore: deprecated_member_use
              axisAlignment: -1.0, // 从顶部向下展开
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 6, right: 6, bottom: 6),
                  child: Material(
                    elevation: 0,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    child: SizedBox(
                      width: barWidth,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.pinnedMessages.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        itemBuilder: (_, index) {
                          final pin = widget.pinnedMessages[index];
                          return _PinMessageItem(
                            pin: pin,
                            onUnpin: () => widget.onUnpin?.call(pin.pinId),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    _animController.forward(from: 0);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _animController.reset();
    if (_isOpen && mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pinnedMessages.isEmpty) return const SizedBox.shrink();

    final lastPinned = widget.pinnedMessages.first;
    final total = widget.pinnedMessages.length;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (widget.pinnedMessages.length > 1) {
            _toggleOverlay();
          }
          // 单条时不做跳转（跳转需要 ScrollController 定位，暂不实现）
        },
        child: Container(
          color: const Color(0xFFF3F3F3),
          padding: const EdgeInsets.only(top: 4, left: 6, right: 6, bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEBFD),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                _CountIndicator(count: total),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${lastPinned.senderName} 置顶了',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatPreview(lastPinned),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (total > 1)
                  Text(
                    '共$total条',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  )
                else if (widget.onUnpin != null)
                  _buildCloseButton(lastPinned.pinId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(String pinId) {
    return Material(
      color: const Color(0xFFD1E0F2),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => widget.onUnpin?.call(pinId),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 16, color: Color(0xFF515559)),
        ),
      ),
    );
  }

  String _formatPreview(PinnedMessage pin) {
    return switch (pin.msgType) {
      1 => '[图片]',
      2 => '[视频]',
      3 => '[文件]',
      _ => pin.content,
    };
  }
}

/// 下拉列表中的单条置顶消息项
class _PinMessageItem extends StatelessWidget {
  final PinnedMessage pin;
  final VoidCallback onUnpin;

  const _PinMessageItem({required this.pin, required this.onUnpin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const _CountIndicator(count: 1, height: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pin.senderName} 置顶了',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatPreview(pin),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                ),
              ],
            ),
          ),
          Material(
            color: const Color(0xFFE7E8E9),
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: onUnpin,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Color(0xFF515559)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPreview(PinnedMessage pin) {
    return switch (pin.msgType) {
      1 => '[图片]',
      2 => '[视频]',
      3 => '[文件]',
      _ => pin.content,
    };
  }
}
