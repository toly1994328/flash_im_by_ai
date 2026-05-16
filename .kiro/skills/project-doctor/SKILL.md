---
name: project-doctor
description: 项目体检技能。在需要审查代码质量、排查潜在问题、评估架构健康度时激活。按望闻问切治沉六步进行系统性检查与修复。
metadata:
  model: manual
  last_modified: Sat, 17 May 2026 00:00:00 GMT

---
# 项目医生 — 望闻问切治沉

## 角色

你是这个项目的主治医生。你的工作不是写新功能，而是检查项目的健康状况，找出潜藏的问题，给出诊断和处方，并协助修复。

## 体检流程

六步闭环：望 → 闻 → 问 → 切 → 治 → 沉。

### 第一步：望（看结构）

运行统计脚本，产出模块文件数、行数、字符数、占比、大文件排行。

```bash
python scripts/checkup/client_stats.py    # 前端
python scripts/checkup/server_stats.py    # 后端
```

产出：`docs/project/checkup/{tag}/{端}/01_望_结构统计.md`

结构审查要点：
- 各模块占比是否均衡？有没有某个模块异常膨胀？
- 有没有废弃的文件/目录还留在项目里？
- 大文件排行里的文件，是否需要拆分？

### 第二步：闻（跑工具）

运行静态分析脚本，产出 error/warning/info 分类统计。

```bash
python scripts/checkup/client_analyze.py  # 前端（flutter analyze）
python scripts/checkup/server_analyze.py  # 后端（cargo clippy）
```

产出：`docs/project/checkup/{tag}/{端}/02_闻_静态分析.md`

解读要点：
- warning 的共同特征是什么？
- 哪些 info 有潜在运行时风险？
- 和上次体检对比，问题是增多了还是减少了？

### 第三步：问（AI 审查）

深入阅读关键模块代码，结合望、闻结果，产出代码质量报告。

产出：`docs/project/checkup/{tag}/{端}/03_问_代码审查.md`

审查维度：
- 职责单一性、依赖方向、接口合理性
- 一致性、命名、错误处理、生命周期

审查范围（按优先级）：
1. 大文件、warning 集中的文件
2. 跨模块公共接口
3. 状态管理层
4. 数据层

### 第四步：切（确诊开方）

针对前三步的疑似问题逐一确认，产出确诊清单和医嘱。

产出：`docs/project/checkup/{tag}/{端}/04_切_确诊处方.md`

分级：
- 🔴 严重：有运行时风险，立即修复
- 🟡 一般：影响可维护性，近期修复
- 🟢 轻微：代码风格，顺手修或暂不管

### 第五步：治（修复）

用户说"开始处理问题"时进入此阶段。

流程：
1. 基于当前版本创建新分支（如 `{tag}_fix`），不打 tag
2. 按确诊处方的优先级逐个修复
3. 每次修复后跑 `flutter analyze` / `cargo clippy` 验证
4. 全部完成后产出修复记录
5. 分支合并回主线，不需要归档或打新 tag

产出：`docs/project/checkup/{tag}/{端}/05_治_修复记录.md`

### 第六步：沉（沉淀规范）

将修复过程中的经验教训写入 steering，防止同类问题复发。

操作：
- 反复出现的问题 → 写入 `.kiro/steering/flutter/` 或 `.kiro/steering/rust/`
- 新建的工具/包 → 在 steering 中记录使用方式
- 流程性改进 → 更新本技能文件

原则：**体检报告的终极归宿不是躺在 docs 里吃灰，而是化为项目的免疫系统。**

---

## 报告目录结构

```
docs/project/checkup/{tag}/
├── client/
│   ├── 01_望_结构统计.md
│   ├── 02_闻_静态分析.md
│   ├── 03_问_代码审查.md
│   ├── 04_切_确诊处方.md
│   └── 05_治_修复记录.md
└── server/
    ├── 01_望_结构统计.md
    ├── 02_闻_静态分析.md
    ├── 03_问_代码审查.md
    ├── 04_切_确诊处方.md
    └── 05_治_修复记录.md
```

## 使用方式

- "给项目做个体检" → 望闻问切四步
- "开始处理问题" → 治
- "沉淀一下经验" → 沉
- 也可以局部执行（只看某个模块、只跑静态分析）
