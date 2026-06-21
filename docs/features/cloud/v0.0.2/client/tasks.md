# 云空间桌面端 UI 适配 — 前端任务清单

基于 design.md 设计，将桌面端云空间三栏布局的改动拆解为可逐条执行的任务。

全局约束：
- 移动端调用方不传新增参数，行为完全不变
- 桌面端布局参考通讯录三栏（DesktopContactDetailPanel 模式）
- NavRail 云空间 index=2，原"我的"移至 index=3

---

## 执行顺序

1. ✅ 任务 1 — CloudSpacePage 增加嵌入模式参数（无依赖）
2. ✅ 任务 2 — FileDetailPage 增加嵌入模式参数（无依赖）
3. ✅ 任务 3 — 新建 DesktopCloudDetailPanel（依赖任务 2）
4. ✅ 任务 4 — NavRail 增加云空间导航项（无依赖）
5. ✅ 任务 5 — DesktopLayout 增加云空间三栏（依赖任务 1、3、4）
6. ✅ 任务 6 — 编译验证

---

## 任务 1：CloudSpacePage 增加嵌入模式 `⬜ 待处理`

文件：`client/modules/flash_cloud/lib/src/view/cloud_space_page.dart`（修改）

### 1.1 增加构造参数 `⬜`

在 `CloudSpacePage` 构造函数增加：

```dart
final bool showAppBar;                          // 默认 true
final void Function(CloudFile file)? onFileTap; // 桌面端：通知父级选中文件
final VoidCallback? onCategoryChanged;          // 桌面端：切换分类通知清除选中
```

### 1.2 AppBar 条件渲染 `⬜`

`build` 方法中，根据 `showAppBar` 决定是否显示 AppBar：

```dart
// showAppBar == true（移动端）：保留现有 Scaffold + AppBar
// showAppBar == false（桌面端）：只返回 _buildBody()，不包 Scaffold
```

逻辑步骤：
1. `if (!widget.showAppBar)` 返回 `BlocProvider.value(value: _cubit, child: _buildBody())`
2. 否则保留现有 Scaffold 结构

### 1.3 _openDetail 方法分流 `⬜`

```dart
void _openDetail(CloudFile file) {
  if (widget.onFileTap != null) {
    widget.onFileTap!(file);  // 桌面端回调
  } else {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FileDetailPage(...),
    ));
  }
}
```

### 1.4 分类切换通知 `⬜`

在 `_onTabChanged` 方法中增加回调调用：

```dart
void _onTabChanged() {
  if (_tabController.index == _lastTabIndex) return;
  _lastTabIndex = _tabController.index;
  _cubit.switchCategory(_categories[_tabController.index]);
  widget.onCategoryChanged?.call();  // 新增：通知父级
}
```

---

## 任务 2：FileDetailPage 增加嵌入模式 `⬜ 待处理`

文件：`client/modules/flash_cloud/lib/src/view/file_detail_page.dart`（修改）

### 2.1 增加构造参数 `⬜`

```dart
final bool showAppBar;  // 默认 true
```

### 2.2 build 方法条件渲染 `⬜`

```dart
builder: (context, state) {
  final Widget body = _buildBody(context, state);
  if (!showAppBar) return body;  // 桌面端：不包 Scaffold
  return Scaffold(
    backgroundColor: const Color(0xFFF5F5F5),
    appBar: AppBar(...),
    body: body,
  );
},
```

### 2.3 listener 中删除后的行为分流 `⬜`

```dart
listener: (context, state) {
  if (state.status == FileDetailStatus.deleted) {
    onDeleted?.call();
    if (showAppBar) Navigator.of(context).pop();  // 仅移动端 pop
  }
},
```

---

## 任务 3：新建 DesktopCloudDetailPanel `⬜ 待处理`

文件：`client/lib/src/home/view/desktop/cloud_detail_panel.dart`（新建）

### 3.1 创建文件 `⬜`

参考 `contact_detail_panel.dart` 的模式，创建右侧面板容器：

```dart
import 'package:flutter/material.dart';
import 'package:flash_cloud/flash_cloud.dart';
import 'package:flash_shared/flash_shared.dart';

/// 桌面端云空间 Tab 右侧详情面板
class DesktopCloudDetailPanel extends StatelessWidget {
  final CloudFile? selectedFile;
  final CloudRepository repository;
  final String? baseUrl;
  final VoidCallback? onDeleted;

  const DesktopCloudDetailPanel({
    super.key,
    this.selectedFile,
    required this.repository,
    this.baseUrl,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    // 未选中 → 空白占位
    // 已选中 → FileDetailPage(showAppBar: false, key: ValueKey(selectedFile!.id))
  }
}
```

### 3.2 实现空白占位 `⬜`

未选中文件时显示：
- 云朵图标（Icons.cloud_outlined, 64px, #DDDDDD）
- 文字"选择一个文件查看详情"（#999999, 14px）

### 3.3 实现详情嵌入 `⬜`

