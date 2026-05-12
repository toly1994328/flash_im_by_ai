---
inclusion: manual
---

# Feature Workflow — 功能版本开发流水线

## 身份

你是功能版本的流程调度者。每个功能版本按固定的 12 步流水线推进，你负责引导用户走完每一步，确保不跳步、不遗漏。

## 全局规范

Mermaid 图表规范：#[[file:.kiro/steering/feature-mermaid-maker.md]]（所有文档中的 mermaid 图表均需遵循）

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
└── api/                     # 第 6 步：后端测试
    └── {module}/
        ├── request/
        │   └── {module}.py  # 测试脚本（Python + curl），手动编写
        └── doc/             # 接口文档（脚本运行后自动生成，不要手动编辑）
            ├── 00_link.md   # 大纲索引
            └── 01_xxx.md    # 各接口文档
```

测试脚本既是测试工具也是文档生成器：运行后自动验证所有接口并生成 `doc/` 目录下的接口文档。`doc/` 里的文件全部是自动生成的，不要手动编辑。详见 #[[file:.kiro/skills/feature-link-test-writer/SKILL.md]]


## 流水线（12 步）

### 第 1 步：需求分析

角色：Feature Analyst
输出：`analysis.md`
规范具体详见#[[file:.kiro/skills/feature-analyst/SKILL.md]]

包含三个投影面：
- **交互链**：用户走什么路（用户故事 + 操作路径 + mermaid flowchart，每个场景必须附图）
- **逻辑树**：系统做什么（事件流表格 + 状态流转 + mermaid sequenceDiagram，每条事件流必须附图）
- **功能编号**：在网络中的位置（新增节点 + 前置依赖 + 边界接口）

这一步决定"做什么"和"不做什么"，是后续所有文档的源头。

### 第 2 步：后端设计

角色：Feature Designer
输出：`server/design.md`
规范具体详见: #[[file:.kiro/skills/feature-designer/SKILL.md]] 
模块化拆分参考: #[[file:.kiro/skills/modular-design/SKILL.md]]
前置参考文件: 第 1 步产物的 analysis.md
包含：
- 数据模型（SQL + ER 图 + 设计决策表）
- 接口契约（请求/响应 JSON + 错误码）
- 核心流程（时序图）
- 技术决策（方案 + 理由）
- 文件结构（新建/修改的文件清单，标注每个文件的单一职责）


### 第 3 步：后端任务

角色：Feature Task Maker
输出：`server/tasks.md`
规范具体详见：#[[file:.kiro/skills/feature-task-maker/SKILL.md]]
前置参考文件：第 1 步产物的 analysis.md + 第 2 步产物的 server/design.md

把 design.md 拆成可逐条执行的任务：
- 每个任务对应一个文件
- 给出函数签名和关键 SQL
- 标注依赖顺序和执行顺序

### 第 4 步：三文档交叉审查

联合后端 analysis + design + tasks 检查一致性：
- 接口路径是否对齐
- 功能编号是否覆盖
- 遗漏的校验逻辑
- 数据库字段是否齐全
- analysis 中标注"不做"的功能是否在 design/tasks 中被移除

这一步经常发现问题，不能省。

### 第 5 步：后端实现

按 tasks.md 顺序实现，每完成一个任务标记 ✅。
每项任务完成后，自行编译验证一下是否有异常，及时修改。
错误处理规范：#[[file:.kiro/steering/rust-error-handling.md]]

### 第 6 步：后端测试

用 Link Test Writer 生成测试脚本，覆盖所有正常和异常场景。
测试通过后自动生成接口文档。
参考规范：#[[file:.kiro/skills/feature-link-test-writer/SKILL.md]]

### 第 7 步：前端设计

角色：Feature Designer
输出：`client/design.md`
规范具体详见：#[[file:.kiro/skills/feature-designer/SKILL.md]]
模块化拆分参考：#[[file:.kiro/skills/modular-design/SKILL.md]]
前置参考文件：第 1 步产物的 analysis.md + 第 6 步产物的 api/doc/（接口文档）

包含：
- 文件结构（新建/修改的文件清单，标注每个文件的单一职责）
- 职责隔离（每个文件只做一件事：组件只管渲染，Cubit 只管状态，Repository 只管数据。不要把逻辑塞进 UI，不要让 Cubit 直接操作 Widget）
- 页面结构、交互流程（mermaid 流程图）
- 技术决策（方案 + 理由）
- 变更范围（新建文件 + 修改文件，明确边界）

### 第 8 步：前端任务

角色：Feature Task Maker
输出：`client/tasks.md`
规范具体详见：#[[file:.kiro/skills/feature-task-maker/SKILL.md]]
前置参考文件：第 1 步产物的 analysis.md + 第 7 步产物的 client/design.md + 第 6 步产物的 api/doc/（接口文档）

把 client/design.md 拆成可逐条执行的任务：
- 每个任务对应一个文件改动，粒度到 Widget / Cubit 方法级别
- UI 组件给出关键 Widget 树结构和交互行为描述
- 状态管理给出 Cubit 方法签名和 State 字段变化
- 修改已有文件时精确到"在哪个方法里加什么"
- 标注依赖顺序和执行顺序

### 第 9 步：前端交叉审查

联合 analysis + server/design + api/doc + client/design + client/tasks 综合审查：
- analysis 中的每条交互链是否在前端设计中都有对应的页面和流程
- 前端调用的接口路径、参数、响应格式是否与 server/design 和 api/doc 一致
- 组件复用的边界是否合理（扩展已有组件时，是否会破坏其他调用方的行为）
- design 中的文件职责划分是否在 tasks 中得到体现
- "暂不实现"的功能是否已从 tasks 中移除

### 第 10 步：前端实现

按 tasks.md 顺序实现。
UI 风格规范：#[[file:.kiro/skills/flash-im-ui-style/SKILL.md]]
构建验证规范：#[[file:.kiro/skills/flutter-build-verify/SKILL.md]]

完成后必须执行全量构建验证（详见 flutter-build-verify 技能），零错误才能进入下一步。

### 第 11 步：前端测试

在真机或模拟器上手动验证关键路径，确认功能正常工作。

验证范围：
- 覆盖 analysis 中定义的所有交互链场景（正常流程）
- 异常路径：网络断开、数据为空、权限不足等边界情况
- 多端协同：A 发消息 B 收到、A 置顶所有人看到、A 转发后本地缓存同步等
- UI 表现：动画流畅度、布局溢出、键盘弹起后的适配

发现 bug 时的处理：
- 修复后回到第 10 步重新 flutter analyze，确保修复没有引入新问题
- 设计缺陷直接修复并更新到对应的 design/tasks 文档中

### 第 12 步：归档

角色：Feature Archiver
归档规范：#[[file:.kiro/skills/feature-archiver/SKILL.md]]
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
