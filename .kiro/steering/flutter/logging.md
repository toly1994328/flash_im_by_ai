---
inclusion: fileMatch
fileMatchPattern: "**/*.dart"
---

# Flutter 日志规范

- 禁止 `print`，使用 `fx_logger` 包（`client/packages/fx_logger/`）
- 用法：`final _log = FxLog('Tag'); _log.d('msg');`
- 级别：d（调试）、i（信息）、w（警告）、e（错误，必须带 error 参数）
- tag 用 PascalCase 简写：`Sync`、`Chat`、`MsgRepo`
- 通用工具放 `packages/`，业务模块放 `modules/`，不往 `flash_shared` 塞工具类
