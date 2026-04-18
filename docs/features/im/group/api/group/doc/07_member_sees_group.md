# GET /conversations?type=1

群成员（非群主）也能在会话列表中看到群聊。

## Response `200`

```json
[{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018","conv_type":1,"created_at":"2026-04-17T17:21:46.899432Z","id":"2b9db0d1-ec3e-4aab-a869-29898e3756af","is_muted":false,"is_pinned":false,"last_message_at":"2026-04-17T17:21:46.905780Z","last_message_preview":"朱红 创建了群聊","name":"测试群聊","peer_avatar":null,"peer_nickname":null,"peer_user_id":null,"unread_count":0},{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018","conv_type":1,"created_at":"2026-04-17T17:11:41.196138Z","id":"625bf09e-945d-4871-8e95-04981e9f1a76","is_muted":false,"is_pinned":false,"last_message_at":"2026-04-17T17:11:41.213493Z","last_message_preview":"朱红 创建了群聊","name":"测试群聊","peer_avatar":null,"peer_nickname":null,"peer_user_id":null,"unread_count":0},{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:姜黄:d6c560,identicon:橄榄绿:5e5314,identicon:宝石蓝:2486b9","conv_type":1,"created_at":"2026-04-16T15:27:15.577348Z","id":"cbce2e21-ddd7-4878-92c1-267ddbbc057d","is_muted":false,"is_pinned":false,"last_message_at":"2026-04-16T15:27:15.591570Z","last_message_preview":"朱红 创建了群聊","name":"姜黄、宝石蓝、橄榄绿等","peer_avatar":null,"peer_nickname":null,"peer_user_id":null,"unread_count":0},{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:银红:e7cad3,identicon:胭脂红:f03f24,identicon:杏黄:f28e16,identicon:柠檬黄:fcd337","conv_type":1,"created_at":"2026-04-15T23:24:25.969429Z","id":"6f465165-a6e6-4fa6-83d0-529ae9b465df","is_muted":false,"is_pinned":false,"last_message_at":"2026-04-15T23:24:26.095391Z","last_message_preview":"黄色也是暖色哦","name":"暖色系联盟","peer_avatar":null,"peer_nickname":null,"peer_user_id":null,"unread_count":2},{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018,identicon:天蓝:1677b3,identicon:景泰蓝:2775b6,identicon:葡萄紫:4c1f24","conv_type":1,"created_at":"2026-04-15T23:24:25.679244Z","id":"80665921-bdcd-4aef-8433-c1e1744927fb","is_muted":false,"is_pinned":false,"last_message_at":"2026-04-15T23:24:25.933478Z","last_message_preview":"紫色最后一个 💜","name":"七彩虹","peer_avatar":null,"peer_nickname":null,"peer_user_id":null,"unread_count":6}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations?type=1"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3MDUxMzA2LCJpYXQiOjE3NzY0NDY1MDZ9.SD2YUBDCZlgpqExJ2Njk7Be-SZWLqh-XCWH_sfLqXeI"
```

> 验证 conversation_members 正确插入了所有成员。