选中文件时：
- 用 `ValueKey(selectedFile!.id)` 确保切换文件时重建
- 传入 `showAppBar: false`、`onDeleted` 回调

---

## 任务 4：NavRail 增加云空间导航项 `⬜ 待处理`

文件：`client/lib/src/home/view/desktop/nav_rail.dart`（修改）

### 4.1 增加第 4 个导航图标 `⬜`

在现有"通讯录"后面（index 2 位置）插入云空间：

```dart
_buildNavIcon(context, 0, Icons.chat_bubble_outline, Icons.chat_bubble, '消息', badge: unreadCount),
const SizedBox(height: 12),
_buildNavIcon(context, 1, Icons.people_outline, Icons.people, '通讯录'),
const SizedBox(height: 12),
_buildNavIcon(context, 2, Icons.cloud_outlined, Icons.cloud, '云空间'),  // 新增
const SizedBox(height: 12),
_buildNavIcon(context, 3, Icons.person_outline, Icons.person, '我的'),   // index 2→3
```

---

## 任务 5：DesktopLayout 增加云空间三栏 `⬜ 待处理`

文件：`client/lib/src/home/view/desktop/desktop_layout.dart`（修改）

### 5.1 增加状态字段 `⬜`

```dart
CloudFile? _selectedCloudFile;
```

### 5.2 调整 navIndex 映射 `⬜`

原来：0=消息, 1=通讯录, 2=我的
新的：0=消息, 1=通讯录, 2=云空间, 3=我的

需要将 `_buildContent()` 中原来 `_navIndex == 2`（设置面板）的分支改为 `_navIndex == 3`。

### 5.3 增加 navIndex==2 云空间三栏 `⬜`

在 `_buildContent()` 方法中增加：

```dart
if (_navIndex == 2) {
  return Row(
    children: [
      SizedBox(
        width: 360,
        child: Column(
          children: [
            _buildCloudListHeader(),
            Expanded(child: _buildCloudListPanel()),
          ],
        ),
      ),
      const VerticalDivider(width: 0.5, thickness: 0.5),
      Expanded(
        child: Column(
          children: [
            _buildCloudDetailHeader(),
            Expanded(child: _buildCloudDetailPanel()),
          ],
        ),
      ),
    ],
  );
}
```

### 5.4 实现 _buildCloudListHeader `⬜`

左侧面板标题栏（DragMoveArea + 标题"云空间"）：

```dart
Widget _buildCloudListHeader() {
  return DragMoveArea(
    child: Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.only(left: 16),
      color: context.imTheme.headerColor,
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text('云空间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}
```

### 5.5 实现 _buildCloudListPanel `⬜`

渲染 CloudSpacePage 嵌入模式：

```dart
Widget _buildCloudListPanel() {
  final CloudRepository cloudRepo = context.read<CloudRepository>();
  return CloudSpacePage(
    repository: cloudRepo,
    baseUrl: AppConfig.baseUrl,
    showAppBar: false,
    onFileTap: (CloudFile file) {
      setState(() => _selectedCloudFile = file);
    },
    onCategoryChanged: () {
      setState(() => _selectedCloudFile = null);
    },
  );
}
```

### 5.6 实现 _buildCloudDetailHeader `⬜`

右侧面板标题栏（文件名 + WindowsButtons）：

```dart
Widget _buildCloudDetailHeader() {
  final String title = _selectedCloudFile?.originalName
      ?? _selectedCloudFile?.url.split('/').last
      ?? '';
  return DragMoveArea(
    child: Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
          if (kApp.isWindows)
            const Positioned(top: 0, right: 0, child: WindowsButtons()),
        ],
      ),
    ),
  );
}
```

### 5.7 实现 _buildCloudDetailPanel `⬜`

渲染 DesktopCloudDetailPanel：

```dart
Widget _buildCloudDetailPanel() {
  return DesktopCloudDetailPanel(
    selectedFile: _selectedCloudFile,
    repository: context.read<CloudRepository>(),
    baseUrl: AppConfig.baseUrl,
    onDeleted: () {
      setState(() => _selectedCloudFile = null);
    },
  );
}
```

### 5.8 增加 import `⬜`

```dart
import 'package:flash_cloud/flash_cloud.dart';
import 'cloud_detail_panel.dart';
```

---

## 任务 6：编译验证 `⬜ 待处理`

### 6.1 flutter analyze `⬜`

```bash
cd client && flutter analyze
```

确保零错误、零 warning。

### 6.2 Windows 运行验证 `⬜`

```bash
python scripts/client/run.py --platform windows
```

验证清单：
- [ ] NavRail 显示 4 个图标
- [ ] 点击云空间图标显示三栏
- [ ] 左侧文件列表正常加载
- [ ] 切换分类正常
- [ ] 点击文件右侧显示详情
- [ ] 删除文件后右侧回到空白
- [ ] 切换分类后右侧回到空白
- [ ] 切换到"我的"Tab 正常显示设置面板
