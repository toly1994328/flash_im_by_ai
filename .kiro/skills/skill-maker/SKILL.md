---
name: skill-maker
description: Skill 创建规范。在需要新建 .kiro/skills/ 下的技能文件时激活，确保格式正确、内容有效。
metadata:
  model: manual
  last_modified: Sat, 30 May 2026 00:00:00 GMT

---

# Skill Maker — 技能创建规范

## 什么是 Skill

Skill 是一份结构化的指令文档，让 AI 在特定场景下被激活，获得该领域的专业知识和行为规范。

每个 Skill 是一个独立目录，包含一个 `SKILL.md` 文件：

```
.kiro/skills/{skill-name}/
└── SKILL.md
```

## 文件格式

### 必须的 front-matter 标头

```yaml
---
name: {skill-name}
description: {一句话描述}。{激活时机}，{确保什么}。
metadata:
  model: manual
  last_modified: {Day}, {DD} {Mon} {YYYY} 00:00:00 GMT

---
```

| 字段 | 说明 | 示例 |
|------|------|------|
| name | 目录名，kebab-case | `flutter-build-verify` |
| description | 一句话描述 + 激活时机 + 确保什么 | `Flutter 构建验证流程。在前端实现完成后激活，确保编译通过。` |
| model | 固定为 `manual` | — |
| last_modified | RFC 2822 日期格式 | `Sat, 30 May 2026 00:00:00 GMT` |

### 正文结构

标头之后是 Markdown 正文，没有强制模板，但推荐以下结构：

```markdown
# {标题}

## 适用场景 / 身份

什么时候用、解决什么问题。

## 核心内容

技能的主体知识。根据类型不同可以是：
- 决策流程（if-else 判断树）
- 操作步骤（有序列表）
- 规范约束（表格 + 示例）
- 代码模式（代码片段 + 解释）

## 注意事项 / 常见错误

容易踩的坑。
```

## 命名规范

- 目录名：`kebab-case`，全小写，用连字符分隔
- 名称要能一眼看出用途：`flutter-build-verify`、`feature-analyst`、`modular-design`
- 避免过于宽泛的名称：不要叫 `coding-style`，要叫 `flutter-code-style`

## 好 Skill 的特征

| 特征 | 说明 |
|------|------|
| 聚焦 | 一个 Skill 只解决一类问题，不要塞太多不相关的内容 |
| 可操作 | 给出具体的做法，不是空泛的原则 |
| 有边界 | 明确说"什么时候用"和"什么时候不用" |
| 有示例 | 代码片段、决策表格、对比表，比纯文字描述更有效 |
| 简洁 | 控制在 200 行以内，太长的拆成多个 Skill |

## 不好的 Skill

- 把整个框架文档复制进来（太长，没有针对性）
- 只有抽象原则没有具体做法（"要写好代码"）
- 和项目无关的通用知识（"什么是 REST API"）
- 内容和其他 Skill 大量重复

## 创建流程

1. 确定场景：什么时候需要这个知识？
2. 起名字：`kebab-case`，能看出用途
3. 创建目录：`.kiro/skills/{name}/SKILL.md`
4. 写 front-matter：name + description + metadata
5. 写正文：适用场景 → 核心内容 → 注意事项
6. 验证：description 中的激活时机是否准确？AI 看到这个描述能判断何时激活吗？

## 与 Steering 的区别

| | Skill | Steering |
|--|-------|----------|
| 位置 | `.kiro/skills/{name}/SKILL.md` | `.kiro/steering/*.md` |
| 激活方式 | 按需激活（AI 判断或用户指定） | 自动包含 / 文件匹配 / 手动引用 |
| 用途 | 特定场景的专业知识 | 全局规范、项目约定 |
| 粒度 | 一个具体问题域 | 跨场景的通用规则 |

简单说：Steering 是"始终生效的规矩"，Skill 是"需要时才拿出来的专业工具"。
