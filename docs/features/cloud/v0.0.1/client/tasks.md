# 云空间 Tab — 客户端任务清单

基于 client/design.md，新建 `flash_cloud` 模块 + 修改底部导航。

全局约束：
- 状态管理使用 Cubit
- 变量显式标注类型
- 日志使用 FxLog
- 新模块路径：`client/modules/flash_cloud/`

---

## 执行顺序

1. ✅ 任务 1 — 新建 flash_cloud 模块骨架
2. ✅ 任务 2 — data 层：数据类（含 originalName）+ repository + CloudDownloadManager
3. ✅ 任务 3 — logic 层：CloudFileCubit（分类切换用 'all' 字符串）
4. ✅ 任务 4 — logic 层：FileDetailCubit（使用 CloudDownloadManager）
5. ✅ 任务 5 — view 层：CloudQuotaHeader（分色圆环 CustomPaint + 图例）
6. ✅ 任务 6 — view 层：CloudFileGrid（类型标签 + 图标占位 + 大小标签）+ CloudFileList
7. ✅ 任务 7 — view 层：CloudSpacePage（CustomScrollView + SliverPersistentHeader 吸顶 Tab + 日期分组）
8. ✅ 任务 8 — view 层：FileDetailPage（showTolyPopPicker 弹框 + 背景进度下载 + 缓存路径展示）
9. ✅ 任务 9 — MobileLayout 改 4 Tab
10. ✅ 任务 10 — ProfilePage 精简云空间卡片（底部 3px 分色进度 + 点击切换 Tab）
11. ✅ 任务 11 — barrel export + 主入口注入（CloudDownloadManager.init）
12. ✅ 任务 12 — 编译验证（dart analyze: 0 errors）

---

## 任务 1：新建 flash_cloud 模块骨架 `⬜`

### 1.1 pubspec.yaml `⬜`

文件：`client/modules/flash_cloud/pubspec.yaml`（新建）

```yaml
name: flash_cloud
description: 云空间文件管理模块
version: 0.0.1
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.8.0+1
  flutter_bloc: ^8.1.6
  cached_network_image: ^3.4.1
  flash_im_cache:
    path: ../flash_im_cache
  flash_shared:
    path: ../flash_shared
  fx_logger:
    path: ../../packages/fx_logger

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### 1.2 目录结构 `⬜`

```
client/modules/flash_cloud/lib/
├── flash_cloud.dart
└── src/
    ├── data/
    ├── logic/
    └── view/
```

---

## 任务 2：data 层 `⬜`

### 2.1 cloud_file.dart `⬜`

文件：`client/modules/flash_cloud/lib/src/data/cloud_file.dart`（新建）

```dart
class CloudFile {
  final int id;
  final String url;
  final String? thumbUrl;
  final int size;
  final String mimeType;
  final String mimeCategory;
  final int? width;
  final int? height;
  final int? durationMs;
  final int refCount;
  final DateTime createdAt;

  // fromJson 工厂构造
  // sizeFormatted getter
}

class CloudFileDetail {
  final CloudFile file;
  final List<FileConversationRef> conversations;
}

class FileConversationRef {
  final String conversationId;
  final String conversationName;
  final int conversationType;
  final String? avatar;
  final int messageCount;
}
```

### 2.2 cloud_repository.dart `⬜`

文件：`client/modules/flash_cloud/lib/src/data/cloud_repository.dart`（新建）

```dart
class CloudRepository {
  final Dio _dio;

  Future<(List<CloudFile>, int total)> getFiles({String? category, int page = 1, int limit = 20});
  Future<CloudFileDetail> getFileDetail(int fileId);
  Future<Map<String, dynamic>> deleteFile(int fileId);
}
```

---

## 任务 3：CloudFileCubit `⬜`

文件：`client/modules/flash_cloud/lib/src/logic/cloud_file_cubit.dart`（新建）

```dart
enum CloudFileStatus { initial, loading, loaded, loadingMore, error }

class CloudFileState {
  final CloudFileStatus status;
  final List<CloudFile> files;
  final int total;
  final int page;
  final String? category; // null = 全部
  final String? error;
}

class CloudFileCubit extends Cubit<CloudFileState> {
  Future<void> loadFiles({String? category});   // 重置 page=1 加载
  Future<void> loadMore();                      // page++ 追加
  void switchCategory(String? category);        // 切换分类
}
```

---

## 任务 4：FileDetailCubit `⬜`

文件：`client/modules/flash_cloud/lib/src/logic/file_detail_cubit.dart`（新建）

```dart
enum FileDetailStatus { loading, loaded, error, deleted }

class FileDetailState {
  final FileDetailStatus status;
  final CloudFileDetail? detail;
  final bool isCached;      // 本地是否有缓存
  final String? cachePath;  // 缓存路径
  final int? cacheSize;     // 缓存大小
}

