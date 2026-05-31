---
name: dep-source-ref
description: 将 pub 依赖库源码复制到 docs/ref 下作为参考。在需要阅读第三方/自有 pub 包源码时激活，确保 AI 能直接读取依赖库的实现。
metadata:
  model: manual
  last_modified: Sat, 30 May 2026 00:00:00 GMT

---

# 依赖库源码参考

## 适用场景

当需要了解某个 pub 依赖包的内部 API、断点逻辑、组件实现时，将其源码复制到 `docs/ref/` 下，让 AI 可以直接读取。

## 操作流程

### 1. 从 pubspec.yaml 确认依赖名

```yaml
# client/pubspec.yaml
dependencies:
  tolyui_rx_layout: 1.0.0+2
  fx_env: 0.0.1+3
```

### 2. 从 pubspec.lock 确认精确版本

```yaml
# client/pubspec.lock
tolyui_rx_layout:
  dependency: "direct main"
  description:
    name: tolyui_rx_layout
    sha256: e2d6882b...
    url: "https://pub.dev"
  source: hosted
  version: "1.0.0+2"
```

### 3. 定位 pub cache 路径

| 平台 | 缓存路径 |
|------|---------|
| Windows | `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\{name}-{version}\` |
| macOS/Linux | `~/.pub-cache/hosted/pub.dev/{name}-{version}/` |

示例：
```
C:\Users\{user}\AppData\Local\Pub\Cache\hosted\pub.dev\tolyui_rx_layout-1.0.0+2\
```

### 4. 复制到 docs/ref

```bash
# Windows
xcopy /E /I "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\tolyui_rx_layout-1.0.0+2" "docs\ref\tolyui_rx_layout-1.0.0+2"

# macOS/Linux
cp -r ~/.pub-cache/hosted/pub.dev/tolyui_rx_layout-1.0.0+2 docs/ref/
```

### 5. 只保留 lib/ 和 pubspec.yaml

复制后可以删除不需要的目录（test/、example/、.dart_tool/ 等），只保留：

```
docs/ref/tolyui_rx_layout-1.0.0+2/
├── lib/          # 源码（必须保留）
├── pubspec.yaml  # 依赖信息（保留）
└── README.md     # 说明文档（可选保留）
```

## 命名规范

目录名格式：`{package_name}-{version}`

示例：
- `docs/ref/tolyui_rx_layout-1.0.0+2/`
- `docs/ref/fx_env-0.0.1+3/`

## 已有参考库

| 库 | 路径 | 说明 |
|----|------|------|
| toly_ui | `docs/ref/toly_ui/` | TolyUI 组件库完整源码（本地项目，非 pub cache） |

## 注意事项

- 只复制需要阅读的包，不要把所有依赖都搬过来
- 更新依赖版本后，记得同步更新 `docs/ref/` 下的源码
- `docs/ref/` 已在 `.gitignore` 中排除（如果没有，建议添加大型参考库）
- 优先复制自有包（如 `fx_env`、`tolyui_rx_layout`），第三方大型包（如 `flutter_bloc`）通常不需要
