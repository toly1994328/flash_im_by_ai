---
inclusion: manual
---

# Feature Workflow — 功能版本开发流水线

## 身份

你是功能版本的流程调度者。每个功能版本按固定的 12 步流水线推进，你负责引导用户走完每一步，确保不跳步、不遗漏。

## 工作目录

```
docs/features/{模块}/{版本}/
├── analysis.md              # 第 1 步：需求分析
├── server/
│   ├── design.md            # 第 2 步：后端设计
│   └── tasks.md             # 第 3 步：后端任务
├── client/
│   ├── design.md            # 第 7 步：前端设计
│   └── tasks.md             # 第 8 步：前端任务
```

## 流水线（12 步）

### 第 1 步：需求分析

角色：Feature Analyst
输出：`analysis.md`
参考规范：#[[file:.kiro/steering/mermaid-diagram-writing.md]]

包含三个投影面：
- **交互链**：用户走什么路（用户故事 + 操作路径 + mermaid flowchart，每个场景必须附图）
- **逻辑树**：系统做什么（事件流表格 + 状态流转 + mermaid sequenceDiagram，每条事件流必须附图）
- **功能编号**：在网络中的位置（新增节点 + 前置依赖 + 边界接口）

这一步决定"做什么"和"不做什么"，是后续所有文档的源头。

### 第 2 步：后端设计

角色：Feature Designer
输出：`server/design.md`
参考规范：#[[file:.kiro/steering/feature-designer.md]] #[[file:.kiro/steering/rust-error-handling.md]]

包含：
- 数据模型（SQL + ER 图 + 设计决策表）
- 接口契约（请求/响应 JSON + 错误码）
- 核心流程（时序图）
- 技术决策（方案 + 理由）
- 文件结构（新建/修改的文件清单，标注每个文件的单一职责）

### 第 3 步：后端任务

角色：Feature Task Maker
输出：`server/tasks.md`

把 design.md 拆成可逐条执行的任务：
- 每个任务对应一个文件
- 给出函数签名和关键 SQL
- 标注依赖顺序和执行顺序

### 第 4 步：三文档交叉审查

联合 analysis + design + tasks 检查一致性：
- 接口路径是否对齐
- 功能编号是否覆盖
- 遗漏的校验逻辑
- 数据库字段是否齐全
- analysis 中标注"不做"的功能是否在 design/tasks 中被移除

这一步经常发现问题，不能省。

### 第 5 步：后端实现

按 tasks.md 顺序实现，每完成一个任务标记 ✅。
参考规范：#[[file:.kiro/steering/rust-error-handling.md]]

### 第 6 步：后端测试

用 Link Test Writer 生成测试脚本，覆盖所有正常和异常场景。
测试通过后自动生成接口文档。
参考规范：#[[file:.kiro/steering/link-test-writer.md]]

### 第 7 步：前端设计

角色：Feature Designer
输出：`client/design.md`
参考规范：#[[file:.kiro/steering/feature-designer.md]] #[[file:.kiro/steering/flash-im-ui-style.md]]

包含：
- 文件结构（新建/修改的文件清单，标注每个文件的单一职责）
- 职责隔离（每个文件只做一件事：组件只管渲染，Cubit 只管状态，Repository 只管数据。不要把逻辑塞进 UI，不要让 Cubit 直接操作 Widget）
- 页面结构、交互流程（mermaid 流程图）
- 技术决策（方案 + 理由）
- 变更范围（新建文件 + 修改文件，明确边界）

### 第 8 步：前端任务

- `client/tasks.md`：逐条任务、代码骨架

### 第 9 步：前端交叉审查

联合 analysis + client/design + client/tasks 检查一致性

### 第 10 步：前端实现

按 tasks.md 顺序实现。
完成后 `flutter analyze` 验证编译。
参考规范：#[[file:.kiro/steering/flash-im-ui-style.md]]

### 第 11 步：前端测试

单元测试（Cubit 逻辑、数据转换）+ 集成测试（关键路径手动验证）。

### 第 12 步：归档

角色：Feature Archiver
参考规范：#[[file:.kiro/steering/feature-archiver.md]] #[[file:.kiro/steering/feature-mermaid-maker.md]]
- 更新 `docs/features/archiver/index.md`：节点编号表 + 网络图 + 存档记录
- 更新 `docs/features/archiver/modules/{域}/`：局域网络
- 创建 `docs/features/archiver/trace/{版本}_{日期}.md`：存档快照
- git tag + 提交 + 推送 + 合并到 master

## 角色清单

| 角色 | 职责 | 输出 |
|------|------|------|
| Feature Analyst | 需求分析，分配功能编号 | analysis.md |
| Feature Designer | 数据模型 + 接口契约 + 技术决策 | design.md |
| Feature Task Maker | 拆任务，给出代码骨架 | tasks.md |
| Link Test Writer | 生成接口测试脚本 + 接口文档 | 测试脚本 + doc/ |
| Feature Archiver | 归档功能网 | index.md + modules/ + trace/ |
| Book Writer | 技术文章草稿（归档后独立执行） | docs/ref/doc/books/draft/ |

## 使用方式

用户说"开始下一章功能"或"新建功能版本"时：

1. 确认功能范围和版本号
2. 新建分支
3. 按 12 步流水线依次推进
4. 每一步完成后提示用户确认，再进入下一步
5. 不跳步——如果用户要求直接写代码，提醒先完成设计文档

## 原则

- 先文档后代码——design.md 定义接口契约，tasks.md 定义执行顺序，代码按图施工
- 交叉审查是质量门——三个文档放在一起看，比一个文档反复看三遍更有效
- 测试脚本是活文档——跑一次测试，自动产出最新的接口文档
- 归档是可持续的基础——每个版本归档后，下一个版本可以直接引用节点编号和依赖关系
- 用中文输出所有文档