class FileDetailCubit extends Cubit<FileDetailState> {
  Future<void> loadDetail(int fileId);
  Future<void> deleteFile(int fileId);
  Future<void> clearLocalCache();
}
```

---

## 任务 5：CloudQuotaHeader `⬜`

文件：`client/modules/flash_cloud/lib/src/view/cloud_quota_header.dart`（新建）

白色卡片，内含：
- 大号数字（已用量）+ "已用" 文字
- 分色进度条（蓝图片/黄视频/红音频/绿文件）
- 图例行：四种类型 + 各自占用
- 右下角灰色小字 "总量 100MB"

接收 `StorageQuota` 参数（复用 v0.0.6 的数据类）。

---

## 任务 6：CloudFileGrid + CloudFileList `⬜`

### 6.1 cloud_file_grid.dart `⬜`

文件：`client/modules/flash_cloud/lib/src/view/cloud_file_grid.dart`（新建）

- 3 列网格（GridView），间距 2px
- 每项：CachedNetworkImage 缩略图，圆角 4px
- 视频：右下角白底半透明时长标签
- 按月份分组：SliverStickyHeader 或简单 Column + 灰色标题行

### 6.2 cloud_file_list.dart `⬜`

文件：`client/modules/flash_cloud/lib/src/view/cloud_file_list.dart`（新建）

- 标准列表项：左侧类型图标（彩色圆角方块）+ 文件名 + 大小 + 日期
- 音频额外显示时长
- 分割线样式和闪讯一致

---

## 任务 7：CloudSpacePage `⬜`

文件：`client/modules/flash_cloud/lib/src/view/cloud_space_page.dart`（新建）

页面结构：
```
Scaffold(backgroundColor: #F5F5F5)
├── AppBar(title: "云空间", backgroundColor: #EDEDED)
└── Column
    ├── CloudQuotaHeader (配额概览)
    ├── CategoryTabs (全部/图片/视频/音频/文件)
    └── Expanded
        └── 根据 category 决定:
            - image/video → CloudFileGrid
            - audio/file → CloudFileList
            - all → 混合（grid 优先，list 补充）
```

CategoryTabs 用 `TabBar` 或自定义 SegmentTab。

---

## 任务 8：FileDetailPage `⬜`

文件：`client/modules/flash_cloud/lib/src/view/file_detail_page.dart`（新建）

页面结构：
```
Scaffold(backgroundColor: #F5F5F5)
├── AppBar(title: "文件详情", white)
└── ListView
    ├── 预览区（高度 240px，CachedNetworkImage cover）
    ├── SizedBox(10)
    ├── 文件信息卡片（白色，label-value 列表）
    │   ├── 名称
    │   ├── 大小
    │   ├── 格式
    │   └── 上传时间
    ├── SizedBox(10)
    ├── 本地缓存卡片（白色）
    │   ├── 状态：✅已缓存 / ❌未缓存
    │   ├── 缓存大小（已缓存时显示）
    │   └── [清除] 按钮（蓝色文字）
    ├── SizedBox(10)
    ├── 引用会话卡片（白色）
    │   ├── 标题 "使用此文件的会话（N）"
    │   └── 会话列表（头像 + 名称 + 箭头）
    ├── SizedBox(10)
    └── 删除按钮卡片（白色，红色文字居中）
```

---

## 任务 9：MobileLayout 改 4 Tab `⬜`

文件：`client/lib/src/home/view/mobile_layout.dart`（修改）

### 9.1 pages 列表新增 CloudSpacePage `⬜`

```dart
final pages = [
  _buildMessageTab(),
  _buildContactsTab(),
  const CloudSpacePage(),   // ← 新增
  const ProfilePage(),
];
```

### 9.2 底部导航新增 Tab item `⬜`

在"通讯录"和"我"之间插入：

```dart
_buildNavItem(
  index: 2,
  icon: Icons.cloud_outlined,
  activeIcon: Icons.cloud,
  label: '云空间',
),
```

原"我"的 index 从 2 改为 3。

---

## 任务 10：ProfilePage 精简云空间卡片 `⬜`

文件：`client/lib/src/home/profile/profile_page.dart`（修改）

将 `_buildCloudStorageCard` 精简为一行样式：
- 左侧：云朵图标 + "云空间"
- 右侧：已用/总量文字 + 箭头
- 点击：切换到云空间 Tab（而不是 push 新页面）

去掉分色进度条（Tab 页有更详细的展示）。

---

## 任务 11：barrel export + 主入口注入 `⬜`

### 11.1 flash_cloud.dart `⬜`

```dart
export 'src/data/cloud_file.dart';
export 'src/data/cloud_repository.dart';
export 'src/logic/cloud_file_cubit.dart';
export 'src/logic/file_detail_cubit.dart';
export 'src/view/cloud_space_page.dart';
export 'src/view/file_detail_page.dart';
```

### 11.2 主 app pubspec.yaml 添加依赖 `⬜`

```yaml
flash_cloud:
  path: modules/flash_cloud
```

### 11.3 main.dart 注入 CloudRepository `⬜`

```dart
final cloudRepo = CloudRepository(dio: httpClient.dio);
// 通过 RepositoryProvider 注入
```

---

## 任务 12：编译验证 `⬜`

```bash
cd client && flutter analyze
```

确认 0 errors。
