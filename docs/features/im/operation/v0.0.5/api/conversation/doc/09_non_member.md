# POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/pin

非会话成员操作（用户 C 不是 A-B 会话的成员），返回 403。

## Response `403`

```json
(empty)
```

> is_member 校验失败，不执行 toggle。