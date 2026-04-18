---
name: mermaid-diagram-writing
description: Mermaid 图表编写规范与常见陷阱。在编写 mermaid 代码块时激活，避免语法错误和渲染异常。
metadata:
  model: manual
  last_modified: Sat, 18 Apr 2026 00:00:00 GMT

---
# Mermaid 图表编写规范

## Contents
- [Supported Diagram Types](#supported-diagram-types)
- [Node Text Special Characters](#node-text-special-characters)
- [Subgraph Rules](#subgraph-rules)
- [Edge Labels](#edge-labels)
- [Line Breaks and Sizing](#line-breaks-and-sizing)
- [Style and Colors](#style-and-colors)
- [Common Errors](#common-errors)
- [Examples](#examples)

## Supported Diagram Types

| 类型 | 语法 | 适用场景 |
|------|------|---------|
| 流程图 | `graph TB` / `graph LR` | 模块关系、页面跳转、依赖图 |
| 时序图 | `sequenceDiagram` | 接口调用链路、事件流 |
| ER 图 | `erDiagram` | 数据库表关系 |
| 状态图 | `stateDiagram-v2` | 状态流转 |
| 流程图 | `flowchart LR` / `flowchart TB` | 用户操作路径 |

## Node Text Special Characters

mermaid 解析器对特殊字符敏感，以下字符在节点文字中会导致解析失败：

| 字符 | 问题 | 解法 |
|------|------|------|
| `()` 圆括号 | 被解析为节点形状定义 | 用中文括号 `（）`，或省略 |
| `[]` 方括号 | 被解析为节点 ID 定义 | 用中文括号 `【】` |
| `{}` 花括号 | 被解析为菱形节点 | 用 `「」` 或文字描述 |
| `>` `<` | 被解析为节点形状或 HTML | 用 `→` `←` 或文字描述 |
| `"` 双引号 | 可能截断字符串 | 用单引号 `'` 或省略 |
| `#` 井号 | 被解析为 HTML 实体 | 避免使用 |
| `&` | 被解析为 HTML 实体 | 用 `+` 或 `和` 替代 |
| `:` 冒号 | 某些上下文中被解析为子图语法 | 用中文冒号 `：` |
| `\|` 竖线 | 被解析为边标签分隔符 | 避免在节点文字中使用 |

**安全做法**：节点文字只用中文、英文字母、数字、空格、`/`、`.`、`_`、`-`、`+`。

## Subgraph Rules

- 每个 `subgraph` 必须有对应的 `end` 闭合
- subgraph 标题中不要用特殊字符（括号、冒号等），纯中文 + 英文最安全
- subgraph 标题不要和节点 ID 重名
- subgraph 可以嵌套，但不要超过 3 层（渲染会变乱）
- 节点在 subgraph 内定义后，连线可以在 subgraph 外写

## Edge Labels

- 连线标签用 `|文字|` 包裹：`A -->|标签| B`
- 标签内不要有 `|` 字符
- 标签文字尽量短（< 15 字），太长会撑宽整张图
- 虚线箭头：`-.->` 或 `-.->|标签|`
- 粗线箭头：`==>` 或 `==>|标签|`

## Line Breaks and Sizing

- 节点内换行用 `<br/>`，不是 `\n`
- 每行不要超过 20 个中文字符，否则节点会很宽
- 节点总数控制在 25 个以内，超过后布局会失控
- `graph TB`（从上到下）适合层级关系，`graph LR`（从左到右）适合流程链路

## Style and Colors

在 mermaid 代码末尾统一添加 `style` 语句：

```
style NODE_ID fill:#颜色,stroke:#边框色
```

推荐配色（柔和不刺眼）：

| 用途 | 填充色 | 边框色 | 说明 |
|------|--------|--------|------|
| 页面/视图 | `#E8F5E9` | `#4CAF50` | 绿色，用户可见的 UI |
| 状态管理 | `#FFF3E0` | `#FF9800` | 橙色，Cubit/Bloc/ViewModel |
| 数据层 | `#E3F2FD` | `#2196F3` | 蓝色，Repository/WsClient |
| 共享组件 | `#F3E5F5` | `#9C27B0` | 紫色，跨模块复用的 Widget |
| API 路由 | `#FFEBEE` | `#F44336` | 红色，HTTP 入口 |
| 服务层 | `#FFF8E1` | `#FFC107` | 黄色，业务逻辑 Service |
| 数据库 | `#ECEFF1` | `#607D8B` | 灰色，PostgreSQL/存储 |
| 局部组件 | `#E0F7FA` | `#00BCD4` | 青色，弹窗/输入框/列表项等 |
| 事件/动作 | `#E8EAF6` | `#3F51B5` | 靛蓝，用户操作/回调/错误等 |

`linkStyle` 可以给特定连线上色：
```
linkStyle 0 stroke:#2196F3,stroke-width:2px
```
注意：linkStyle 的序号是连线在代码中出现的顺序（从 0 开始）。

## Common Errors

| 现象 | 原因 | 排查 |
|------|------|------|
| `Parse error` | 节点文字中有未转义的特殊字符 | 检查 `()`、`{}`、`[]`、`>` |
| 图渲染为空白 | subgraph 未闭合 | 检查每个 `subgraph` 是否有 `end` |
| 节点消失 | 节点 ID 和 mermaid 关键字冲突 | 避免用 `end`、`graph`、`style`、`class` 作为 ID |
| 布局混乱 | 节点太多或连线交叉 | 减少节点数，合并同类项 |
| style 不生效 | 节点 ID 拼写错误 | 确认 style 中的 ID 和定义处完全一致 |
| linkStyle 错位 | 序号算错 | 按代码中连线出现的顺序从 0 数 |

## Examples

### Example: Basic Flow Chart

```
graph TB
    A[页面 A] --> B[页面 B]
    B --> C[页面 C]
    A -.->|HTTP| D[后端 API]

    style A fill:#E8F5E9,stroke:#4CAF50
    style D fill:#FFEBEE,stroke:#F44336
```

### Example: Sequence Diagram with Line Breaks

```
sequenceDiagram
    participant U as 用户
    participant FE as 前端
    participant API as 后端

    U->>FE: T1 点击按钮
    FE->>API: POST /groups<br/>{name, member_ids}
    API-->>FE: T2 返回结果
    FE->>U: T3 跳转页面
```

### Example: ER Diagram

```
erDiagram
    users ||--o{ orders : "has"
    users {
        int id PK
        string name
    }
    orders {
        int id PK
        int user_id FK
        string status
    }
```
