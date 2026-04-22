import 'package:flutter/material.dart';
import 'selectable_member.dart';
import 'avatar_widget.dart';
import 'search_bar.dart';

const _kSectionH = 32.0;
const _kItemH = 56.0;

const _kIndexLetters = [
  'A','B','C','D','E','F','G','H','I','J','K','L','M',
  'N','O','P','Q','R','S','T','U','V','W','X','Y','Z','#',
];

/// 选人结果
class MemberPickerResult {
  /// 所有选中的成员 ID（含 lockedIds）
  final List<String> allIds;

  /// 新选的成员 ID（不含 lockedIds）
  final List<String> newIds;

  const MemberPickerResult({required this.allIds, required this.newIds});
}

/// 通用选人页面（微信风格）
///
/// 顶部已选头像横条 + 搜索框 → 按字母分组的列表 + 右侧索引栏 → 右上角操作按钮
/// 与业务无关，可用于创建群聊、邀请入群、移除成员等场景。
class MemberPickerPage extends StatefulWidget {
  /// 可选成员列表
  final List<SelectableMember> members;

  /// 锁定的成员 ID（预选中且不可取消，列表中显示灰色勾选）
  final Set<String> lockedIds;

  /// 选中后的回调
  final void Function(MemberPickerResult result)? onConfirm;

  /// 页面标题
  final String title;

  /// 确认按钮文案前缀（如"完成"、"移除"）
  final String confirmLabel;

  /// 最少需要选择的新成员数（不含 lockedIds）
  final int minNewSelection;

  /// 是否为移除模式（红色勾选 + 红色按钮）
  final bool isRemoveMode;

  const MemberPickerPage({
    super.key,
    required this.members,
    this.lockedIds = const {},
    this.onConfirm,
    this.title = '选择联系人',
    this.confirmLabel = '完成',
    this.minNewSelection = 1,
    this.isRemoveMode = false,
  });

  @override
  State<MemberPickerPage> createState() => _MemberPickerPageState();
}

class _MemberPickerPageState extends State<MemberPickerPage> {
  late final Set<String> _selectedIds;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchKeyword = '';
  String? _activeLetter;
  bool _isTouching = false;

