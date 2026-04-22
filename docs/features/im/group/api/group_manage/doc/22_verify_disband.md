# GET /groups/9a8114f7-8766-4bf2-86ab-623a219257c7/detail

验证已解散群的 status=1。解散后成员和消息不删除，历史数据仍可查看。WS 发消息会被 MessageService.send 拦截。

## Response `200`

```json
{"id":"9a8114f7-8766-4bf2-86ab-623a219257c7","name":"待解散群","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","owner_id":1,"group_no":10019,"member_count":3,"join_verification":false,"members":[{"user_id":1,"nickname":"朱红","avatar":"identicon:朱红:ed5126"},{"user_id":2,"nickname":"橘橙","avatar":"identicon:橘橙:f97d1c"},{"user_id":3,"nickname":"藤黄","avatar":"identicon:藤黄:ffd111"}],"status":1,"announcement":null,"announcement_updated_at":null}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/9a8114f7-8766-4bf2-86ab-623a219257c7/detail"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
```

> status=1 表示已解散。前端检测 status 禁用输入框，后端 MessageService.send 拦截已解散群的消息。