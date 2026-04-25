import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/friend.dart';
import '../utils/pinyin_helper.dart';

/// 带字母索引的联系人列表（微信风格）
///
/// 右侧字母索引栏快速跳转，按拼音首字母分组，当前分组字母浮动吸顶
class IndexedContactList extends StatefulWidget {
  final List<Friend> friends;
  final List<Widget> headerItems;
  final Widget? topWidget;
  final double topWidgetHeight;
  final void Function(Friend friend)? onFriendTap;
  final void Function(Friend friend)? onFriendLongPress;
  final Future<void> Function()? onRefresh;
  final Set<String> onlineIds;

  const IndexedContactList({
    super.key,
    required this.friends,
    this.headerItems = const [],
    this.topWidget,
    this.topWidgetHeight = 0,
    this.onFriendTap,
    this.onFriendLongPress,
    this.onRefresh,
    this.onlineIds = const {},
  });

  @override
  State<IndexedContactList> createState() => _IndexedContactListState();
}

const double _kSectionH = 32.0;
const double _kItemH = 56.0;
const double _kDividerH = 0.5;
const double _kHeaderH = 56.5;

class _IndexedContactListState extends State<IndexedContactList> {
  final ScrollController _sc = ScrollController();
  String? _activeLetter;
  bool _isTouching = false;

  late Map<String, List<Friend>> _grouped;
  late List<String> _letters;
  final Map<String, double> _offsets = {};
  final Map<String, double> _endOffsets = {};
  String? _stickyLetter;
  double _stickyDy = 0;

  @override
  void initState() {
    super.initState();
    _buildData();
    _sc.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant IndexedContactList old) {
    super.didUpdateWidget(old);
    if (old.friends != widget.friends ||
        old.headerItems.length != widget.headerItems.length ||
        old.topWidgetHeight != widget.topWidgetHeight) {
      _buildData();
    }
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    _sc.dispose();
    super.dispose();
  }

  void _buildData() {
    _grouped = {};
    for (final f in widget.friends) {
      final l = PinyinUtil.getFirstLetter(f.nickname);
      _grouped.putIfAbsent(l, () => []).add(f);
    }
    for (final list in _grouped.values) {
      list.sort((a, b) => PinyinUtil.getFullPinyin(a.nickname)
          .compareTo(PinyinUtil.getFullPinyin(b.nickname)));
    }
    _letters = _grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    _calcOffsets();
  }

  void _calcOffsets() {
    _offsets.clear();
    _endOffsets.clear();
    double y = widget.topWidgetHeight + widget.headerItems.length * _kHeaderH;
    for (final l in _letters) {
      _offsets[l] = y;
      y += _kSectionH;
      final count = _grouped[l]!.length;
      y += count * _kItemH + (count > 1 ? (count - 1) * _kDividerH : 0);
      _endOffsets[l] = y;
    }
  }

  void _onScroll() {
    final pos = _sc.offset;
    String? current;
    double dy = 0;

    for (int i = 0; i < _letters.length; i++) {
      final l = _letters[i];
      final start = _offsets[l]!;
      final end = _endOffsets[l]!;
      if (pos >= start - _kSectionH && pos < end) {
        current = l;
        if (i + 1 < _letters.length) {
          final nextStart = _offsets[_letters[i + 1]]!;
          final overlap = pos + _kSectionH - nextStart;
          if (overlap > 0) dy = -overlap;
        }
        break;
      }
    }

    if (current != _stickyLetter || dy != _stickyDy) {
      setState(() {
        _stickyLetter = current;
        _stickyDy = dy;
      });
    }
  }

  void _scrollTo(String letter) {
    final o = _offsets[letter];
    if (o == null) return;
    _sc.jumpTo(o.clamp(0, _sc.position.maxScrollExtent));
  }

  void _onIndexTouch(Offset global, BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox;
    final localY = box.globalToLocal(global).dy;
    final all = PinyinUtil.indexLetters;
    final h = box.size.height / all.length;
    final i = (localY / h).floor().clamp(0, all.length - 1);
    final l = all[i];
    if (_activeLetter != l) {
      setState(() => _activeLetter = l);
      if (_offsets.containsKey(l)) _scrollTo(l);
    }
  }