  late Map<String, List<SelectableMember>> _grouped;
  late List<String> _letters;
  final Map<String, double> _offsets = {};

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.lockedIds);
    _buildGroupedData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _buildGroupedData() {
    final source = _searchKeyword.isEmpty
        ? widget.members
        : widget.members.where(
            (m) => m.nickname.toLowerCase().contains(_searchKeyword.toLowerCase()),
          ).toList();

    _grouped = {};
    for (final m in source) {
      _grouped.putIfAbsent(m.letter, () => []).add(m);
    }
    for (final list in _grouped.values) {
      list.sort((a, b) => a.nickname.compareTo(b.nickname));
    }
    _letters = _grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    _offsets.clear();
    double y = 0;
    for (final l in _letters) {
      _offsets[l] = y;
      y += _kSectionH + _grouped[l]!.length * _kItemH;
    }
  }

  List<SelectableMember> get _newlySelected =>
      widget.members.where((m) =>
        _selectedIds.contains(m.id) && !widget.lockedIds.contains(m.id),
      ).toList();

  bool get _canConfirm => _newlySelected.length >= widget.minNewSelection;

  void _toggleMember(String id) {
    if (widget.lockedIds.contains(id)) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _removeMember(String id) {
    if (widget.lockedIds.contains(id)) return;
    setState(() => _selectedIds.remove(id));
  }

  void _submit() {
    if (!_canConfirm) return;
    final result = MemberPickerResult(
      allIds: _selectedIds.toList(),
      newIds: _newlySelected.map((m) => m.id).toList(),
    );
    if (widget.onConfirm != null) {
      widget.onConfirm!(result);
    } else {
      Navigator.pop(context, result);
    }
  }

  void _onSearch(String value) {
    setState(() {
      _searchKeyword = value.trim();
      _buildGroupedData();
    });
  }

  void _scrollToLetter(String letter) {
    final offset = _offsets[letter];
    if (offset == null || !_scrollController.hasClients) return;
    _scrollController.jumpTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
    );
  }

  void _onIndexTouch(Offset globalPos, BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localY = box.globalToLocal(globalPos).dy;
    final h = box.size.height / _kIndexLetters.length;
    final i = (localY / h).floor().clamp(0, _kIndexLetters.length - 1);
    final l = _kIndexLetters[i];
    if (_activeLetter != l) {
      setState(() => _activeLetter = l);
      if (_offsets.containsKey(l)) _scrollToLetter(l);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final newCount = _newlySelected.length;
    final label = _canConfirm
        ? '${widget.confirmLabel}($newCount)'
        : widget.confirmLabel;
    final labelColor = widget.isRemoveMode
        ? (_canConfirm ? const Color(0xFFF44336) : theme.colorScheme.onSurfaceVariant)
        : (_canConfirm ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _canConfirm ? _submit : null,
            child: Text(label, style: TextStyle(color: labelColor)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopSection(),
          Expanded(
            child: Stack(
              children: [
                _buildGroupedList(),
                if (_searchKeyword.isEmpty && _letters.isNotEmpty)
                  _buildIndexBar(),
                if (_isTouching && _activeLetter != null)
                  _buildLetterIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    final selected = _newlySelected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlashSearchBar(
          editable: true,
          controller: _searchController,
          onChanged: _onSearch,
          hintText: '搜索',
        ),
        if (selected.isNotEmpty)
          Container(
            color: Colors.white,
            margin: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: selected.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final m = selected[index];
                  return GestureDetector(
                    onTap: () => _removeMember(m.id),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AvatarWidget(avatar: m.avatar, size: 44, borderRadius: 6),
                        Positioned(
                          top: -4, right: -4,
                          child: Container(
                            width: 18, height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCCCCCC), shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupedList() {
    if (_letters.isEmpty) {
      return const Center(
        child: Text('暂无成员', style: TextStyle(color: Colors.grey)),
      );
    }

    final entries = <_Entry>[];
    for (final l in _letters) {
      entries.add(_Entry.section(l));
      for (final m in _grouped[l]!) {
        entries.add(_Entry.member(m));
      }
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: entries.length,
      itemBuilder: (_, index) {
        final e = entries[index];
        if (e.isSection) {
          return Container(
            height: _kSectionH,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            color: Colors.white,
            child: Text(e.letter!, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey,
            )),
          );
        }
        final m = e.member!;
        final isSelected = _selectedIds.contains(m.id);
        final isLocked = widget.lockedIds.contains(m.id);
        return _buildMemberTile(m, isSelected, isLocked);
      },
    );
  }

  Widget _buildMemberTile(SelectableMember member, bool isSelected, bool isLocked) {
    final checkColor = widget.isRemoveMode
        ? const Color(0xFFF44336)
        : const Color(0xFF07C160);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: isLocked ? null : () => _toggleMember(member.id),
        child: Container(
          height: _kItemH,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (isLocked ? const Color(0xFFCCCCCC) : checkColor)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? (isLocked ? const Color(0xFFCCCCCC) : checkColor)
                        : isLocked ? const Color(0xFFDDDDDD) : const Color(0xFFCCCCCC),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              AvatarWidget(avatar: member.avatar, size: 40, borderRadius: 6),
              const SizedBox(width: 12),
              Expanded(
                child: Text(member.nickname,
                  style: TextStyle(
                    fontSize: 15,
                    color: isLocked ? const Color(0xFF999999) : const Color(0xFF333333),
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
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
                children: _kIndexLetters.map((l) {
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

  Widget _buildLetterIndicator() {
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

class _Entry {
  final String? letter;
  final SelectableMember? member;
  bool get isSection => letter != null;

  const _Entry._({this.letter, this.member});
  factory _Entry.section(String l) => _Entry._(letter: l);
  factory _Entry.member(SelectableMember m) => _Entry._(member: m);
}
