# GET /groups/search?keyword=开放

群主开启入群验证后，搜索结果中 join_verification=true。

## Response `200`

```json
[{"id":"5aaebb83-19e1-45e7-891c-3a2b2775a9ea","name":"开放群聊","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018","owner_id":1,"group_no":10011,"member_count":4,"is_member":false,"join_verification":true,"has_pending_request":false}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/search?keyword=开放"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9._yeyry_Gy62lFGahp-S5tLYYIzmsdp1LaPjtNnmoISM"
```

> 验证群设置修改即时生效。