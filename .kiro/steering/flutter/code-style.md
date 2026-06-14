---
inclusion: fileMatch
fileMatchPattern: "**/*.dart"
---

# Flutter 前端代码风格

## 代码质量

- 变量声明必须显式标注类型，禁止使用 `var` 或 `final` 省略类型。如：`final String name = 'hello'`，不允许 `final name = 'hello'`。
- 单例使用 factory 构造风格：
  ```dart
  class Foo {
    static final Foo _instance = Foo._();
    factory Foo() => _instance;
    Foo._();
  }
  ```
- 单个文件超过 500 行考虑拆分，可以基于 mixin 合理拆分职能。
- 3 个以上参数总是成组传递时，提取为值对象（如 ChatContext）。
- 重复出现的转换逻辑用 extension 封装（如 `Message.toCached()`）。
- async 操作后使用 BuildContext 前必须检查 mounted。

## 分层职责

- **view 层**：纯 UI 构建，不写业务逻辑。
- **logic 层（Cubit/State）**：状态管理、业务流程编排。单个 Cubit 超过 500 行考虑拆分 mixin。
- **data 层（Repository）**：网络请求 + 本地缓存读写。

## 生命周期

- StreamSubscription 必须在 dispose/close 中取消，成对出现。
- StreamController 关闭前加 `_isClosed` 守卫，防止异步回调在 dispose 后 add。
- async 操作后使用 BuildContext 前必须检查 `if (!context.mounted) return`。

## 数据库（Drift）

- 先 delete 再 insert 的全量同步操作必须包裹在 `transaction()` 中。

## 日期时间

- 判断"今天"用 `DateTime(year, month, day)` 比较，不用 `difference().inDays == 0`。

## 搜索

- 搜索输入加防抖（300ms），避免每次按键触发请求。

## 代码清洁

- 不用的变量/方法/import 及时删除，不留死代码。
- 注释写在类/文件顶部（`///`），方法体内部尽量不写注释——好的命名即注释。仅极其重要的逻辑（如 hack、workaround）才在代码内标注。
- `__` / `___` 改为 `_`（Dart 3 允许多个 `_` 通配符）。
- Map 字面量中可选值用 `'key': ?value` 语法替代 `if (x != null) 'key': x`。
- 可选参数有默认值且内部使用的，不算死代码，无需删除。
