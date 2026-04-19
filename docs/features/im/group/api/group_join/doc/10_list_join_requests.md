# GET /groups/join-requests

查询当前用户作为群主的所有入群申请。包含申请者信息和群名。

## Response `200`

```json
[{"id":"39f4f4a5-f6d6-40a8-998d-003a55094e0f","conversation_id":"1e011830-5353-48f7-ab89-a05c69faaaf5","group_name":"验证群聊","group_avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","user_id":5,"nickname":"天蓝","avatar":"identicon:天蓝:1677b3","message":"请让我加入验证群","status":0,"created_at":"2026-04-19T16:12:07.989992Z"},{"id":"086f27b1-e771-4cf1-a4fe-17a50a1fc981","conversation_id":"77af58a0-4ac0-4fd8-bc76-306cf299da34","group_name":"暖色系联盟","group_avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:银红:e7cad3,identicon:胭脂红:f03f24,identicon:杏黄:f28e16,identicon:柠檬黄:fcd337","user_id":14,"nickname":"草莓红","avatar":"identicon:草莓红:ef6f48","message":null,"status":0,"created_at":"2026-04-19T10:18:20.508663Z"},{"id":"88c92c4f-4100-4f6c-8034-3cad64d39380","conversation_id":"8e9a6aae-844d-4c3c-b961-ec79bee529f3","group_name":"传统色研究会","group_avatar":"grid:identicon:朱红:ed5126,identicon:藤黄:ffd111,identicon:天蓝:1677b3,identicon:葡萄紫:4c1f24,identicon:枫叶红:c21f30,identicon:藤萝紫:8076a3,identicon:姜黄:d6c560,identicon:橄榄绿:5e5314,identicon:宝石蓝:2486b9","user_id":14,"nickname":"草莓红","avatar":"identicon:草莓红:ef6f48","message":"你好啊，加一下","status":1,"created_at":"2026-04-19T10:16:10.277825Z"}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/join-requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.bkyRhLQ92eyB0vtIv1jP5wvukqHFuP4pNzpFHVO0-0U"
```

> 按 created_at DESC 排序，包含所有状态（0/1/2）。