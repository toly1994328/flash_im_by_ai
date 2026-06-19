import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cloud_file.dart';
import '../data/cloud_repository.dart';
import '../logic/cloud_file_cubit.dart';
import 'cloud_file_grid.dart';
import 'cloud_file_list.dart';
import 'cloud_quota_header.dart';
import 'file_detail_page.dart';

/// 云空间 Tab 主页面
class CloudSpacePage extends StatefulWidget {
  final CloudRepository repository;
  final String? baseUrl;

  const CloudSpacePage({
    super.key,
    required this.repository,
    this.baseUrl,
  });

  @override
  State<CloudSpacePage> createState() => _CloudSpacePageState();
}

class _CloudSpacePageState extends State<CloudSpacePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CloudFileCubit _cubit;
  Map<String, dynamic>? _quotaData;

  static const List<String> _categories = ['all', 'image', 'video', 'audio', 'file'];
  static const List<String> _labels = ['全部', '图片', '视频', '音频', '文件'];

  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _cubit = CloudFileCubit(repository: widget.repository)..loadFiles();
    _tabController.addListener(_onTabChanged);
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      final Map<String, dynamic> data = await widget.repository.getQuota();
      if (mounted) setState(() => _quotaData = data);
    } catch (_) {}
  }

  void _onTabChanged() {
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    _cubit.switchCategory(_categories[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('云空间'),
          backgroundColor: const Color(0xFFEDEDED),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<CloudFileCubit, CloudFileState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            // 配额卡片（可滑走）
            if (_quotaData != null)
              SliverToBoxAdapter(
                child: CloudQuotaHeader(
                  usedBytes: _quotaData!['used_bytes'] as int? ?? 0,
                  quotaBytes: _quotaData!['quota_bytes'] as int? ?? 0,
                  breakdown: _quotaData!['breakdown'] as Map<String, dynamic>? ?? {},
                ),
              ),
            // Tab 栏（吸顶）
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabDelegate(
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF3B82F6),
                    unselectedLabelColor: const Color(0xFF666666),
                    indicatorColor: const Color(0xFF3B82F6),
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerHeight: 0,
                    labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    tabs: _labels.map((l) => Tab(text: l)).toList(),
                  ),
                ),
              ),
            ),
            // 内容区
            ..._buildSliverContent(state),
          ],
        );
      },
    );
  }

  List<Widget> _buildSliverContent(CloudFileState state) {
    if (state.status == CloudFileStatus.loading) {
      return [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
    }
    if (state.status == CloudFileStatus.error) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('加载失败', style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 12),
                TextButton(onPressed: () => _cubit.loadFiles(category: state.category), child: const Text('重试')),
              ],
            ),
          ),
        ),
      ];
    }
    if (state.files.isEmpty) {
      return [const SliverFillRemaining(child: Center(child: Text('暂无文件', style: TextStyle(color: Color(0xFF999999)))))];
    }

    final String category = state.category;
    final bool isGrid = category == 'all' || category == 'image' || category == 'video';

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        sliver: SliverList(
          delegate: SliverChildListDelegate(
            _buildGroupedContent(state.files, category, isGrid),
          ),
        ),
      ),
      if (state.status == CloudFileStatus.loadingMore)
        const SliverToBoxAdapter(
          child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        ),
    ];
  }

  void _openDetail(CloudFile file) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FileDetailPage(
        fileId: file.id,
        repository: widget.repository,
        baseUrl: widget.baseUrl,
        onDeleted: () => _cubit.removeFile(file.id),
      ),
    ));
  }

  /// 按日期分组渲染文件列表
  List<Widget> _buildGroupedContent(List<CloudFile> files, String category, bool isGrid) {
    final Map<String, List<CloudFile>> groups = {};
    for (final CloudFile file in files) {
      final String key = '${file.createdAt.year}-${file.createdAt.month.toString().padLeft(2, '0')}-${file.createdAt.day.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(file);
    }

    final List<Widget> widgets = [];
    for (final MapEntry<String, List<CloudFile>> entry in groups.entries) {
      // 月份标题
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Text(entry.key, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
      ));
      // 文件内容
      if (isGrid) {
        widgets.add(CloudFileGrid(
          files: entry.value,
          baseUrl: widget.baseUrl,
          showCategoryTag: category == 'all',
          onTap: (f) => _openDetail(f),
        ));
      } else {
        widgets.add(Container(
          color: Colors.white,
          child: CloudFileList(
            files: entry.value,
            onTap: (f) => _openDetail(f),
          ),
        ));
      }
    }
    return widgets;
  }
}

/// Tab 栏吸顶代理
class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTabDelegate({required this.child});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyTabDelegate oldDelegate) => false;
}
