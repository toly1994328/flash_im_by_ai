# GET /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/detail

获取群详情：群信息 + 成员列表。当前用户必须是群成员。

## Response `200`

```json
{"id":"5aaebb83-19e1-45e7-891c-3a2b2775a9ea","name":"开放群聊","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018","owner_id":1,"group_no":10011,"member_count":4,"join_verification":false,"members":[{"user_id":1,"nickname":"朱红","avatar":"identicon:朱红:ed5126"},{"user_id":2,"nickname":"橘橙","avatar":"identicon:橘橙:f97d1c"},{"user_id":3,"nickname":"藤黄","avatar":"identicon:藤黄:ffd111"},{"user_id":4,"nickname":"碧螺春绿","avatar":"identicon:碧螺春绿:867018"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/detail"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.bkyRhLQ92eyB0vtIv1jP5wvukqHFuP4pNzpFHVO0-0U"
```

> 返回群名、群号、群头像、成员数、入群验证开关、成员列表（user_id + nickname + avatar）。