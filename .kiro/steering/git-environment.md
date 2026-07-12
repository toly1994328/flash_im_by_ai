---
inclusion: manual
---

# Git 环境说明

## 远程仓库

- `origin`：`git@github.com:toly1994328/flash_im_by_ai.git`（公开仓库）
- `private`：`git@github.com:toly1994328/flash-im.git`（私有仓库）

## 分支策略

- `master`：主分支，稳定版本
- `feature/vX.XX.X`：功能开发分支
- `vX.XX.X`：版本发布分支

## 当前状态

- 当前分支：`feature/v0.41.0`
- 追踪：`private/feature/v0.41.0`

## 提交规范

使用 Conventional Commits 规范：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建/工具相关

## 常用操作

- 查看状态：`git status`
- 查看提交历史：`git log --oneline -10`
- 创建功能分支：`git checkout -b feature/vX.XX.X`
- 推送到私有仓库：`git push private feature/vX.XX.X`