  List<_ListEntry> _buildEntries() {
    final entries = <_ListEntry>[];
    if (widget.topWidget != null) {
      entries.add(_ListEntry.header(widget.topWidget!));
    }
    for (final w in widget.headerItems) {
      entries.add(_ListEntry.header(w));
    }
    for (final l in _letters) {
      entries.add(_ListEntry.section(l));
      final friends = _grouped[l]!;
      for (int i = 0; i < friends.length; i++) {
        entries.add(_ListEntry.friend(friends[i], showDivider: i < friends.length - 1));
      }
    }
    if (widget.friends.isNotEmpty) {
      entries.add(_ListEntry.footer(widget.friends.length));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();
    final listView = ListView.builder(
      controller: _sc,
      itemCount: entries.length,
      itemBuilder: (ctx, i) => _buildEntry(entries[i]),
    );

    return Stack(
      children: [
        widget.onRefresh != null
            ? RefreshIndicator(onRefresh: widget.onRefresh!, child: listView)
            : listView,
        // 浮动吸顶字母
        if (_stickyLetter != null && widget.friends.isNotEmpty)
          Positioned(
            top: _stickyDy,
            left: 0,
            right: 0,
            child: _SectionHeader(letter: _stickyLetter!),
          ),
        if (widget.friends.isNotEmpty) _buildIndexBar(),
        if (_isTouching && _activeLetter != null) _buildIndicator(),
      ],
    );
  }

  Widget _buildEntry(_ListEntry e) {
    return switch (e.type) {
      _EntryType.header => e.headerWidget!,
      _EntryType.section => _SectionHeader(letter: e.letter!),
      _EntryType.friend => _FriendItem(
          friend: e.friend!,
          showDivider: e.showDivider,
          isOnline: widget.onlineIds.contains(e.friend!.friendId),
          onTap: () => widget.onFriendTap?.call(e.friend!),
          onLongPress: () => widget.onFriendLongPress?.call(e.friend!),
        ),
      _EntryType.footer => Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: Text('${e.count} 位联系人',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
    };
  }

  Widget _buildIndexBar() {
    return Positioned(
      right: 0, top: 0, bottom: 0,
      child: Center(
        child: Builder(builder: (ctx) {
          return GestureDetector(
            onVerticalDragStart: (d) {
              setState(() => _isTouching = true);
              _onIndexTouch(d.globalPosition, ctx);
            },
            onVerticalDragUpdate: (d) => _onIndexTouch(d.globalPosition, ctx),
            onVerticalDragEnd: (_) => setState(() {
              _isTouching = false;
              _activeLetter = null;
            }),
            onVerticalDragCancel: () => setState(() {
              _isTouching = false;
              _activeLetter = null;
            }),
            child: Container(
              width: 20,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: PinyinUtil.indexLetters.map((l) {
                  final active = _activeLetter == l;
                  final has = _offsets.containsKey(l);
                  return SizedBox(
                    height: 16,
                    child: Center(
                      child: Text(l, style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        color: active
                            ? Theme.of(context).primaryColor
                            : has ? Colors.grey[600] : Colors.grey[400],
                      )),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIndicator() {
    return Center(
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(_activeLetter!,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ---- 数据模型 ----

enum _EntryType { header, section, friend, footer }

class _ListEntry {
  final _EntryType type;
  final Widget? headerWidget;
  final String? letter;
  final Friend? friend;
  final bool showDivider;
  final int count;

  const _ListEntry._({
    required this.type,
    this.headerWidget,
    this.letter,
    this.friend,
    this.showDivider = false,
    this.count = 0,
  });

  factory _ListEntry.header(Widget w) => _ListEntry._(type: _EntryType.header, headerWidget: w);
  factory _ListEntry.section(String l) => _ListEntry._(type: _EntryType.section, letter: l);
  factory _ListEntry.friend(Friend f, {bool showDivider = true}) =>
      _ListEntry._(type: _EntryType.friend, friend: f, showDivider: showDivider);
  factory _ListEntry.footer(int c) => _ListEntry._(type: _EntryType.footer, count: c);
}

// ---- 子组件 ----

class _SectionHeader extends StatelessWidget {
  final String letter;
  const _SectionHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kSectionH,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      color: const Color(0xFFF5F5F5),
      child: Text(letter,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
    );
  }
}

class _FriendItem extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDivider;
  final bool isOnline;

  const _FriendItem({
    required this.friend,
    this.onTap,
    this.onLongPress,
    this.showDivider = true,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _kItemH,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AvatarWidget(avatar: friend.avatar, size: 40, borderRadius: 6),
                        if (isOnline)
                          Positioned(
                            right: -1, bottom: -1,
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(friend.nickname,
                          style: const TextStyle(fontSize: 15),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
            if (showDivider)
              const Padding(
                padding: EdgeInsets.only(left: 68),
                child: Divider(height: _kDividerH, thickness: _kDividerH, color: Color(0xFFEEEEEE)),
              ),
          ],
        ),
      ),
    );
  }
}
